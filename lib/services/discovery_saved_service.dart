import '../models/daily_discovery.dart';
import '../models/book.dart';
import 'indian_dishes_repository.dart';
import 'indian_drinks_repository.dart';
import 'progress_service.dart';

class DiscoverySavedService {
  const DiscoverySavedService();

  Future<bool> isSaved(DailyDiscovery discovery) async {
    if (discovery.book != null) {
      return (await ProgressService.getBookProgress())[discovery.canonicalId]
              ?.status ==
          BookStatus.wantToRead;
    }
    if (discovery.dish != null) {
      final catalogue = await const IndianDishesRepository().load();
      return (await ProgressService.getDishProgress(
            catalogue,
          ))[discovery.canonicalId]?.wantToTry ??
          false;
    }
    if (discovery.drink != null) {
      final catalogue = await const IndianDrinksRepository().load();
      return (await ProgressService.getDrinkProgress(
            catalogue,
          ))[discovery.canonicalId]?.wantToTry ??
          false;
    }
    return ProgressService.isEntitySaved(discovery.reference);
  }

  Future<bool> toggle(DailyDiscovery discovery) async {
    if (discovery.book != null) {
      final current =
          (await ProgressService.getBookProgress())[discovery.canonicalId]
              ?.status;
      final updated = await ProgressService.setBookStatus(
        book: discovery.book!,
        status: current == BookStatus.wantToRead
            ? BookStatus.unread
            : BookStatus.wantToRead,
      );
      return updated.status == BookStatus.wantToRead;
    }
    if (discovery.dish != null) {
      final catalogue = await const IndianDishesRepository().load();
      final value = await ProgressService.toggleCategoryItemAction(
        categoryId: catalogue.category.id,
        itemId: discovery.canonicalId,
        action: 'wantToTry',
      );
      return value.wantToTry;
    }
    if (discovery.drink != null) {
      final catalogue = await const IndianDrinksRepository().load();
      final value = await ProgressService.toggleCategoryItemAction(
        categoryId: catalogue.category.id,
        itemId: discovery.canonicalId,
        action: 'wantToTry',
      );
      return value.wantToTry;
    }
    return ProgressService.toggleSavedEntity(discovery.reference);
  }
}
