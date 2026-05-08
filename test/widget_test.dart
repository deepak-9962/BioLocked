import 'package:bio_locked/ui/auth_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the Supabase auth entry screen', (tester) async {
    await tester.pumpWidget(const AuthScreen());

    expect(find.text('BIO-LOCKED'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('New here? Create an account'), findsOneWidget);
  });
}
