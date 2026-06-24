// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get verifyEmail => 'Verify Email';

  @override
  String get enterCodeSentTo => 'Enter the code sent to';

  @override
  String get pleaseEnterCode => 'Please enter the code.';

  @override
  String get invalidCode => 'Invalid code. Please try again.';

  @override
  String get codeExpired => 'Code expired. Please request a new one.';

  @override
  String get verificationFailed => 'Verification failed. Please try again.';

  @override
  String get verifyAndContinue => 'Verify & Continue';

  @override
  String get newCodeSent => 'New code sent!';

  @override
  String resendFailed(String e) {
    return 'Resend failed: $e';
  }

  @override
  String get resendCode => 'Resend code';

  @override
  String resendCodeIn(String seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get pleaseEnterEmail => 'Please enter your email.';

  @override
  String get emailLabel => 'EMAIL ADDRESS';

  @override
  String get sendVerificationCode => 'Send Verification Code';

  @override
  String get codeSent => 'Code sent! Check your inbox.';

  @override
  String sendError(String e) {
    return 'Error: $e';
  }

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get videoNotAllowed => 'Please select an image, not a video.';
}
