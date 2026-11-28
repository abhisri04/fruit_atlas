import '../screens/travel/passport_stats_page.dart';
import 'district_repository.dart';
import 'progress_service.dart';
import 'trip_service.dart';

/// Gathers the numbers trips and places add to "My India in numbers".
Future<PassportExtraStats> loadPassportExtras() async {
  final trips = await TripService.load();
  final districts = await const DistrictRepository().loadDistricts();
  final done = await ProgressService.getCompletedDistrictIds();
  final ids = {for (final d in districts) d.id};
  return PassportExtraStats(
    trips: trips.trips.length,
    daysTravelled: trips.daysTravelled,
    placesVisited: done.where(ids.contains).length,
    placesTotal: ids.length,
  );
}
