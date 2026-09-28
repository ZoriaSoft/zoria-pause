// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Zoria Pause';

  @override
  String get statusHeading => 'PRIVATE DNS';

  @override
  String get statusProtectionOn => 'Protection on';

  @override
  String get statusAuto => 'Auto';

  @override
  String get statusPaused => 'Paused';

  @override
  String get controlHeading => 'AD BLOCKING';

  @override
  String get controlOn => 'ON';

  @override
  String get controlAuto => 'AUTO';

  @override
  String get controlPaused => 'PAUSED';

  @override
  String get controlTapPause => 'tap: pause';

  @override
  String get controlTapResume => 'tap: resume';

  @override
  String get errorNotGranted =>
      'Setup needed first: grant the one-time permission.';

  @override
  String get errorUnsupported =>
      'This device is not supported (Android 9+ required).';

  @override
  String get errorGeneric => 'Status could not be read.';

  @override
  String get statusReading => 'Reading status';

  @override
  String get statusNoHostname => 'none';

  @override
  String get setupTitle => 'Setup';

  @override
  String get setupTabSetup => 'SETUP';

  @override
  String get setupTabGuide => 'STEP BY STEP';

  @override
  String get setupIntro =>
      'Pausing your ad-blocking Private DNS needs a one-time permission from Android. Grant it once and you are done; the app touches nothing else and sends nothing over the internet. The easiest path is done on the phone and needs a Wi-Fi connection.';

  @override
  String get setupPathShizukuTitle => 'OPTION 1 · PHONE ONLY (RECOMMENDED)';

  @override
  String get setupLegacyAndroidNote =>
      'The phone-only setup needs Android 11 or newer, so it is not available on this phone. Nothing is lost: connect the phone to a computer with USB once and run the command below — the permission is permanent either way.';

  @override
  String get setupPathShizukuSteps =>
      '1. Install Shizuku from Play Store with the button below (free, trusted helper).\n2. Open Shizuku and follow the \'start via wireless debugging\' steps. Your phone must be on Wi-Fi.\n3. Come back to Zoria Pause and tap ALLOW below. The full walkthrough is in the step-by-step guide.';

  @override
  String get setupGuideButton => 'STEP BY STEP GUIDE';

  @override
  String get shizukuNeedInstall =>
      'Setting up with just the phone needs a small helper app: Shizuku. It is free on Play Store; you can even remove it once this is done.';

  @override
  String get shizukuInstallButton => 'INSTALL FROM PLAY STORE';

  @override
  String get shizukuStartHint =>
      'Shizuku is installed but not started yet. Open it, start it via \'wireless debugging\', then come back here. This page refreshes itself when you return.';

  @override
  String get shizukuOpenButton => 'OPEN SHIZUKU';

  @override
  String get shizukuReady =>
      'Shizuku is ready. Permission can be granted with one tap.';

  @override
  String get shizukuGrantButton => 'ALLOW';

  @override
  String get shizukuGrantFailed =>
      'Could not grant. Make sure Shizuku is running and try again.';

  @override
  String get setupPathPcTitle => 'OPTION 2 · WITH A PC AND A HELPER';

  @override
  String get setupPathPcSteps =>
      'Fastest route if someone can plug the phone into a computer with USB. That person runs the command below. USB debugging must be on, on the phone.';

  @override
  String get setupCommandHeader => 'COMMAND TO RUN ON THE COMPUTER:';

  @override
  String get setupCopy => 'Copy command';

  @override
  String get setupCopied => 'Copied';

  @override
  String get advancedWirelessTitle =>
      'Advanced: wireless computer link (Android 11+)';

  @override
  String get setupPathWirelessSteps =>
      'No USB cable? Pair Wireless debugging from Developer options on the phone, then run the same command over the air from the computer.';

  @override
  String get devOptionsTitle => 'Developer options turned off?';

  @override
  String get devOptionsSteps =>
      '1. Settings → About phone.\n2. Tap Build number 7 times.\n3. Once it says \'You are now a developer\', go back; Developer options appears in Settings.';

  @override
  String get setupCheckAgain => 'Check again';

  @override
  String get guideIntro =>
      'The full walkthrough for phone-only setup. Takes about 5 minutes and is done only once.';

  @override
  String get guideStep1Title => 'Connect to a Wi-Fi network';

  @override
  String get guideStep1Body =>
      'Wireless debugging works over Wi-Fi; keep the phone connected throughout the setup.';

  @override
  String get guideStep2Title => 'Turn on Developer options';

  @override
  String get guideStep2Body =>
      'Settings → About phone → tap Build number 7 times. Once it says \'You are now a developer\' you are done.';

  @override
  String get guideStep3Title => 'Turn on Wireless debugging';

  @override
  String get guideStep3Body =>
      'Settings → Developer options → Wireless debugging on. Allow the network if asked.';

  @override
  String get guideStep4Title => 'Install Shizuku';

  @override
  String get guideStep4Body =>
      'Install it free from Play Store. You can remove it once everything is done.';

  @override
  String get guideStep5Title => 'Start Shizuku';

  @override
  String get guideStep5Body =>
      'Open Shizuku and choose \'Start via wireless debugging\'. The phone takes you to the pairing screen in Settings; type the code shown there into Shizuku.';

  @override
  String get guideStep6Title => 'See it running';

  @override
  String get guideStep6Body =>
      'Wait until Shizuku\'s home screen shows it is running.';

  @override
  String get guideStep7Title => 'Return to Zoria Pause and grant';

  @override
  String get guideStep7Body =>
      'Tap ALLOW on the setup screen. That is it: the permission is permanent and these steps never repeat.';

  @override
  String get guideRebootNote =>
      'Note: if the phone restarts, Shizuku stops and must be started again. The permission you gave Zoria Pause is permanent.';

  @override
  String get guideTroubleNote =>
      'Stuck? Turn Wi-Fi off and on, then repeat the pairing step. If the pairing notification does not appear, open Wireless debugging in Settings and tap \'Pair device with pairing code\' yourself.';

  @override
  String get durationLabel => 'AUTO-RESUME';

  @override
  String get durationRelabel => 'REPLAN';

  @override
  String get durationForever => 'No timer';

  @override
  String get minutesShort => 'min';

  @override
  String get resumeAtLabel => 'Resumes at';

  @override
  String get autoResumeNote => 'System alarms may be off by about a minute.';

  @override
  String get unscheduledNote =>
      'No auto-resume. Tap the button above to resume, or plan a duration below.';

  @override
  String weeklyCount(int count) {
    return 'Paused $count times this week';
  }

  @override
  String get honestDelayNote => 'Takes effect within 1-2 minutes.';

  @override
  String get notifPermTitle => 'NOTIFICATION PERMISSION';

  @override
  String get notifPermBody =>
      'While paused we may send two small notifications: the resume time and an ends-soon heads-up. Without permission the app still works; you just will not see those times as notifications.';

  @override
  String get notifPermGrant => 'ALLOW';

  @override
  String get notifPermLater => 'NOT NOW';

  @override
  String get notifOffNote =>
      'Notifications off: the resume time will not appear as a notification.';

  @override
  String get tileHintTitle => 'FOR ONE-TAP CONTROL';

  @override
  String get tileHintBody =>
      'Swipe down with two fingers to open the quick settings panel. Tap EDIT, find Zoria Pause and drag it up. From then on you can pause without opening the app.';

  @override
  String get tileHintDone => 'DONE, ADDED IT';

  @override
  String get reminderBandTitle => 'ENDS SOON';

  @override
  String get reminderBandExtend => '+5 MIN';

  @override
  String get providerCardTitle => 'AD BLOCKING NOT SET UP';

  @override
  String get providerCardBody =>
      'Your phone has no blocking DNS yet, so there is nothing for the app to pause. Free, account-less AdGuard DNS can be set up with one tap.';

  @override
  String get providerSetupButton => 'SET UP ADGUARD';

  @override
  String get providerManualLink =>
      'Have your own DNS server? Enter it manually';

  @override
  String get providerManualTitle => 'DNS ADDRESS';

  @override
  String get providerManualHint => 'e.g. dns.adguard.com';

  @override
  String get providerManualApply => 'SET UP';

  @override
  String get providerManualCancel => 'CANCEL';

  @override
  String get providerManualInvalid =>
      'Enter a valid address, e.g. dns.adguard.com';

  @override
  String get infoTitle => 'WHAT GETS BLOCKED?';

  @override
  String get infoBlocksLabel => 'BLOCKS';

  @override
  String get infoBlocks =>
      'Banner and pop-up ads on the web, in-app ad banners and interstitials, tracker/analytics beacons — anything served from known ad servers.';

  @override
  String get infoLimitsLabel => 'DOESN\'T BLOCK';

  @override
  String get infoLimits =>
      'Ads served from the same source as the content itself: YouTube video ads, Instagram-style feed ads.';

  @override
  String get infoHowLabel => 'HOW IT WORKS';

  @override
  String get infoHow =>
      'Known ad servers resolve to \'not found\', so the ad can\'t load. Your connection stays encrypted; content traffic is untouched.';

  @override
  String get homeSetupTooltip => 'Setup guide';
}
