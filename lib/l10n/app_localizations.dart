import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmail;

  /// No description provided for @enterCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to'**
  String get enterCodeSentTo;

  /// No description provided for @pleaseEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the code.'**
  String get pleaseEnterCode;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code. Please try again.'**
  String get invalidCode;

  /// No description provided for @codeExpired.
  ///
  /// In en, this message translates to:
  /// **'Code expired. Please request a new one.'**
  String get codeExpired;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Please try again.'**
  String get verificationFailed;

  /// No description provided for @verifyAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get verifyAndContinue;

  /// No description provided for @newCodeSent.
  ///
  /// In en, this message translates to:
  /// **'New code sent!'**
  String get newCodeSent;

  /// No description provided for @resendFailed.
  ///
  /// In en, this message translates to:
  /// **'Resend failed: {e}'**
  String resendFailed(String e);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendCodeIn(String seconds);

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email.'**
  String get pleaseEnterEmail;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'EMAIL ADDRESS'**
  String get emailLabel;

  /// No description provided for @sendVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Send Verification Code'**
  String get sendVerificationCode;

  /// No description provided for @codeSent.
  ///
  /// In en, this message translates to:
  /// **'Code sent! Check your inbox.'**
  String get codeSent;

  /// No description provided for @sendError.
  ///
  /// In en, this message translates to:
  /// **'Error: {e}'**
  String sendError(String e);

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @videoNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Please select an image, not a video.'**
  String get videoNotAllowed;

  /// No description provided for @signInWelcome1.
  ///
  /// In en, this message translates to:
  /// **'Welcome '**
  String get signInWelcome1;

  /// No description provided for @signInWelcome2.
  ///
  /// In en, this message translates to:
  /// **'back.'**
  String get signInWelcome2;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep their story safe across devices.'**
  String get signInSubtitle;

  /// No description provided for @signInOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get signInOr;

  /// No description provided for @signInJustExploring.
  ///
  /// In en, this message translates to:
  /// **'Just exploring? '**
  String get signInJustExploring;

  /// No description provided for @signInContinueAsGuestLink.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get signInContinueAsGuestLink;

  /// No description provided for @signInCooldown.
  ///
  /// In en, this message translates to:
  /// **'You can request another code in {seconds}s'**
  String signInCooldown(int seconds);

  /// No description provided for @signInEmailError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get signInEmailError;

  /// No description provided for @keepMemoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your local memories?'**
  String get keepMemoriesTitle;

  /// No description provided for @keepMemoriesContent.
  ///
  /// In en, this message translates to:
  /// **'You can keep the memories saved on this device with this account, or start fresh.'**
  String get keepMemoriesContent;

  /// No description provided for @keepMemoriesKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keepMemoriesKeep;

  /// No description provided for @keepMemoriesStartFresh.
  ///
  /// In en, this message translates to:
  /// **'Start Fresh'**
  String get keepMemoriesStartFresh;

  /// No description provided for @onbSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onbSkip;

  /// No description provided for @onbGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onbGetStarted;

  /// No description provided for @onb1Title1.
  ///
  /// In en, this message translates to:
  /// **'A childhood,'**
  String get onb1Title1;

  /// No description provided for @onb1Title2.
  ///
  /// In en, this message translates to:
  /// **'in nineteen frames.'**
  String get onb1Title2;

  /// No description provided for @onb1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'One photo per year,\nfrom birth to eighteen.'**
  String get onb1Subtitle;

  /// No description provided for @onb2Title1.
  ///
  /// In en, this message translates to:
  /// **'Everything they need.'**
  String get onb2Title1;

  /// No description provided for @onb2Title2.
  ///
  /// In en, this message translates to:
  /// **'Nothing they don\'t.'**
  String get onb2Title2;

  /// No description provided for @onb2Feature1Title.
  ///
  /// In en, this message translates to:
  /// **'One photo per year'**
  String get onb2Feature1Title;

  /// No description provided for @onb2Feature1Body.
  ///
  /// In en, this message translates to:
  /// **'Capture a single moment — no clutter, just growth.'**
  String get onb2Feature1Body;

  /// No description provided for @onb2Feature2Title.
  ///
  /// In en, this message translates to:
  /// **'19 year journey'**
  String get onb2Feature2Title;

  /// No description provided for @onb2Feature2Body.
  ///
  /// In en, this message translates to:
  /// **'From birth to eighteen, all in one place.'**
  String get onb2Feature2Body;

  /// No description provided for @onb2Feature3Title.
  ///
  /// In en, this message translates to:
  /// **'See them grow'**
  String get onb2Feature3Title;

  /// No description provided for @onb2Feature3Body.
  ///
  /// In en, this message translates to:
  /// **'Compare any two years side by side.'**
  String get onb2Feature3Body;

  /// No description provided for @onb3Title1.
  ///
  /// In en, this message translates to:
  /// **'Their story,'**
  String get onb3Title1;

  /// No description provided for @onb3Title2.
  ///
  /// In en, this message translates to:
  /// **'forever.'**
  String get onb3Title2;

  /// No description provided for @onb3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep their memories\nsafe across all your devices.'**
  String get onb3Subtitle;

  /// No description provided for @editChildTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Child'**
  String get editChildTitle;

  /// No description provided for @editChildNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Child name'**
  String get editChildNameLabel;

  /// No description provided for @editChildNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get editChildNotSelected;

  /// No description provided for @saveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveAction;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning!'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon!'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening!'**
  String get goodEvening;

  /// No description provided for @familyOverview.
  ///
  /// In en, this message translates to:
  /// **'Here\'s your family overview'**
  String get familyOverview;

  /// No description provided for @childrenLabel.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get childrenLabel;

  /// No description provided for @memoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get memoriesLabel;

  /// No description provided for @daysToBirthday.
  ///
  /// In en, this message translates to:
  /// **'Days to B-day'**
  String get daysToBirthday;

  /// No description provided for @noBirthday.
  ///
  /// In en, this message translates to:
  /// **'No birthday'**
  String get noBirthday;

  /// No description provided for @addChild.
  ///
  /// In en, this message translates to:
  /// **'Add Child'**
  String get addChild;

  /// No description provided for @noChildrenYet.
  ///
  /// In en, this message translates to:
  /// **'No children added yet'**
  String get noChildrenYet;

  /// No description provided for @startByAdding.
  ///
  /// In en, this message translates to:
  /// **'Start by adding your child to begin capturing their growth journey.'**
  String get startByAdding;

  /// No description provided for @signInToKeep.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep your account ready.'**
  String get signInToKeep;

  /// No description provided for @removeChildTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove child'**
  String get removeChildTitle;

  /// No description provided for @removeChildConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all memories for {name}.\nThis action cannot be undone.'**
  String removeChildConfirm(String name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @settingsAction.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsAction;

  /// No description provided for @logoutAction.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutAction;

  /// No description provided for @signInAction.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInAction;

  /// No description provided for @memorySingular.
  ///
  /// In en, this message translates to:
  /// **'memory'**
  String get memorySingular;

  /// No description provided for @memoriesPlural.
  ///
  /// In en, this message translates to:
  /// **'memories'**
  String get memoriesPlural;

  /// No description provided for @ageYearSingular.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get ageYearSingular;

  /// No description provided for @ageYearsPlural.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get ageYearsPlural;

  /// No description provided for @ageMonthSingular.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get ageMonthSingular;

  /// No description provided for @ageMonthsPlural.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get ageMonthsPlural;

  /// No description provided for @ageDaySingular.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get ageDaySingular;

  /// No description provided for @ageDaysPlural.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get ageDaysPlural;

  /// No description provided for @ageNewborn.
  ///
  /// In en, this message translates to:
  /// **'Newborn'**
  String get ageNewborn;

  /// No description provided for @timelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timelineTitle;

  /// No description provided for @nOfNineteen.
  ///
  /// In en, this message translates to:
  /// **'{n} of 19 memories'**
  String nOfNineteen(int n);

  /// No description provided for @birth.
  ///
  /// In en, this message translates to:
  /// **'Birth'**
  String get birth;

  /// No description provided for @capturedLabel.
  ///
  /// In en, this message translates to:
  /// **'Captured'**
  String get capturedLabel;

  /// No description provided for @nowLabel.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get nowLabel;

  /// No description provided for @waitingLabel.
  ///
  /// In en, this message translates to:
  /// **'waiting'**
  String get waitingLabel;

  /// No description provided for @tapToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap to add'**
  String get tapToAdd;

  /// No description provided for @theJourney.
  ///
  /// In en, this message translates to:
  /// **'THE JOURNEY'**
  String get theJourney;

  /// No description provided for @importNudgeText.
  ///
  /// In en, this message translates to:
  /// **'Import existing photos to fill in past years.'**
  String get importNudgeText;

  /// No description provided for @importingPhotos.
  ///
  /// In en, this message translates to:
  /// **'Importing photos…'**
  String get importingPhotos;

  /// No description provided for @importCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Complete'**
  String get importCompleteTitle;

  /// No description provided for @importResult.
  ///
  /// In en, this message translates to:
  /// **'Imported {imported} photos.\nSkipped {skipped} (no date, out of range, or year already filled).'**
  String importResult(int imported, int skipped);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @firstMemorySaved.
  ///
  /// In en, this message translates to:
  /// **'✨ First memory saved'**
  String get firstMemorySaved;

  /// No description provided for @allMemoriesComplete.
  ///
  /// In en, this message translates to:
  /// **'🏁 All memories completed\nA lifetime captured'**
  String get allMemoriesComplete;

  /// No description provided for @yearCompleted.
  ///
  /// In en, this message translates to:
  /// **'🎉 Year {year} completed'**
  String yearCompleted(int year);

  /// No description provided for @memorySavedSnack.
  ///
  /// In en, this message translates to:
  /// **'💜 Memory saved'**
  String get memorySavedSnack;

  /// No description provided for @yearN.
  ///
  /// In en, this message translates to:
  /// **'Year {n}'**
  String yearN(int n);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get preferences;

  /// No description provided for @birthdayReminders.
  ///
  /// In en, this message translates to:
  /// **'Birthday Reminders'**
  String get birthdayReminders;

  /// No description provided for @birthdayRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified before birthdays'**
  String get birthdayRemindersSubtitle;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark theme'**
  String get darkModeSubtitle;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'LEGAL'**
  String get legal;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About SeeMeGrow'**
  String get aboutApp;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get account;

  /// No description provided for @guestMode.
  ///
  /// In en, this message translates to:
  /// **'Guest Mode'**
  String get guestMode;

  /// No description provided for @guestModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your account for future sync features'**
  String get guestModeSubtitle;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// No description provided for @freeBadge.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freeBadge;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmContent;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Logout failed: {e}'**
  String logoutFailed(String e);

  /// No description provided for @clearDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Data & Reset'**
  String get clearDataTitle;

  /// No description provided for @clearDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all local data and sign out'**
  String get clearDataSubtitle;

  /// No description provided for @clearDataContent.
  ///
  /// In en, this message translates to:
  /// **'This will delete all local children and photos from this device. This cannot be undone.'**
  String get clearDataContent;

  /// No description provided for @clearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearAction;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountContent.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and all data including children, photos, and memories. This cannot be undone.'**
  String get deleteAccountContent;

  /// No description provided for @deleteAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountAction;

  /// No description provided for @newChildTitle.
  ///
  /// In en, this message translates to:
  /// **'New Child'**
  String get newChildTitle;

  /// No description provided for @aNewChapter.
  ///
  /// In en, this message translates to:
  /// **'A new chapter'**
  String get aNewChapter;

  /// No description provided for @begins.
  ///
  /// In en, this message translates to:
  /// **'begins.'**
  String get begins;

  /// No description provided for @childNameHint.
  ///
  /// In en, this message translates to:
  /// **'Child\'s name'**
  String get childNameHint;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get nameLabel;

  /// No description provided for @birthDateLabel.
  ///
  /// In en, this message translates to:
  /// **'BIRTH DATE'**
  String get birthDateLabel;

  /// No description provided for @selectBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Select birth date'**
  String get selectBirthDate;

  /// No description provided for @beginStory.
  ///
  /// In en, this message translates to:
  /// **'Begin {name}\'s story'**
  String beginStory(String name);

  /// No description provided for @beginTheirStory.
  ///
  /// In en, this message translates to:
  /// **'Begin their story'**
  String get beginTheirStory;

  /// No description provided for @nameAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This name already exists.'**
  String get nameAlreadyExists;

  /// No description provided for @earlyAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'SeeMeGrow is free\nduring early access.'**
  String get earlyAccessTitle;

  /// No description provided for @earlyAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re focusing on making the experience\nstable and useful for families first.'**
  String get earlyAccessSubtitle;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @tapToAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to add a photo'**
  String get tapToAddPhoto;

  /// No description provided for @memorySavedPhoto.
  ///
  /// In en, this message translates to:
  /// **'✨ Memory saved'**
  String get memorySavedPhoto;

  /// No description provided for @failedToSavePhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to save photo: {e}'**
  String failedToSavePhoto(String e);

  /// No description provided for @couldNotSaveImage.
  ///
  /// In en, this message translates to:
  /// **'Could not save image: {e}'**
  String couldNotSaveImage(String e);

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @compareBeforeLabel.
  ///
  /// In en, this message translates to:
  /// **'BEFORE'**
  String get compareBeforeLabel;

  /// No description provided for @compareAfterLabel.
  ///
  /// In en, this message translates to:
  /// **'AFTER'**
  String get compareAfterLabel;

  /// No description provided for @saveImage.
  ///
  /// In en, this message translates to:
  /// **'Save image'**
  String get saveImage;

  /// No description provided for @addPhotosToCompare.
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 photos\nto compare growth'**
  String get addPhotosToCompare;

  /// No description provided for @ageN.
  ///
  /// In en, this message translates to:
  /// **'Age {n}'**
  String ageN(int n);

  /// No description provided for @addBirthPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add birth photo'**
  String get addBirthPhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @swipeDownToClose.
  ///
  /// In en, this message translates to:
  /// **'Swipe down to close'**
  String get swipeDownToClose;

  /// No description provided for @resetFailed.
  ///
  /// In en, this message translates to:
  /// **'Reset failed: {e}'**
  String resetFailed(String e);

  /// No description provided for @couldNotOpenUrl.
  ///
  /// In en, this message translates to:
  /// **'Could not open {url}'**
  String couldNotOpenUrl(String url);

  /// No description provided for @accountDeletionFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t complete account deletion.\nPlease contact support@seemegrow.app.'**
  String get accountDeletionFailed;

  /// No description provided for @quote01.
  ///
  /// In en, this message translates to:
  /// **'Every moment with your child is a memory worth keeping.'**
  String get quote01;

  /// No description provided for @quote02.
  ///
  /// In en, this message translates to:
  /// **'Children grow so fast — capture every smile.'**
  String get quote02;

  /// No description provided for @quote03.
  ///
  /// In en, this message translates to:
  /// **'The littlest feet make the biggest footprints in our hearts.'**
  String get quote03;

  /// No description provided for @quote04.
  ///
  /// In en, this message translates to:
  /// **'A child\'s laughter is the best sound in the world.'**
  String get quote04;

  /// No description provided for @quote05.
  ///
  /// In en, this message translates to:
  /// **'Today\'s little moments become tomorrow\'s precious memories.'**
  String get quote05;

  /// No description provided for @quote06.
  ///
  /// In en, this message translates to:
  /// **'Watching you grow is the greatest adventure.'**
  String get quote06;

  /// No description provided for @quote07.
  ///
  /// In en, this message translates to:
  /// **'Every day is a new chapter in your child\'s story.'**
  String get quote07;

  /// No description provided for @quote08.
  ///
  /// In en, this message translates to:
  /// **'The best thing to spend on your child is time.'**
  String get quote08;

  /// No description provided for @quote09.
  ///
  /// In en, this message translates to:
  /// **'In the eyes of a child, you will see the world as it should be.'**
  String get quote09;

  /// No description provided for @quote10.
  ///
  /// In en, this message translates to:
  /// **'Childhood is a short season — make it sweet.'**
  String get quote10;

  /// No description provided for @quote11.
  ///
  /// In en, this message translates to:
  /// **'One day you\'ll look back and realize these were the big moments.'**
  String get quote11;

  /// No description provided for @quote12.
  ///
  /// In en, this message translates to:
  /// **'Growth is a journey best measured in love.'**
  String get quote12;

  /// No description provided for @quote13.
  ///
  /// In en, this message translates to:
  /// **'Small hands, big dreams — capture them all.'**
  String get quote13;

  /// No description provided for @quote14.
  ///
  /// In en, this message translates to:
  /// **'The days are long but the years are short.'**
  String get quote14;

  /// No description provided for @quote15.
  ///
  /// In en, this message translates to:
  /// **'Every photo tells a story of how much they\'ve grown.'**
  String get quote15;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
