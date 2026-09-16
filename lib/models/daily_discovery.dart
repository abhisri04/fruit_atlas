import 'challenge.dart';
import 'fruit.dart';
import 'item.dart';

enum DailyDiscoveryType { fruit, variety, yogaPose }

class DailyDiscovery {
  final DailyDiscoveryType type;
  final String canonicalId;
  final String title;
  final String subtitle;
  final Fruit? fruit;
  final FruitVariety? variety;
  final Item? yogaPose;
  final Challenge? yogaChallenge;

  const DailyDiscovery({
    required this.type,
    required this.canonicalId,
    required this.title,
    required this.subtitle,
    this.fruit,
    this.variety,
    this.yogaPose,
    this.yogaChallenge,
  });

  String get reference => '${type.name}:$canonicalId';

  // V1 only creates entries for content that can be discovered anywhere.
  bool get locationRequired => false;
}
