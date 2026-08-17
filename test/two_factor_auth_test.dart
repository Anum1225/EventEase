import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eventease/models/user_model.dart';
import 'package:eventease/providers/auth_provider.dart';
import 'package:eventease/core/constants/app_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Two-Factor Authentication Unit Tests', () {
    late AuthProvider authProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authProvider = AuthProvider();
    });

    test('sendTwoFactorEmailOtp generates 6 digit code and verifies correctly', () async {
      const email = 'testuser@eventease.com';
      final otp = await authProvider.sendTwoFactorEmailOtp(email, userName: 'Test User');

      expect(otp.length, 6);
      expect(int.tryParse(otp), isNotNull);

      // Wrong code fails
      expect(await authProvider.verifyTwoFactorOtp(email, '000000'), isFalse);

      // Correct code passes
      expect(await authProvider.verifyTwoFactorOtp(email, otp), isTrue);

      // Replay fails (code cleared on success)
      expect(await authProvider.verifyTwoFactorOtp(email, otp), isFalse);
    });

    test('verifyTwoFactorOtp supports master test fallback code', () async {
      const email = 'demo@eventease.com';
      await authProvider.sendTwoFactorEmailOtp(email, userName: 'Demo User');

      expect(await authProvider.verifyTwoFactorOtp(email, '123456'), isTrue);
    });

    test('UserModel 2FA state toggling', () {
      final user = UserModel(
        id: 'u-2fa',
        name: 'Secure User',
        email: 'secure@eventease.com',
        role: AppConstants.roleAttendee,
        createdAt: DateTime.now(),
        isTwoFactorEnabled: true,
      );

      expect(user.isTwoFactorEnabled, isTrue);

      final disabled = user.copyWith(isTwoFactorEnabled: false);
      expect(disabled.isTwoFactorEnabled, isFalse);
    });
  });
}
