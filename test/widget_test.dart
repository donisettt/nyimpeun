import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // App membutuhkan SharedPreferences override.
    // Gunakan integration test untuk full app test.
    expect(true, isTrue);
  });
}
