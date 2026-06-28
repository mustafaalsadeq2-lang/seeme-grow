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

  @override
  String get signInWelcome1 => 'Welcome ';

  @override
  String get signInWelcome2 => 'back.';

  @override
  String get signInSubtitle =>
      'Sign in to keep their story safe across devices.';

  @override
  String get signInOr => 'or';

  @override
  String get signInJustExploring => 'Just exploring? ';

  @override
  String get signInContinueAsGuestLink => 'Continue as guest';

  @override
  String signInCooldown(int seconds) {
    return 'You can request another code in ${seconds}s';
  }

  @override
  String get signInEmailError => 'Please enter a valid email address.';

  @override
  String get keepMemoriesTitle => 'Keep your local memories?';

  @override
  String get keepMemoriesContent =>
      'You can keep the memories saved on this device with this account, or start fresh.';

  @override
  String get keepMemoriesKeep => 'Keep';

  @override
  String get keepMemoriesStartFresh => 'Start Fresh';

  @override
  String get onbSkip => 'Skip';

  @override
  String get onbGetStarted => 'Get Started';

  @override
  String get onb1Title1 => 'A childhood,';

  @override
  String get onb1Title2 => 'in nineteen frames.';

  @override
  String get onb1Subtitle => 'One photo per year,\nfrom birth to eighteen.';

  @override
  String get onb2Title1 => 'Everything they need.';

  @override
  String get onb2Title2 => 'Nothing they don\'t.';

  @override
  String get onb2Feature1Title => 'One photo per year';

  @override
  String get onb2Feature1Body =>
      'Capture a single moment — no clutter, just growth.';

  @override
  String get onb2Feature2Title => '19 year journey';

  @override
  String get onb2Feature2Body => 'From birth to eighteen, all in one place.';

  @override
  String get onb2Feature3Title => 'See them grow';

  @override
  String get onb2Feature3Body => 'Compare any two years side by side.';

  @override
  String get onb3Title1 => 'Their story,';

  @override
  String get onb3Title2 => 'forever.';

  @override
  String get onb3Subtitle =>
      'Sign in to keep their memories\nsafe across all your devices.';

  @override
  String get editChildTitle => 'Edit Child';

  @override
  String get editChildNameLabel => 'Child name';

  @override
  String get editChildNotSelected => 'Not selected';

  @override
  String get saveAction => 'Save';

  @override
  String get goodMorning => 'Good Morning!';

  @override
  String get goodAfternoon => 'Good Afternoon!';

  @override
  String get goodEvening => 'Good Evening!';

  @override
  String get familyOverview => 'Here\'s your family overview';

  @override
  String get childrenLabel => 'Children';

  @override
  String get memoriesLabel => 'Memories';

  @override
  String get daysToBirthday => 'Days to B-day';

  @override
  String get noBirthday => 'No birthday';

  @override
  String get addChild => 'Add Child';

  @override
  String get noChildrenYet => 'No children added yet';

  @override
  String get startByAdding =>
      'Start by adding your child to begin capturing their growth journey.';

  @override
  String get signInToKeep => 'Sign in to keep your account ready.';

  @override
  String get removeChildTitle => 'Remove child';

  @override
  String removeChildConfirm(String name) {
    return 'This will permanently delete all memories for $name.\nThis action cannot be undone.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String get editAction => 'Edit';

  @override
  String get deleteAction => 'Delete';

  @override
  String get settingsAction => 'Settings';

  @override
  String get logoutAction => 'Logout';

  @override
  String get signInAction => 'Sign In';

  @override
  String get memorySingular => 'memory';

  @override
  String get memoriesPlural => 'memories';

  @override
  String get ageYearSingular => 'year';

  @override
  String get ageYearsPlural => 'years';

  @override
  String get ageMonthSingular => 'month';

  @override
  String get ageMonthsPlural => 'months';

  @override
  String get ageDaySingular => 'day';

  @override
  String get ageDaysPlural => 'days';

  @override
  String get ageNewborn => 'Newborn';

  @override
  String get timelineTitle => 'Timeline';

  @override
  String nOfNineteen(int n) {
    return '$n of 19 memories';
  }

  @override
  String get birth => 'Birth';

  @override
  String get capturedLabel => 'Captured';

  @override
  String get nowLabel => 'NOW';

  @override
  String get waitingLabel => 'waiting';

  @override
  String get tapToAdd => 'Tap to add';

  @override
  String get theJourney => 'THE JOURNEY';

  @override
  String get importNudgeText => 'Import existing photos to fill in past years.';

  @override
  String get importingPhotos => 'Importing photos…';

  @override
  String get importCompleteTitle => 'Import Complete';

  @override
  String importResult(int imported, int skipped) {
    return 'Imported $imported photos.\nSkipped $skipped (no date, out of range, or year already filled).';
  }

  @override
  String get ok => 'OK';

  @override
  String get firstMemorySaved => '✨ First memory saved';

  @override
  String get allMemoriesComplete =>
      '🏁 All memories completed\nA lifetime captured';

  @override
  String yearCompleted(int year) {
    return '🎉 Year $year completed';
  }

  @override
  String get memorySavedSnack => '💜 Memory saved';

  @override
  String yearN(int n) {
    return 'Year $n';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get preferences => 'PREFERENCES';

  @override
  String get birthdayReminders => 'Birthday Reminders';

  @override
  String get birthdayRemindersSubtitle => 'Get notified before birthdays';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkModeSubtitle => 'Switch to dark theme';

  @override
  String get legal => 'LEGAL';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get support => 'Support';

  @override
  String get aboutApp => 'About SeeMeGrow';

  @override
  String get account => 'ACCOUNT';

  @override
  String get guestMode => 'Guest Mode';

  @override
  String get guestModeSubtitle => 'Use your account for future sync features';

  @override
  String get upgradeToPro => 'Upgrade to Pro';

  @override
  String get freeBadge => 'Free';

  @override
  String get logoutConfirmTitle => 'Logout';

  @override
  String get logoutConfirmContent => 'Are you sure you want to logout?';

  @override
  String logoutFailed(String e) {
    return 'Logout failed: $e';
  }

  @override
  String get clearDataTitle => 'Clear Data & Reset';

  @override
  String get clearDataSubtitle => 'Delete all local data and sign out';

  @override
  String get clearDataContent =>
      'This will delete all local children and photos from this device. This cannot be undone.';

  @override
  String get clearAction => 'Clear';

  @override
  String get deleteAccountTitle => 'Delete Account';

  @override
  String get deleteAccountContent =>
      'This will permanently delete your account and all data including children, photos, and memories. This cannot be undone.';

  @override
  String get deleteAccountAction => 'Delete Account';

  @override
  String get newChildTitle => 'New Child';

  @override
  String get aNewChapter => 'A new chapter';

  @override
  String get begins => 'begins.';

  @override
  String get childNameHint => 'Child\'s name';

  @override
  String get nameLabel => 'NAME';

  @override
  String get birthDateLabel => 'BIRTH DATE';

  @override
  String get selectBirthDate => 'Select birth date';

  @override
  String beginStory(String name) {
    return 'Begin $name\'s story';
  }

  @override
  String get beginTheirStory => 'Begin their story';

  @override
  String get nameAlreadyExists => 'This name already exists.';

  @override
  String get earlyAccessTitle => 'SeeMeGrow is free\nduring early access.';

  @override
  String get earlyAccessSubtitle =>
      'We\'re focusing on making the experience\nstable and useful for families first.';

  @override
  String get continueAction => 'Continue';

  @override
  String get tapToAddPhoto => 'Tap to add a photo';

  @override
  String get memorySavedPhoto => '✨ Memory saved';

  @override
  String failedToSavePhoto(String e) {
    return 'Failed to save photo: $e';
  }

  @override
  String couldNotSaveImage(String e) {
    return 'Could not save image: $e';
  }

  @override
  String get goBack => 'Go Back';

  @override
  String get compareBeforeLabel => 'BEFORE';

  @override
  String get compareAfterLabel => 'AFTER';

  @override
  String get saveImage => 'Save image';

  @override
  String get addPhotosToCompare => 'Add at least 2 photos\nto compare growth';

  @override
  String ageN(int n) {
    return 'Age $n';
  }

  @override
  String get addBirthPhoto => 'Add birth photo';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get swipeDownToClose => 'Swipe down to close';

  @override
  String resetFailed(String e) {
    return 'Reset failed: $e';
  }

  @override
  String couldNotOpenUrl(String url) {
    return 'Could not open $url';
  }

  @override
  String get accountDeletionFailed =>
      'We couldn\'t complete account deletion.\nPlease contact support@seemegrow.app.';

  @override
  String get quote01 =>
      'Every moment with your child is a memory worth keeping.';

  @override
  String get quote02 => 'Children grow so fast — capture every smile.';

  @override
  String get quote03 =>
      'The littlest feet make the biggest footprints in our hearts.';

  @override
  String get quote04 => 'A child\'s laughter is the best sound in the world.';

  @override
  String get quote05 =>
      'Today\'s little moments become tomorrow\'s precious memories.';

  @override
  String get quote06 => 'Watching you grow is the greatest adventure.';

  @override
  String get quote07 => 'Every day is a new chapter in your child\'s story.';

  @override
  String get quote08 => 'The best thing to spend on your child is time.';

  @override
  String get quote09 =>
      'In the eyes of a child, you will see the world as it should be.';

  @override
  String get quote10 => 'Childhood is a short season — make it sweet.';

  @override
  String get quote11 =>
      'One day you\'ll look back and realize these were the big moments.';

  @override
  String get quote12 => 'Growth is a journey best measured in love.';

  @override
  String get quote13 => 'Small hands, big dreams — capture them all.';

  @override
  String get quote14 => 'The days are long but the years are short.';

  @override
  String get quote15 => 'Every photo tells a story of how much they\'ve grown.';
}
