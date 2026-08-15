import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eventease/core/widgets/status_badge.dart';
import 'package:eventease/core/widgets/category_chip.dart';
import 'package:eventease/core/widgets/app_button.dart';
import 'package:eventease/core/widgets/qr_pass_card.dart';
import 'package:eventease/core/theme/app_theme.dart';
import 'package:eventease/features/auth/screens/splash_screen.dart';

void main() {
  Widget wrapWithTheme(Widget child, {bool isDark = false}) {
    return MaterialApp(
      theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('Core Widget Tests', () {
    testWidgets('StatusBadge renders correct label and icon for approved status', (tester) async {
      await tester.pumpWidget(wrapWithTheme(const StatusBadge(status: 'approved')));
      await tester.pump();
      expect(find.text('Approved'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('StatusBadge renders pending approval status', (tester) async {
      await tester.pumpWidget(wrapWithTheme(const StatusBadge(status: 'pending_approval')));
      await tester.pump();
      expect(find.text('Pending Approval'), findsOneWidget);
    });

    testWidgets('CategoryChip renders category title and responds to taps', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(wrapWithTheme(
        CategoryChip(
          category: 'technology',
          isSelected: true,
          onSelected: (_) => tapped = true,
        ),
      ));
      await tester.pump();

      expect(find.text('Technology'), findsOneWidget);
      await tester.tap(find.byType(CategoryChip));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('AppButton renders label and responds to taps', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(wrapWithTheme(
        AppButton(
          text: 'Register Now',
          onPressed: () => tapped = true,
        ),
      ));
      await tester.pump();

      expect(find.text('Register Now'), findsOneWidget);
      await tester.tap(find.text('Register Now'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('AppButton displays loading spinner when isLoading is true', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        AppButton(
          text: 'Submit',
          isLoading: true,
          onPressed: () {},
        ),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('QRPassCard renders event title and attendee name', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        QRPassCard(
          eventTitle: 'Flutter Global Summit',
          attendeeName: 'Jane Developer',
          qrCodePayload: 'EE:ev-1:reg-1:secret',
          registrationId: 'reg-00123456',
          eventDate: DateTime(2026, 9, 20),
          hasAttended: false,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Flutter Global Summit'), findsOneWidget);
      expect(find.text('Jane Developer'), findsOneWidget);
      expect(find.text('Pass ID: REG-00123456'), findsOneWidget);
    });

    testWidgets('SplashScreen renders app branding', (tester) async {
      bool completed = false;
      await tester.pumpWidget(wrapWithTheme(SplashScreen(
        onComplete: () => completed = true,
      )));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('EventEase'), findsOneWidget);
      expect(find.text('Institutional Edition • v1.0.0'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 2500));
      expect(completed, isTrue);
    });
  });
}
