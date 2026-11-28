import 'package:flutter/material.dart';

import '../../models/mixed_drink.dart';
import '../../services/drink_mix_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String mixDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// Asks once before showing cocktails. Returns the choice, or null if the
/// sheet was dismissed.
Future<bool?> askAboutCocktails(BuildContext context) async {
  final show = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.local_bar_outlined),
      title: const Text('Cocktails contain alcohol'),
      content: const Text(
        'They are only for adults of legal drinking age where you live. '
        'Every cocktail here also shows a zero-proof way to make it.\n\n'
        'You can change this any time.',
      ),
      actions: [
        TextButton(
          key: const ValueKey('cocktails-no'),
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Mocktails only'),
        ),
        FilledButton(
          key: const ValueKey('cocktails-yes'),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Show cocktails'),
        ),
      ],
    ),
  );
  if (show != null) await DrinkMixService.setShowCocktails(show);
  return show;
}

/// A coloured badge: green glass for mocktails, amber for cocktails.
class DrinkBadge extends StatelessWidget {
  final MixedDrink drink;
  final double size;
  const DrinkBadge({super.key, required this.drink, this.size = 40});

  static const mocktailColor = Color(0xFF2E8B6E);
  static const cocktailColor = Color(0xFFB0602A);

  static IconData iconFor(MixedDrink d) => switch (d.method) {
    'Heat' => Icons.coffee_outlined,
    'Blend' => Icons.blender_outlined,
    'Whisk' => Icons.coffee_maker_outlined,
    _ when d.isCocktail => Icons.local_bar_outlined,
    _ => Icons.local_drink_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final color = drink.isCocktail ? cocktailColor : mocktailColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Icon(iconFor(drink), color: color, size: size * .55),
    );
  }
}

/// One drink in a list, with one-tap "made it".
class DrinkTile extends StatelessWidget {
  final MixedDrink drink;
  final DrinkBook book;
  final bool made;
  final String? note;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  const DrinkTile({
    super.key,
    required this.drink,
    required this.book,
    required this.made,
    required this.onTap,
    required this.onToggle,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final c = book.country(drink.country);
    return Container(
      key: ValueKey('drink-${drink.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: made ? AppColors.completedSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(
          color: made
              ? AppColors.primary.withValues(alpha: .35)
              : AppColors.outline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          onTap: onTap,
          leading: DrinkBadge(drink: drink),
          title: Text(
            drink.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: made ? AppColors.primary : AppColors.ink,
            ),
          ),
          subtitle: Text(
            note ??
                '${c.flag} ${c.name} · ${drink.method} · ${drink.minutes} min',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Checkbox(
            key: ValueKey('drink-check-${drink.id}'),
            value: made,
            onChanged: (_) => onToggle(),
          ),
        ),
      ),
    );
  }
}
