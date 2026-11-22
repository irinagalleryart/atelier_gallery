import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atelier_gallery/controllers/gallery_data_controller.dart';
import 'package:atelier_gallery/controllers/locale_controller.dart';
import 'package:atelier_gallery/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AtelierGalleryApp renders title smoke test', (WidgetTester tester) async {
    final localeController = LocaleController();
    final dataController = GalleryDataController();

    // Build our app and trigger a frame.
    await tester.pumpWidget(AtelierGalleryApp(
      localeController: localeController,
      dataController: dataController,
    ));

    // Verify that the title "Ателје Галерија" or "Atelier Gallery" appears on screen.
    expect(find.textContaining('Ателје Галерија'), findsWidgets);
  });

  test('GalleryDataController manages and persists favorites state', () async {
    final controller = GalleryDataController();
    expect(controller.isFavorite('1'), isFalse);
    expect(controller.favoriteArtworkIds, isEmpty);

    await controller.toggleFavorite('1');
    expect(controller.isFavorite('1'), isTrue);
    expect(controller.favoriteArtworkIds, contains('1'));

    await controller.toggleFavorite('1');
    expect(controller.isFavorite('1'), isFalse);
    expect(controller.favoriteArtworkIds, isEmpty);

    await controller.toggleFavorite('2');
    await controller.deleteArtwork('2');
    expect(controller.isFavorite('2'), isFalse);
  });
}
