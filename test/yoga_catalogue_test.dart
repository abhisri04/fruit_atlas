import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/item.dart';

void main() {
  final raw = jsonDecode(
    File('assets/data/yoga_poses.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final records = (raw['items'] as List<dynamic>).cast<Map<String, dynamic>>();
  final items = records.map(Item.fromJson).toList(growable: false);

  const existingIds = {
    'mountain_pose',
    'raised_arms_pose',
    'standing_forward_fold',
    'halfway_lift',
    'chair_pose',
    'warrior_one',
    'warrior_two',
    'reverse_warrior',
    'extended_side_angle',
    'triangle_pose',
    'wide_legged_forward_fold',
    'tree_pose',
    'eagle_pose',
    'dancer_pose',
    'downward_facing_dog',
    'plank_pose',
    'knees_chest_chin',
    'cobra_pose',
    'sphinx_pose',
    'bridge_pose',
    'staff_pose',
    'easy_pose',
    'bound_angle_pose',
    'seated_forward_fold',
    'head_to_knee_pose',
    'seated_spinal_twist',
    'cat_pose',
    'cow_pose',
    'childs_pose',
    'corpse_pose',
  };

  test('Yoga Atlas contains 132 unique canonical poses and target counts', () {
    expect(items, hasLength(132));
    expect(items.map((item) => item.id).toSet(), hasLength(132));
    expect(
      records.where((item) => item['difficulty'] == 'beginner'),
      hasLength(48),
    );
    expect(
      records.where((item) => item['difficulty'] == 'intermediate'),
      hasLength(41),
    );
    expect(
      records.where((item) => item['difficulty'] == 'difficult'),
      hasLength(27),
    );
    expect(
      records.where((item) => item['difficulty'] == 'expert'),
      hasLength(16),
    );
    expect(items.map((item) => item.id).toSet(), containsAll(existingIds));
  });

  test('every Yoga pose references an existing canonical WebP asset', () {
    expect(
      items.every(
        (item) =>
            item.imageUrl != null &&
            item.imageUrl!.isNotEmpty &&
            item.imageUrl == 'assets/images/yoga/${item.id}.webp',
      ),
      isTrue,
    );
    final imagePaths = items.map((item) => item.imageUrl!).toList();
    expect(imagePaths.toSet(), hasLength(132));
    final imageFiles = Directory('assets/images/yoga')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.webp'))
        .toList(growable: false);
    final actualNames = imageFiles
        .map((file) => file.uri.pathSegments.last.toLowerCase())
        .toSet();
    final referencedNames = imagePaths
        .map((path) => Uri.file(path).pathSegments.last.toLowerCase())
        .toSet();
    final missing = referencedNames.difference(actualNames).toList()..sort();
    final extra = actualNames.difference(referencedNames).toList()..sort();
    expect(imageFiles, hasLength(132));
    expect(
      missing.isEmpty && extra.isEmpty,
      isTrue,
      reason: 'Missing Yoga images: $missing\nUnreferenced Yoga images: $extra',
    );
  });

  test('canonical Sanskrit names are unique after normalization', () {
    String normalize(String value) =>
        value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    final names = items
        .map((item) => normalize(item.sanskritName!))
        .toList(growable: false);
    expect(names.toSet(), hasLength(names.length));
    expect(items.every((item) => item.sanskritName!.isNotEmpty), isTrue);
    expect(items.every((item) => item.primaryFamily!.isNotEmpty), isTrue);
    expect(items.every((item) => item.tags.isNotEmpty), isTrue);
    expect(items.every((item) => item.howToSteps.isNotEmpty), isTrue);
    expect(items.every((item) => item.practiceSafety!.isNotEmpty), isTrue);
    expect(items.every((item) => item.sourceRefs.isNotEmpty), isTrue);
    expect(items.every((item) => item.researchStatus == 'verified'), isTrue);
  });

  test('every old completion ID resolves to one expanded catalogue item', () {
    expect(
      items.where((item) => existingIds.contains(item.id)),
      hasLength(existingIds.length),
    );
  });
}
