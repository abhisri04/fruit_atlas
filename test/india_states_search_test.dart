import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/services/global_search_service.dart';
import 'package:fruit_atlas/services/experience_repository.dart';

void main() {
  testWidgets(
    'state search indexes exact names, aliases, and parent challenge',
    (tester) async {
      ExperienceRepository.clearCacheForTesting();
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (message) async {
          final name = utf8.decode(message!.buffer.asUint8List());
          if (name == 'AssetManifest.bin') {
            return const StandardMessageCodec().encodeMessage(
              <String, Object>{},
            );
          }
          final file = File(name);
          return file.existsSync()
              ? ByteData.sublistView(file.readAsBytesSync())
              : null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMessageHandler(
          'flutter/assets',
          null,
        ),
      );

      final search = GlobalSearchService();
      await search.load();
      for (final name in [
        'Rajasthan',
        'Delhi',
        'Kerala',
        'Goa',
        'Ladakh',
        'Puducherry',
        'Uttar Pradesh',
      ]) {
        expect(search.search(name).first.title, name);
        expect(
          search.search(name).map((result) => result.title),
          contains('Explore All 36 States & UTs of India'),
        );
      }
      expect(search.search('UP').first.title, 'Uttar Pradesh');
      expect(search.search('MP').first.title, 'Madhya Pradesh');
      expect(search.search('J&K').first.title, 'Jammu and Kashmir');
      expect(search.search('Mehrangarh').first.title, 'Mehrangarh Fort');
      expect(
        search.search('fort').map((result) => result.title),
        containsAll(['Mehrangarh Fort', 'Amber Palace']),
      );
      expect(search.search('Dal Baati').first.title, 'Dal Baati Churma');
      expect(search.search('laal maas').first.title, 'Lal Maas');
      expect(
        search.search('desert').map((result) => result.title),
        contains('Jaisalmer Desert Safari'),
      );
      expect(search.search('Jaipur').first.title, 'Jaipur');
      expect(search.search('Jaipur').first.subtitle, 'District · Rajasthan');
      expect(search.search('Jodhpur').first.subtitle, 'District · Rajasthan');
      expect(search.search('Udaipur').first.subtitle, 'District · Rajasthan');
      expect(search.search('Bikaner').first.subtitle, 'District · Rajasthan');
    },
  );
}
