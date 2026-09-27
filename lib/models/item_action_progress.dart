class ItemActionProgress {
  final bool tried;
  final bool cooked;
  final bool wantToTry;
  final bool favourite;
  final DateTime? updatedAt;

  const ItemActionProgress({
    this.tried = false,
    this.cooked = false,
    this.wantToTry = false,
    this.favourite = false,
    this.updatedAt,
  });

  bool hasAction(String action) => switch (action) {
    'tried' => tried,
    'cooked' => cooked,
    'want_to_try' => wantToTry,
    'favourite' => favourite,
    _ => false,
  };

  ItemActionProgress toggle(String action) {
    var nextTried = tried;
    var nextCooked = cooked;
    var nextWant = wantToTry;
    var nextFavourite = favourite;
    switch (action) {
      case 'tried':
        nextTried = !tried;
        if (nextTried) nextWant = false;
      case 'cooked':
        nextCooked = !cooked;
        if (nextCooked) {
          nextTried = true;
          nextWant = false;
        }
      case 'want_to_try':
        nextWant = tried ? false : !wantToTry;
      case 'favourite':
        nextFavourite = !favourite;
    }
    return ItemActionProgress(
      tried: nextTried,
      cooked: nextCooked,
      wantToTry: nextWant,
      favourite: nextFavourite,
      updatedAt: DateTime.now(),
    );
  }

  factory ItemActionProgress.fromJson(Map<String, dynamic> json) {
    final cooked = json['cooked'] as bool? ?? false;
    final tried = (json['tried'] as bool? ?? false) || cooked;
    return ItemActionProgress(
      tried: tried,
      cooked: cooked,
      wantToTry: (json['want_to_try'] as bool? ?? false) && !tried,
      favourite: json['favourite'] as bool? ?? false,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'tried': tried,
    'cooked': cooked,
    'want_to_try': wantToTry,
    'favourite': favourite,
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };

  ItemActionProgress merge(ItemActionProgress other) {
    final mergedTried = tried || other.tried || cooked || other.cooked;
    return ItemActionProgress(
      tried: mergedTried,
      cooked: cooked || other.cooked,
      wantToTry: (wantToTry || other.wantToTry) && !mergedTried,
      favourite: favourite || other.favourite,
      updatedAt: switch ((updatedAt, other.updatedAt)) {
        (null, final value) => value,
        (final value, null) => value,
        (final left?, final right?) => left.isAfter(right) ? left : right,
      },
    );
  }
}
