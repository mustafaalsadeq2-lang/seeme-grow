// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get verifyEmail => 'التحقق من البريد الإلكتروني';

  @override
  String get enterCodeSentTo => 'أدخل الرمز المرسل إلى';

  @override
  String get pleaseEnterCode => 'يرجى إدخال الرمز.';

  @override
  String get invalidCode => 'رمز غير صحيح، يرجى المحاولة مرة أخرى.';

  @override
  String get codeExpired => 'انتهت صلاحية الرمز، يرجى طلب رمز جديد.';

  @override
  String get verificationFailed => 'فشل التحقق، يرجى المحاولة مرة أخرى.';

  @override
  String get verifyAndContinue => 'تحقق وتابع';

  @override
  String get newCodeSent => 'تم إرسال رمز جديد!';

  @override
  String resendFailed(String e) {
    return 'فشل إعادة الإرسال: $e';
  }

  @override
  String get resendCode => 'أعد إرسال الرمز';

  @override
  String resendCodeIn(String seconds) {
    return 'أعد إرسال الرمز خلال $secondsث';
  }

  @override
  String get pleaseEnterEmail => 'يرجى إدخال بريدك الإلكتروني.';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get sendVerificationCode => 'إرسال رمز التحقق';

  @override
  String get codeSent => 'تم الإرسال! تحقق من بريدك الوارد.';

  @override
  String sendError(String e) {
    return 'خطأ: $e';
  }

  @override
  String get continueAsGuest => 'تابع كضيف';

  @override
  String get videoNotAllowed => 'يرجى اختيار صورة وليس فيديو.';
}
