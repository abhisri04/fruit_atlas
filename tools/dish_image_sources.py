"""Source adapters returning neutral photo candidates; no source fallback."""
import time
import json
import html
import re
import requests
from urllib.request import HTTPRedirectHandler
from urllib.parse import quote, quote_plus, urlparse
from urllib.error import URLError
from download_dish_images_pexels import atomic_json, read_json, normal, StopRun

PIXABAY_LICENSE = 'https://pixabay.com/service/license-summary/'
HOSTS = {'pixabay.com', 'www.pixabay.com', 'cdn.pixabay.com'}
PIXABAY_ENDPOINT = 'https://pixabay.com/api/'
PIXABAY_HEADERS = {'User-Agent': 'UPLYFA/1.0 dish-image-validation'}


def sanitize(value, key):
    value = html.unescape(str(value))
    for secret in {key, quote(key, safe=''), quote_plus(key), quote(key, safe='').lower()}:
        if secret:
            value = value.replace(secret, '<redacted>')
    value = re.sub(r'(?i)([?&]key=)[^&\s<>"\']+', r'\1<redacted>', value)
    # Do not expose complete credential-bearing URLs, even when redacted.
    return re.sub(r'https?://[^\s<>"\']*[?&]key=[^\s<>"\']*', '<credential URL omitted>', value)


class PixabayHTTPError(StopRun):
    def __init__(self, status, reset='60'):
        self.status, self.reset = status, reset
        super().__init__(f'Pixabay HTTP {status}; stopped without retries. Sanitized response details shown above.')


def trusted_url(url):
    parsed = urlparse(url)
    return parsed.scheme == 'https' and parsed.hostname in HOSTS and not parsed.username


class PixabayRedirects(HTTPRedirectHandler):
    def redirect_request(self, request, response, code, message, headers, newurl):
        # API credential URLs must never follow redirects. Image redirects may
        # follow only the explicit official Pixabay/CDN hosts.
        if '/api/' in request.full_url or not trusted_url(newurl):
            raise StopRun('Refused untrusted source redirect')
        return super().redirect_request(request, response, code, message, headers, newurl)


