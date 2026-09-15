import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

import '../../models/jyotirlinga.dart';

class JyotirlingaDetailsPage extends StatelessWidget {
  final JyotirlingaSite site;

  const JyotirlingaDetailsPage({super.key, required this.site});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jyotirlinga Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.temple_hindu_outlined, size: 72),
            ),
            const SizedBox(height: 24),
            Text(
              site.name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              site.location,
              style: const TextStyle(fontSize: 16, color: AppColors.muted),
            ),
            const SizedBox(height: 28),
            const Text(
              'Backstory',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              site.backstory,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
