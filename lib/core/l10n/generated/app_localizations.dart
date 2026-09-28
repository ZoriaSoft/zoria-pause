import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('en'),
    Locale('tr'),
  ];

  /// App display name shown in the system and app bar.
  ///
  /// In en, this message translates to:
  /// **'Zoria Pause'**
  String get appTitle;

  /// Status band label above the current DNS mode/hostname.
  ///
  /// In en, this message translates to:
  /// **'PRIVATE DNS'**
  String get statusHeading;

  /// Shown when private_dns_mode is hostname (enforcing).
  ///
  /// In en, this message translates to:
  /// **'Protection on'**
  String get statusProtectionOn;

  /// Shown when private_dns_mode is opportunistic or unset (not enforcing).
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get statusAuto;

  /// Shown when private_dns_mode is off.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statusPaused;

  /// Control plate heading; pre-uppercased in ARB (TR i-to-İ trap).
  ///
  /// In en, this message translates to:
  /// **'AD BLOCKING'**
  String get controlHeading;

  /// Control plate state; pre-uppercased in ARB.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get controlOn;

  /// Control plate state for opportunistic; pre-uppercased in ARB.
  ///
  /// In en, this message translates to:
  /// **'AUTO'**
  String get controlAuto;

  /// Control plate state; pre-uppercased in ARB.
  ///
  /// In en, this message translates to:
  /// **'PAUSED'**
  String get controlPaused;

  /// Action hint under the plate state.
  ///
  /// In en, this message translates to:
  /// **'tap: pause'**
  String get controlTapPause;

  /// Action hint under the plate state while paused.
  ///
  /// In en, this message translates to:
  /// **'tap: resume'**
  String get controlTapResume;

  /// WRITE_SECURE_SETTINGS grant missing; router gate normally catches this.
  ///
  /// In en, this message translates to:
  /// **'Setup needed first: grant the one-time permission.'**
  String get errorNotGranted;

  /// Private DNS does not exist below API 28.
  ///
  /// In en, this message translates to:
  /// **'This device is not supported (Android 9+ required).'**
  String get errorUnsupported;

  /// Native bridge or platform error fallback.
  ///
  /// In en, this message translates to:
  /// **'Status could not be read.'**
  String get errorGeneric;

  /// Loading placeholder; not the slop word Loading.
  ///
  /// In en, this message translates to:
  /// **'Reading status'**
  String get statusReading;

  /// Plate hostname when specifier is empty; no em-dash.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get statusNoHostname;

  /// Setup screen title (permission guide).
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get setupTitle;

  /// First setup tab label; pre-uppercased in ARB.
  ///
  /// In en, this message translates to:
  /// **'SETUP'**
  String get setupTabSetup;

  /// Visual guide tab label; pre-uppercased in ARB.
  ///
  /// In en, this message translates to:
  /// **'STEP BY STEP'**
  String get setupTabGuide;

  /// Intro paragraph; plain language, Wi-Fi requirement called out.
  ///
  /// In en, this message translates to:
  /// **'Pausing your ad-blocking Private DNS needs a one-time permission from Android. Grant it once and you are done; the app touches nothing else and sends nothing over the internet. The easiest path is done on the phone and needs a Wi-Fi connection.'**
  String get setupIntro;

  /// Primary setup path: Shizuku helper, no PC needed.
  ///
  /// In en, this message translates to:
  /// **'OPTION 1 · PHONE ONLY (RECOMMENDED)'**
  String get setupPathShizukuTitle;

  /// Shown instead of the Shizuku card on API 28-29 (SDK gate); redirects to the PC/adb path.
  ///
  /// In en, this message translates to:
  /// **'The phone-only setup needs Android 11 or newer, so it is not available on this phone. Nothing is lost: connect the phone to a computer with USB once and run the command below — the permission is permanent either way.'**
  String get setupLegacyAndroidNote;

  /// Numbered steps for the phone-only path.
  ///
  /// In en, this message translates to:
  /// **'1. Install Shizuku from Play Store with the button below (free, trusted helper).\n2. Open Shizuku and follow the \'start via wireless debugging\' steps. Your phone must be on Wi-Fi.\n3. Come back to Zoria Pause and tap ALLOW below. The full walkthrough is in the step-by-step guide.'**
  String get setupPathShizukuSteps;

  /// Opens the full Shizuku walkthrough from the setup screen; pre-uppercased in ARB.
  ///
  /// In en, this message translates to:
  /// **'STEP BY STEP GUIDE'**
  String get setupGuideButton;

  /// Not-installed card copy; leads to the Play Store button.
  ///
  /// In en, this message translates to:
  /// **'Setting up with just the phone needs a small helper app: Shizuku. It is free on Play Store; you can even remove it once this is done.'**
  String get shizukuNeedInstall;

  /// Opens Shizuku's Play Store page; pre-uppercased in ARB.
  ///
  /// In en, this message translates to:
  /// **'INSTALL FROM PLAY STORE'**
  String get shizukuInstallButton;

  /// Not-running card copy; leads to the open-Shizuku button.
  ///
  /// In en, this message translates to:
  /// **'Shizuku is installed but not started yet. Open it, start it via \'wireless debugging\', then come back here. This page refreshes itself when you return.'**
  String get shizukuStartHint;

  /// Launches the Shizuku app; pre-uppercased in ARB.
  ///
  /// In en, this message translates to:
  /// **'OPEN SHIZUKU'**
  String get shizukuOpenButton;

  /// Ready card status line.
  ///
  /// In en, this message translates to:
  /// **'Shizuku is ready. Permission can be granted with one tap.'**
  String get shizukuReady;

  /// One-tap grant button; pre-uppercased in ARB (TR i-to-İ trap).
  ///
  /// In en, this message translates to:
  /// **'ALLOW'**
  String get shizukuGrantButton;

  /// Snackbar when the Shizuku grant flow fails to start.
  ///
  /// In en, this message translates to:
  /// **'Could not grant. Make sure Shizuku is running and try again.'**
  String get shizukuGrantFailed;

  /// Secondary path: someone runs the command from a computer.
  ///
  /// In en, this message translates to:
  /// **'OPTION 2 · WITH A PC AND A HELPER'**
  String get setupPathPcTitle;

  /// Plain-language steps for the PC path.
  ///
  /// In en, this message translates to:
  /// **'Fastest route if someone can plug the phone into a computer with USB. That person runs the command below. USB debugging must be on, on the phone.'**
  String get setupPathPcSteps;

  /// Header above the copyable adb grant command.
  ///
  /// In en, this message translates to:
  /// **'COMMAND TO RUN ON THE COMPUTER:'**
  String get setupCommandHeader;

  /// Copy-to-clipboard button label.
  ///
  /// In en, this message translates to:
  /// **'Copy command'**
  String get setupCopy;

  /// Snackbar after copying.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get setupCopied;

  /// Collapsed advanced section title.
  ///
  /// In en, this message translates to:
  /// **'Advanced: wireless computer link (Android 11+)'**
  String get advancedWirelessTitle;

  /// Wireless variant of the PC path, one paragraph.
  ///
  /// In en, this message translates to:
  /// **'No USB cable? Pair Wireless debugging from Developer options on the phone, then run the same command over the air from the computer.'**
  String get setupPathWirelessSteps;

  /// Collapsed helper section title.
  ///
  /// In en, this message translates to:
  /// **'Developer options turned off?'**
  String get devOptionsTitle;

  /// How to unlock developer options, numbered.
  ///
  /// In en, this message translates to:
  /// **'1. Settings → About phone.\n2. Tap Build number 7 times.\n3. Once it says \'You are now a developer\', go back; Developer options appears in Settings.'**
  String get devOptionsSteps;

  /// Re-check grant button.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get setupCheckAgain;

  /// Guide tab intro line.
  ///
  /// In en, this message translates to:
  /// **'The full walkthrough for phone-only setup. Takes about 5 minutes and is done only once.'**
  String get guideIntro;

  /// No description provided for @guideStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Connect to a Wi-Fi network'**
  String get guideStep1Title;

  /// No description provided for @guideStep1Body.
  ///
  /// In en, this message translates to:
  /// **'Wireless debugging works over Wi-Fi; keep the phone connected throughout the setup.'**
  String get guideStep1Body;

  /// No description provided for @guideStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Turn on Developer options'**
  String get guideStep2Title;

  /// No description provided for @guideStep2Body.
  ///
  /// In en, this message translates to:
  /// **'Settings → About phone → tap Build number 7 times. Once it says \'You are now a developer\' you are done.'**
  String get guideStep2Body;

  /// No description provided for @guideStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Turn on Wireless debugging'**
  String get guideStep3Title;

  /// No description provided for @guideStep3Body.
  ///
  /// In en, this message translates to:
  /// **'Settings → Developer options → Wireless debugging on. Allow the network if asked.'**
  String get guideStep3Body;

  /// No description provided for @guideStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Install Shizuku'**
  String get guideStep4Title;

  /// No description provided for @guideStep4Body.
  ///
  /// In en, this message translates to:
  /// **'Install it free from Play Store. You can remove it once everything is done.'**
  String get guideStep4Body;

  /// No description provided for @guideStep5Title.
  ///
  /// In en, this message translates to:
  /// **'Start Shizuku'**
  String get guideStep5Title;

  /// No description provided for @guideStep5Body.
  ///
  /// In en, this message translates to:
  /// **'Open Shizuku and choose \'Start via wireless debugging\'. The phone takes you to the pairing screen in Settings; type the code shown there into Shizuku.'**
  String get guideStep5Body;

  /// No description provided for @guideStep6Title.
  ///
  /// In en, this message translates to:
  /// **'See it running'**
  String get guideStep6Title;

  /// No description provided for @guideStep6Body.
  ///
  /// In en, this message translates to:
  /// **'Wait until Shizuku\'s home screen shows it is running.'**
  String get guideStep6Body;

  /// No description provided for @guideStep7Title.
  ///
  /// In en, this message translates to:
  /// **'Return to Zoria Pause and grant'**
  String get guideStep7Title;

  /// No description provided for @guideStep7Body.
  ///
  /// In en, this message translates to:
  /// **'Tap ALLOW on the setup screen. That is it: the permission is permanent and these steps never repeat.'**
  String get guideStep7Body;

  /// No description provided for @guideRebootNote.
  ///
  /// In en, this message translates to:
  /// **'Note: if the phone restarts, Shizuku stops and must be started again. The permission you gave Zoria Pause is permanent.'**
  String get guideRebootNote;

  /// Troubleshooting note at the end of the guide.
  ///
  /// In en, this message translates to:
  /// **'Stuck? Turn Wi-Fi off and on, then repeat the pairing step. If the pairing notification does not appear, open Wireless debugging in Settings and tap \'Pair device with pairing code\' yourself.'**
  String get guideTroubleNote;

  /// Label above the duration selector while protection is on.
  ///
  /// In en, this message translates to:
  /// **'AUTO-RESUME'**
  String get durationLabel;

  /// Label above the duration selector while paused; pre-uppercased in ARB.
  ///
  /// In en, this message translates to:
  /// **'REPLAN'**
  String get durationRelabel;

  /// Fourth duration chip: pause with no auto-resume.
  ///
  /// In en, this message translates to:
  /// **'No timer'**
  String get durationForever;

  /// Short minutes unit on duration chips.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesShort;

  /// Prefix for the scheduled auto-resume time.
  ///
  /// In en, this message translates to:
  /// **'Resumes at'**
  String get resumeAtLabel;

  /// Honest inexact-alarm note (PLAN dürstlük notu).
  ///
  /// In en, this message translates to:
  /// **'System alarms may be off by about a minute.'**
  String get autoResumeNote;

  /// Shown when paused with no plan (no-timer pause or manual system-settings off).
  ///
  /// In en, this message translates to:
  /// **'No auto-resume. Tap the button above to resume, or plan a duration below.'**
  String get unscheduledNote;

  /// Mini weekly summary from the event log.
  ///
  /// In en, this message translates to:
  /// **'Paused {count} times this week'**
  String weeklyCount(int count);

  /// No description provided for @honestDelayNote.
  ///
  /// In en, this message translates to:
  /// **'Takes effect within 1-2 minutes.'**
  String get honestDelayNote;

  /// Info card title; pre-uppercased in ARB.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATION PERMISSION'**
  String get notifPermTitle;

  /// Non-scary rationale: what notifications do and what is lost without them.
  ///
  /// In en, this message translates to:
  /// **'While paused we may send two small notifications: the resume time and an ends-soon heads-up. Without permission the app still works; you just will not see those times as notifications.'**
  String get notifPermBody;

  /// Accept button; pre-uppercased in ARB.
  ///
  /// In en, this message translates to:
  /// **'ALLOW'**
  String get notifPermGrant;

  /// Decline button, still pauses; pre-uppercased in ARB.
  ///
  /// In en, this message translates to:
  /// **'NOT NOW'**
  String get notifPermLater;

  /// Honest note under the paused section when permission is missing.
  ///
  /// In en, this message translates to:
  /// **'Notifications off: the resume time will not appear as a notification.'**
  String get notifOffNote;

  /// One-time tile onboarding card title; pre-uppercased in ARB.
  ///
  /// In en, this message translates to:
  /// **'FOR ONE-TAP CONTROL'**
  String get tileHintTitle;

  /// How to add the QS tile, one-time.
  ///
  /// In en, this message translates to:
  /// **'Swipe down with two fingers to open the quick settings panel. Tap EDIT, find Zoria Pause and drag it up. From then on you can pause without opening the app.'**
  String get tileHintBody;

  /// Dismiss button; pre-uppercased in ARB.
  ///
  /// In en, this message translates to:
  /// **'DONE, ADDED IT'**
  String get tileHintDone;

  /// In-panel ends-soon band; pre-uppercased in ARB.
  ///
  /// In en, this message translates to:
  /// **'ENDS SOON'**
  String get reminderBandTitle;

  /// Extend action on the reminder band and notification; pre-uppercased in ARB.
  ///
  /// In en, this message translates to:
  /// **'+5 MIN'**
  String get reminderBandExtend;

  /// One-time provider setup card title; pre-uppercased in ARB.
  ///
  /// In en, this message translates to:
  /// **'AD BLOCKING NOT SET UP'**
  String get providerCardTitle;

  /// Why the card exists + the one-tap offer.
  ///
  /// In en, this message translates to:
  /// **'Your phone has no blocking DNS yet, so there is nothing for the app to pause. Free, account-less AdGuard DNS can be set up with one tap.'**
  String get providerCardBody;

  /// One-tap provider setup button; pre-uppercased in ARB.
  ///
  /// In en, this message translates to:
  /// **'SET UP ADGUARD'**
  String get providerSetupButton;

  /// Small link under the one-tap button.
  ///
  /// In en, this message translates to:
  /// **'Have your own DNS server? Enter it manually'**
  String get providerManualLink;

  /// Manual hostname dialog title; pre-uppercased in ARB.
  ///
  /// In en, this message translates to:
  /// **'DNS ADDRESS'**
  String get providerManualTitle;

  /// TextField hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. dns.adguard.com'**
  String get providerManualHint;

  /// Dialog apply button; pre-uppercased in ARB.
  ///
  /// In en, this message translates to:
  /// **'SET UP'**
  String get providerManualApply;

  /// Dialog cancel button; pre-uppercased in ARB.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get providerManualCancel;

  /// Validation error line.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid address, e.g. dns.adguard.com'**
  String get providerManualInvalid;

  /// Collapsible info card title; pre-uppercased.
  ///
  /// In en, this message translates to:
  /// **'WHAT GETS BLOCKED?'**
  String get infoTitle;

  /// Sub-label; pre-uppercased.
  ///
  /// In en, this message translates to:
  /// **'BLOCKS'**
  String get infoBlocksLabel;

  /// What gets blocked, one honest sentence.
  ///
  /// In en, this message translates to:
  /// **'Banner and pop-up ads on the web, in-app ad banners and interstitials, tracker/analytics beacons — anything served from known ad servers.'**
  String get infoBlocks;

  /// Sub-label; pre-uppercased.
  ///
  /// In en, this message translates to:
  /// **'DOESN\'T BLOCK'**
  String get infoLimitsLabel;

  /// Honest limits of DNS-level blocking.
  ///
  /// In en, this message translates to:
  /// **'Ads served from the same source as the content itself: YouTube video ads, Instagram-style feed ads.'**
  String get infoLimits;

  /// Sub-label; pre-uppercased.
  ///
  /// In en, this message translates to:
  /// **'HOW IT WORKS'**
  String get infoHowLabel;

  /// One-line mechanism explanation.
  ///
  /// In en, this message translates to:
  /// **'Known ad servers resolve to \'not found\', so the ad can\'t load. Your connection stays encrypted; content traffic is untouched.'**
  String get infoHow;

  /// App bar setup guide icon tooltip.
  ///
  /// In en, this message translates to:
  /// **'Setup guide'**
  String get homeSetupTooltip;
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
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
