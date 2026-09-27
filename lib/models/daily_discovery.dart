import 'challenge.dart';
import 'fruit.dart';
import 'item.dart';
import 'indian_dish.dart';
import 'indian_drink.dart';
import 'jyotirlinga.dart';

enum DailyDiscoveryType {
  fruit,
  variety,
  yogaPose,
  indianDish,
  indianDrink,
  indiaLocation,
  jyotirlinga,
}

class DailyDiscovery {
  final DailyDiscoveryType type;
  final String canonicalId;
  final String title;
  final String subtitle;
  final Fruit? fruit;
  final FruitVariety? variety;
  final Item? yogaPose;
  final Challenge? yogaChallenge;
  final IndianDish? dish;
  final IndianDrink? drink;
  final Item? location;
  final Challenge? locationChallenge;
  final JyotirlingaSite? jyotirlinga;

  const DailyDiscovery({
    required this.type,
    required this.canonicalId,
    required this.title,
    required this.subtitle,
    this.fruit,
    this.variety,
    this.yogaPose,
    this.yogaChallenge,
    this.dish,
    this.drink,
    this.location,
    this.locationChallenge,
    this.jyotirlinga,
  });

  String get reference => '${type.name}:$canonicalId';

  // V1 only creates entries for content that can be discovered anywhere.
  bool get locationRequired => false;
}
