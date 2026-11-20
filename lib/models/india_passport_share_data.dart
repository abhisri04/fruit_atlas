import 'india_location_registry.dart';
import 'state_travel_status.dart';
import '../services/state_travel_service.dart';

class IndiaPassportShareData {
  final Map<String, TravelStatus> statuses;
  IndiaPassportShareData(StateTravelService travel)
    : statuses = Map.unmodifiable({
        for (final id in IndiaLocationRegistry.allLocationIds)
          id: travel.statusFor(id),
      });
  int get total => IndiaLocationRegistry.allLocationIds.length;
  int get visited =>
      statuses.values.where((s) => s == TravelStatus.visited).length;
  int get wanted =>
      statuses.values.where((s) => s == TravelStatus.wantToVisit).length;
  int get notMarked => total - visited - wanted;
  double get ratio => visited / total;
  int get percent => (ratio * 100).round();
  String get shareText =>
      "I've visited $visited of India's $total States & UTs — $percent% of India.";
}
