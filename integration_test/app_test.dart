import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:virtualwalker/constants/strings.dart';
import 'package:virtualwalker/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1 smoke test', () {
    testWidgets('app launches and shows app name', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: VirtualWalkerApp()),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.appName), findsOneWidget);
    });
  });
}
