import '../models/fruit.dart';

/// Searches the full atlas unless a state is explicitly selected.
List<Fruit> filterFruits(
  Iterable<Fruit> fruits, {
  String query = '',
  String? stateId,
}) {
  final normalized = query.trim().toLowerCase();
  return fruits.where((fruit) {
    if (stateId != null &&
        !fruit.states.any((state) => state.stateId == stateId)) {
      return false;
    }
    return normalized.isEmpty ||
        fruit.name.toLowerCase().contains(normalized) ||
        fruit.scientificName.toLowerCase().contains(normalized) ||
        fruit.varieties.any(
          (variety) => variety.name.toLowerCase().contains(normalized),
        );
  }).toList();
}
