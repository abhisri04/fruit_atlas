import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/state_travel_status.dart';
import '../models/trip.dart';
import 'progress_service.dart';
import 'state_travel_service.dart';

/// Stores trips on the device (private unless shared) and stamps India
/// Passport for every place a trip went.
abstract final class TripService {
  static const _key = 'trips_v1';
  static const _photoPrefix = 'trip_photo_';

  /// Bumped on every change so open screens can refresh.
  static final ValueNotifier<int> changes = ValueNotifier(0);

  static final Map<String, Uint8List> _photoCache = {};
  static int _counter = 0;

  static String newId([DateTime? at]) =>
      'trip_${(at ?? DateTime.now()).microsecondsSinceEpoch}_${_counter++}';

  static Future<TripLog> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null || raw.isEmpty) return TripLog(const []);
    try {
      return TripLog([
        for (final t in jsonDecode(raw) as List<dynamic>)
          Trip.fromJson(t as Map<String, dynamic>),
      ]);
    } on FormatException {
      return TripLog(const []);
    }
  }

  static Future<void> _save(List<Trip> trips) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      _key,
      jsonEncode([for (final t in trips) t.toJson()]),
    )) {
      throw StateError('Could not save your trips');
    }
    changes.value++;
  }

  /// Adds or replaces [trip], stamps its places and celebrates new trips.
  static Future<void> save(Trip trip, {Uint8List? photo}) async {
    if (trip.stateIds.isEmpty) throw ArgumentError('A trip needs a place');
    var saved = trip;
    final current = await load();
    final previous = current.trips.where((t) => t.id == trip.id).firstOrNull;
    if (photo != null) {
      final photoId = 'photo_${DateTime.now().microsecondsSinceEpoch}';
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(
        '$_photoPrefix$photoId',
        base64Encode(photo),
      )) {
        throw StateError('Could not save the photo');
      }
      _photoCache[photoId] = photo;
      saved = trip.copyWith(photoId: photoId);
      if (previous?.photoId case final old?) await _deletePhoto(old);
    }
    await _save([
      for (final t in current.trips)
        if (t.id != trip.id) t,
      saved,
    ]);
    await _stamp(saved.stateIds, saved.start);
    if (previous == null) {
      await ProgressService.recordActivity(saved.start, 'trip:${saved.id}');
      await ProgressService.recordCollectionMilestone(
        'trip_${saved.id}',
        current.isEmpty ? 'Your first trip!' : 'Trip saved',
        '${saved.title} is in your travel record.',
      );
    }
  }

  /// Removing a trip keeps the passport stamps: you were still there.
  static Future<void> delete(String id) async {
    final current = await load();
    final trip = current.trips.where((t) => t.id == id).firstOrNull;
    if (trip == null) return;
    await _save([
      for (final t in current.trips)
        if (t.id != id) t,
    ]);
    if (trip.photoId case final photo?) await _deletePhoto(photo);
  }

  static Future<Uint8List?> photo(String photoId) async {
    final cached = _photoCache[photoId];
    if (cached != null) return cached;
    final raw = (await SharedPreferences.getInstance()).getString(
      '$_photoPrefix$photoId',
    );
    if (raw == null) return null;
    try {
      return _photoCache[photoId] = base64Decode(raw);
    } on FormatException {
      return null;
    }
  }

  static Future<void> _deletePhoto(String photoId) async {
    _photoCache.remove(photoId);
    await (await SharedPreferences.getInstance()).remove(
      '$_photoPrefix$photoId',
    );
  }

  static Future<void> _stamp(List<String> stateIds, DateTime at) async {
    final travel = StateTravelService();
    try {
      await travel.load();
      for (final id in stateIds) {
        if (travel.statusFor(id) != TravelStatus.visited) {
          await travel.setStatus(id, TravelStatus.visited, at: at);
        }
      }
    } finally {
      travel.dispose();
    }
  }
}
