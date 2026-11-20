import 'package:share_plus/share_plus.dart';

import '../models/book.dart';

abstract interface class BookShareGateway {
  Future<void> shareText(String text);
}

class NativeBookShareGateway implements BookShareGateway {
  const NativeBookShareGateway();

  @override
  Future<void> shareText(String text) =>
      SharePlus.instance.share(ShareParams(text: text));
}

class BookShareService {
  final BookShareGateway gateway;
  const BookShareService({this.gateway = const NativeBookShareGateway()});

  /// Text is the reliable baseline for every Books share type. A visual-card
  /// renderer can be added later without changing payload calculation.
  Future<void> share(BookSharePayload payload) =>
      gateway.shareText(payload.shareText);
}