class PixabayAdapter:
    source = 'pixabay'
    key_variable = 'PIXABAY_API_KEY'

    def __init__(self, key, work, pause=2):
        self.key, self.work, self.pause = key, work, pause
        self.cache_path = work / 'pixabay_search_cache.json'
        self.rate_path = work / 'pixabay_rate_checkpoint.json'
        self.cache = read_json(self.cache_path, {})
        self.rate = read_json(self.rate_path, {'requests': []})
        self.session = requests.Session()

    def request(self, parameters, debug=False):
        params = {'key': self.key, **parameters}
        try:
            response = self.session.get(PIXABAY_ENDPOINT, params=params,
                headers=PIXABAY_HEADERS, timeout=20)
        except requests.RequestException as error:
            raise StopRun(f'Pixabay {type(error).__name__}: {sanitize(error, self.key)}. No retries.') from None
        if debug or response.status_code != 200:
            print('GET ' + PIXABAY_ENDPOINT)
            print('params:')
            for name, value in params.items():
                print(f'  {name}=' + ('<redacted>' if name == 'key' else sanitize(value, self.key)))
            print('headers: ' + json.dumps(PIXABAY_HEADERS))
            print(f'HTTP status: {response.status_code}')
            for name in ['Content-Type', 'Server', 'CF-Ray', 'Location', 'Retry-After', 'X-RateLimit-Limit', 'X-RateLimit-Remaining', 'X-RateLimit-Reset']:
                if name in response.headers:
                    print(f'{name}: {sanitize(response.headers[name], self.key)}')
            if response.status_code != 200:
                print('Response body: ' + sanitize(response.text, self.key)[:4000])
        try:
            response.raise_for_status()
        except requests.HTTPError as error:
            print(f'{type(error).__name__}: {sanitize(error, self.key)}')
            raise PixabayHTTPError(response.status_code, response.headers.get('X-RateLimit-Reset', '60'))
        if response.status_code != 200:
            raise PixabayHTTPError(response.status_code, response.headers.get('X-RateLimit-Reset', '60'))
        try:
            data = response.json()
        except (ValueError, requests.RequestException):
            raise StopRun('Pixabay returned an invalid JSON response; no credential URL logged.') from None
        if debug:
            print(f"Number of hits: {len(data.get('hits', []))}")
            print(f"Results found: {data.get('totalHits', 0)}")
            if data.get('hits'):
                print(f"First result ID: {data['hits'][0]['id']}")
        return data, response.headers

    def diagnose(self):
        # Deliberately bypass caches, quotas and manifest/batch writes.
        return self.request(dict(q='butter chicken', image_type='photo', per_page=3, safesearch='true'), debug=True)

    def search(self, query):
        if len(query) > 100:
            raise StopRun('Query exceeds API length limit; refine without broadening it')
        return self.fetch(query, {'q': query})

    def get_photo(self, image_id):
        return self.fetch('photo:' + str(image_id), {'id': str(image_id)})

    def fetch(self, query, parameters):
        now = time.time()
        cached = self.cache.get(query)
        if cached and now - cached['cachedAt'] < 86400:
            return cached['hits']
        if self.rate.get('blockedUntil', 0) > now:
            raise StopRun('Pixabay rate checkpoint is active. Wait before resuming the same batch.')
        recent = [stamp for stamp in self.rate.get('requests', []) if stamp > now - 60]
        if len(recent) >= 90:
            raise StopRun('Conservative per-minute rate budget reached. Resume later; progress saved.')
        recent.append(now)
        self.rate['requests'] = recent
        atomic_json(self.rate_path, self.rate)
        try:
            data, headers = self.request(dict(**parameters, image_type='photo',
                category='food', safesearch='true', per_page=20, page=1, min_width=600, min_height=600))
            remaining = headers.get('X-RateLimit-Remaining')
            reset = headers.get('X-RateLimit-Reset', '60')
            self.rate.update(remaining=remaining, resetSeconds=reset)
            if remaining == '0':
                self.rate['blockedUntil'] = now + max(60, int(reset))
            atomic_json(self.rate_path, self.rate)
        except PixabayHTTPError as error:
            if error.status == 429:
                reset = error.reset
                self.rate['blockedUntil'] = now + max(60, int(reset) if reset.isdigit() else 60)
                atomic_json(self.rate_path, self.rate)
            raise
        except (URLError, TimeoutError, ValueError):
            # Never propagate an exception containing the credential URL.
            raise StopRun('Pixabay connection/response failed; checkpoints retained.') from None
        hits = data.get('hits', [])
        self.cache[query] = {'cachedAt': now, 'hits': hits}
        atomic_json(self.cache_path, self.cache)
        time.sleep(self.pause)
        return hits

    def candidate(self, hit, dish, query):
        tags = normal(hit.get('tags', ''))
        names = [normal(dish['name']), *map(normal, dish.get('aliases', []))]
        exact = any(name and f' {name} ' in f' {tags} ' for name in names)
        flags = []
        if hit.get('type') != 'photo':
            flags.append('not_photo')
        for word in ['buffet', 'packaging', 'watermark', 'logo', 'advertisement', 'collage', 'illustration', 'render', 'generated', 'ai']:
            if word in tags.split():
                flags.append(word)
        width, height = int(hit.get('imageWidth', 0)), int(hit.get('imageHeight', 0))
        source = hit.get('fullHDURL') or hit.get('imageURL') or hit.get('largeImageURL', '')
        if max(width, height) < 1200 or min(width, height) < 600:
            flags.append('insufficient_original_resolution')
        if not trusted_url(source) or not trusted_url(hit.get('pageURL', '')):
            flags.append('invalid_source')
        image_id, creator = str(hit['id']), hit.get('user', '')
        return dict(source=self.source, sourceId=image_id, pixabayImageId=image_id,
            pageUrl=hit.get('pageURL'), creator=creator,
            creatorPageUrl=f"https://pixabay.com/users/{creator}-{hit['user_id']}/" if creator and hit.get('user_id') else None,
            licenseReference=PIXABAY_LICENSE, originalWidth=width, originalHeight=height,
            downloadUrl=source, reviewUrl=hit.get('webformatURL', ''), tags=hit.get('tags', ''),
            searchQueryUsed=query, sourceMetadata=hit,
            score=(60 if exact else 0) + (15 if not flags else 0) + (10 if width >= height else 0),
            confidence='MEDIUM' if exact and not flags else 'LOW', flags=flags,
            notes='Ranking only. Exact dish, professional quality and real-photograph status need visual review.')


# Only Pixabay is callable in this test. Existing source tooling is retained;
# additional adapters can implement the same source-neutral candidate contract.
ACTIVE_ADAPTERS = {'pixabay': PixabayAdapter}


def download_pixabay_image(url):
    """Download reviewed image bytes with Requests' default TLS/proxy settings."""
    if not trusted_url(url):
        raise StopRun('Invalid Pixabay image source')
    try:
        with requests.Session() as session:
            with session.get(url, headers=PIXABAY_HEADERS, timeout=30, stream=True) as response:
                response.raise_for_status()
                if response.status_code != 200:
                    raise StopRun(f'Pixabay image HTTP {response.status_code}')
                if not response.headers.get('Content-Type', '').lower().startswith('image/'):
                    raise StopRun('Pixabay image response has a non-image Content-Type')
                raw = bytearray()
                for chunk in response.iter_content(chunk_size=65536):
                    raw.extend(chunk)
                    if len(raw) > 25 * 1024 * 1024:
                        raise StopRun('Source exceeds download budget')
                if not raw:
                    raise StopRun('Pixabay image response is empty')
                return bytes(raw)
    except requests.RequestException as error:
        raise StopRun(f'Pixabay image {type(error).__name__}: {sanitize(error, "")}. Checkpoint retained.') from None
