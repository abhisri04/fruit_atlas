import 'package:flutter/widgets.dart';

import '../../services/challenge_groups.dart';
import '../hubs/category_hub_page.dart';

/// The Scent & Perfume hub.
class ScentHubPage extends StatelessWidget {
  const ScentHubPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const CategoryHubPage(categoryId: scentCategoryId);
}
