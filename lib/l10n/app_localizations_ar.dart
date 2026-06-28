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
  String get invalidCode => 'رمز غير صحيح. يرجى المحاولة مرة أخرى.';

  @override
  String get codeExpired => 'انتهت صلاحية الرمز. يرجى طلب رمز جديد.';

  @override
  String get verificationFailed => 'فشل التحقق. يرجى المحاولة مرة أخرى.';

  @override
  String get verifyAndContinue => 'تحقق وتابع';

  @override
  String get newCodeSent => 'تم إرسال رمز جديد!';

  @override
  String resendFailed(String e) {
    return 'فشل إعادة الإرسال: $e';
  }

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String resendCodeIn(String seconds) {
    return 'إعادة الإرسال بعد $secondsث';
  }

  @override
  String get pleaseEnterEmail => 'يرجى إدخال بريدك الإلكتروني.';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get sendVerificationCode => 'إرسال رمز التحقق';

  @override
  String get codeSent => 'تم الإرسال! تحقق من بريدك.';

  @override
  String sendError(String e) {
    return 'خطأ: $e';
  }

  @override
  String get continueAsGuest => 'المتابعة كضيف';

  @override
  String get videoNotAllowed => 'يرجى اختيار صورة وليس فيديو.';

  @override
  String get signInWelcome1 => 'مرحباً ';

  @override
  String get signInWelcome2 => 'بعودتك.';

  @override
  String get signInSubtitle => 'سجّل الدخول للحفاظ على قصتهم عبر جميع أجهزتك.';

  @override
  String get signInOr => 'أو';

  @override
  String get signInJustExploring => 'تريد الاستكشاف فقط؟ ';

  @override
  String get signInContinueAsGuestLink => 'تابع كضيف';

  @override
  String signInCooldown(int seconds) {
    return 'يمكنك طلب رمز جديد خلال $secondsث';
  }

  @override
  String get signInEmailError => 'يرجى إدخال بريد إلكتروني صحيح.';

  @override
  String get keepMemoriesTitle => 'هل تريد الاحتفاظ بذكرياتك؟';

  @override
  String get keepMemoriesContent =>
      'يمكنك الاحتفاظ بالذكريات المحفوظة على هذا الجهاز مع حسابك، أو البدء من جديد.';

  @override
  String get keepMemoriesKeep => 'احتفظ بها';

  @override
  String get keepMemoriesStartFresh => 'ابدأ من جديد';

  @override
  String get onbSkip => 'تخطي';

  @override
  String get onbGetStarted => 'ابدأ';

  @override
  String get onb1Title1 => 'طفولة';

  @override
  String get onb1Title2 => 'في تسعة عشر إطاراً.';

  @override
  String get onb1Subtitle =>
      'صورة واحدة لكل سنة،\nمن الميلاد حتى الثامنة عشرة.';

  @override
  String get onb2Title1 => 'كل ما يحتاجونه.';

  @override
  String get onb2Title2 => 'لا شيء غير ذلك.';

  @override
  String get onb2Feature1Title => 'صورة واحدة لكل سنة';

  @override
  String get onb2Feature1Body => 'لحظة واحدة — بلا تشتت، فقط نمو.';

  @override
  String get onb2Feature2Title => 'رحلة 19 سنة';

  @override
  String get onb2Feature2Body => 'من الميلاد حتى الثامنة عشرة، في مكان واحد.';

  @override
  String get onb2Feature3Title => 'شاهدهم يكبرون';

  @override
  String get onb2Feature3Body => 'قارن أي سنتين جنباً إلى جنب.';

  @override
  String get onb3Title1 => 'قصتهم،';

  @override
  String get onb3Title2 => 'للأبد.';

  @override
  String get onb3Subtitle =>
      'سجّل الدخول لحفظ ذكرياتهم\nبأمان على جميع أجهزتك.';

  @override
  String get editChildTitle => 'تعديل الطفل';

  @override
  String get editChildNameLabel => 'اسم الطفل';

  @override
  String get editChildNotSelected => 'غير محدد';

  @override
  String get saveAction => 'حفظ';

  @override
  String get goodMorning => 'صباح الخير!';

  @override
  String get goodAfternoon => 'مساء الخير!';

  @override
  String get goodEvening => 'مساء النور!';

  @override
  String get familyOverview => 'نظرة على عائلتك';

  @override
  String get childrenLabel => 'الأطفال';

  @override
  String get memoriesLabel => 'الذكريات';

  @override
  String get daysToBirthday => 'أيام للعيد';

  @override
  String get noBirthday => 'لا يوجد عيد';

  @override
  String get addChild => 'إضافة طفل';

  @override
  String get noChildrenYet => 'لم تُضَف أي أطفال بعد';

  @override
  String get startByAdding => 'ابدأ بإضافة طفلك لتوثيق رحلة نموه.';

  @override
  String get signInToKeep => 'سجّل الدخول للحفاظ على حسابك.';

  @override
  String get removeChildTitle => 'حذف الطفل';

  @override
  String removeChildConfirm(String name) {
    return 'سيتم حذف جميع ذكريات $name بشكل نهائي.\nلا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get remove => 'حذف';

  @override
  String get editAction => 'تعديل';

  @override
  String get deleteAction => 'حذف';

  @override
  String get settingsAction => 'الإعدادات';

  @override
  String get logoutAction => 'تسجيل الخروج';

  @override
  String get signInAction => 'تسجيل الدخول';

  @override
  String get memorySingular => 'ذكرى';

  @override
  String get memoriesPlural => 'ذكريات';

  @override
  String get ageYearSingular => 'سنة';

  @override
  String get ageYearsPlural => 'سنوات';

  @override
  String get ageMonthSingular => 'شهر';

  @override
  String get ageMonthsPlural => 'أشهر';

  @override
  String get ageDaySingular => 'يوم';

  @override
  String get ageDaysPlural => 'أيام';

  @override
  String get ageNewborn => 'حديث الولادة';

  @override
  String get timelineTitle => 'المسيرة';

  @override
  String nOfNineteen(int n) {
    return '$n من 19 ذكرى';
  }

  @override
  String get birth => 'الميلاد';

  @override
  String get capturedLabel => 'محفوظة';

  @override
  String get nowLabel => 'الآن';

  @override
  String get waitingLabel => 'في الانتظار';

  @override
  String get tapToAdd => 'اضغط للإضافة';

  @override
  String get theJourney => 'الرحلة';

  @override
  String get importNudgeText => 'استورد الصور القديمة لملء السنوات الماضية.';

  @override
  String get importingPhotos => 'جارٍ الاستيراد…';

  @override
  String get importCompleteTitle => 'اكتمل الاستيراد';

  @override
  String importResult(int imported, int skipped) {
    return 'تم استيراد $imported صورة.\nتم تخطي $skipped (لا تاريخ، خارج النطاق، أو السنة ممتلئة).';
  }

  @override
  String get ok => 'حسناً';

  @override
  String get firstMemorySaved => '✨ أول ذكرى محفوظة';

  @override
  String get allMemoriesComplete => '🏁 اكتملت جميع الذكريات\nعمر بأكمله موثّق';

  @override
  String yearCompleted(int year) {
    return '🎉 اكتملت السنة $year';
  }

  @override
  String get memorySavedSnack => '💜 ذكرى محفوظة';

  @override
  String yearN(int n) {
    return 'السنة $n';
  }

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get preferences => 'التفضيلات';

  @override
  String get birthdayReminders => 'تذكيرات أعياد الميلاد';

  @override
  String get birthdayRemindersSubtitle =>
      'الحصول على إشعارات قبل أعياد الميلاد';

  @override
  String get darkMode => 'الوضع المظلم';

  @override
  String get darkModeSubtitle => 'التبديل إلى السمة المظلمة';

  @override
  String get legal => 'قانوني';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get termsOfService => 'شروط الخدمة';

  @override
  String get support => 'الدعم';

  @override
  String get aboutApp => 'حول SeeMeGrow';

  @override
  String get account => 'الحساب';

  @override
  String get guestMode => 'وضع الضيف';

  @override
  String get guestModeSubtitle => 'استخدم حسابك لميزات المزامنة';

  @override
  String get upgradeToPro => 'الترقية إلى Pro';

  @override
  String get freeBadge => 'مجاني';

  @override
  String get logoutConfirmTitle => 'تسجيل الخروج';

  @override
  String get logoutConfirmContent => 'هل أنت متأكد من تسجيل الخروج؟';

  @override
  String logoutFailed(String e) {
    return 'فشل تسجيل الخروج: $e';
  }

  @override
  String get clearDataTitle => 'مسح البيانات وإعادة الضبط';

  @override
  String get clearDataSubtitle => 'حذف جميع البيانات المحلية وتسجيل الخروج';

  @override
  String get clearDataContent =>
      'سيتم حذف جميع الأطفال والصور من هذا الجهاز. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get clearAction => 'مسح';

  @override
  String get deleteAccountTitle => 'حذف الحساب';

  @override
  String get deleteAccountContent =>
      'سيتم حذف حسابك وجميع بياناتك بشكل نهائي بما في ذلك الأطفال والصور والذكريات. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get deleteAccountAction => 'حذف الحساب';

  @override
  String get newChildTitle => 'طفل جديد';

  @override
  String get aNewChapter => 'فصل جديد';

  @override
  String get begins => 'يبدأ.';

  @override
  String get childNameHint => 'اسم الطفل';

  @override
  String get nameLabel => 'الاسم';

  @override
  String get birthDateLabel => 'تاريخ الميلاد';

  @override
  String get selectBirthDate => 'اختر تاريخ الميلاد';

  @override
  String beginStory(String name) {
    return 'ابدأ قصة $name';
  }

  @override
  String get beginTheirStory => 'ابدأ قصته';

  @override
  String get nameAlreadyExists => 'هذا الاسم موجود بالفعل.';

  @override
  String get earlyAccessTitle => 'SeeMeGrow مجاني\nخلال الوصول المبكر.';

  @override
  String get earlyAccessSubtitle =>
      'نركز على تقديم تجربة\nمستقرة ومفيدة للعائلات أولاً.';

  @override
  String get continueAction => 'متابعة';

  @override
  String get tapToAddPhoto => 'اضغط لإضافة صورة';

  @override
  String get memorySavedPhoto => '✨ ذكرى محفوظة';

  @override
  String failedToSavePhoto(String e) {
    return 'فشل حفظ الصورة: $e';
  }

  @override
  String couldNotSaveImage(String e) {
    return 'تعذّر حفظ الصورة: $e';
  }

  @override
  String get goBack => 'رجوع';

  @override
  String get compareBeforeLabel => 'قبل';

  @override
  String get compareAfterLabel => 'بعد';

  @override
  String get saveImage => 'حفظ الصورة';

  @override
  String get addPhotosToCompare => 'أضف صورتين على الأقل\nلمقارنة النمو';

  @override
  String ageN(int n) {
    return 'السنة $n';
  }

  @override
  String get addBirthPhoto => 'أضف صورة الميلاد';

  @override
  String get takePhoto => 'التقط صورة';

  @override
  String get chooseFromGallery => 'اختر من المعرض';

  @override
  String get swipeDownToClose => 'اسحب لأسفل للإغلاق';

  @override
  String resetFailed(String e) {
    return 'فشلت إعادة الضبط: $e';
  }

  @override
  String couldNotOpenUrl(String url) {
    return 'تعذّر فتح $url';
  }

  @override
  String get accountDeletionFailed =>
      'تعذّر إتمام حذف الحساب.\nيرجى التواصل مع support@seemegrow.app.';

  @override
  String get quote01 => 'كل لحظة مع طفلك تستحق أن تُحفظ.';

  @override
  String get quote02 => 'يكبر الأطفال بسرعة — سجّل كل ابتسامة.';

  @override
  String get quote03 => 'أصغر الأقدام تترك أعمق الآثار في قلوبنا.';

  @override
  String get quote04 => 'ضحكة الطفل أجمل صوت في الدنيا.';

  @override
  String get quote05 => 'اللحظات الصغيرة اليوم تصبح الذكريات الثمينة غداً.';

  @override
  String get quote06 => 'مشاهدتك تكبر أعظم مغامرة في حياتي.';

  @override
  String get quote07 => 'كل يوم فصل جديد في قصة طفلك.';

  @override
  String get quote08 => 'أثمن ما تمنحه لطفلك هو وقتك.';

  @override
  String get quote09 => 'في عيون الطفل سترى العالم كما ينبغي أن يكون.';

  @override
  String get quote10 => 'الطفولة موسم قصير — اجعله جميلاً.';

  @override
  String get quote11 =>
      'يوماً ما ستنظر للوراء وتدرك أن هذه كانت اللحظات العظيمة.';

  @override
  String get quote12 => 'النمو رحلة يُقاس بالحب.';

  @override
  String get quote13 => 'أيدٍ صغيرة وأحلام كبيرة — سجّلها كلها.';

  @override
  String get quote14 => 'الأيام طويلة والسنوات قصيرة.';

  @override
  String get quote15 => 'كل صورة تحكي كيف كبرت.';
}
