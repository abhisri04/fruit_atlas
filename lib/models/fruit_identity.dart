/// IDs retired when duplicate fruit records were folded into their original
/// canonical record. Keep redirects so existing completion and Saved data work.
abstract final class FruitIdentity {
  static const legacyIdRedirects = <String, String>{
    'FR046': 'FR016',
    'FR062': 'FR009',
    'FR075': 'FR074',
    'FR078': 'FR035',
    'FR081': 'FR049',
    'FR082': 'FR049',
    'FR084': 'FR047',
    'FR087': 'FR086',
    'FR089': 'FR009',
    'FR090': 'FR006',
  };

  static String canonicalId(String id) => legacyIdRedirects[id] ?? id;

  static String canonicalReference(String reference) {
    if (!reference.startsWith('fruit:')) return reference;
    final id = reference.substring('fruit:'.length);
    return 'fruit:${canonicalId(id)}';
  }
}
