import 'package:flutter/material.dart';

import 'app/app.dart';
import 'screens/garden/garden_sheets.dart';

void main() {
  runApp(const FruitAtlasApp());
  // Warm up catalogues used by Garden & Plants so it opens straight away.
  GardenCatalogue.raw().ignore();
  GardenCatalogue.ways().ignore();
  GardenCatalogue.plantsChallenge().ignore();
}
