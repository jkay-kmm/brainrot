// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Settings`
  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: '',
      args: [],
    );
  }

  /// `Screen Time Goal`
  String get screenTimeGoal {
    return Intl.message(
      'Screen Time Goal',
      name: 'screenTimeGoal',
      desc: '',
      args: [],
    );
  }

  /// `hours`
  String get hours {
    return Intl.message(
      'hours',
      name: 'hours',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get language {
    return Intl.message(
      'Language',
      name: 'language',
      desc: '',
      args: [],
    );
  }

  /// `Change app language`
  String get changeLanguage {
    return Intl.message(
      'Change app language',
      name: 'changeLanguage',
      desc: '',
      args: [],
    );
  }

  /// `English`
  String get english {
    return Intl.message(
      'English',
      name: 'english',
      desc: '',
      args: [],
    );
  }

  /// `Tiếng Việt`
  String get vietnamese {
    return Intl.message(
      'Tiếng Việt',
      name: 'vietnamese',
      desc: '',
      args: [],
    );
  }

  /// `Support & Feedback`
  String get supportFeedback {
    return Intl.message(
      'Support & Feedback',
      name: 'supportFeedback',
      desc: '',
      args: [],
    );
  }

  /// `Help & Support`
  String get helpSupport {
    return Intl.message(
      'Help & Support',
      name: 'helpSupport',
      desc: '',
      args: [],
    );
  }

  /// `Feature Requests`
  String get featureRequests {
    return Intl.message(
      'Feature Requests',
      name: 'featureRequests',
      desc: '',
      args: [],
    );
  }

  /// `Leave a Review`
  String get leaveReview {
    return Intl.message(
      'Leave a Review',
      name: 'leaveReview',
      desc: '',
      args: [],
    );
  }

  /// `Contact Us`
  String get contactUs {
    return Intl.message(
      'Contact Us',
      name: 'contactUs',
      desc: '',
      args: [],
    );
  }

  /// `Legal`
  String get legal {
    return Intl.message(
      'Legal',
      name: 'legal',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Policy`
  String get privacyPolicy {
    return Intl.message(
      'Privacy Policy',
      name: 'privacyPolicy',
      desc: '',
      args: [],
    );
  }

  /// `Dark Mode`
  String get darkMode {
    return Intl.message(
      'Dark Mode',
      name: 'darkMode',
      desc: '',
      args: [],
    );
  }

  /// `Switch between light and dark theme`
  String get switchTheme {
    return Intl.message(
      'Switch between light and dark theme',
      name: 'switchTheme',
      desc: '',
      args: [],
    );
  }

  /// `App Version 1.0.0`
  String get appVersion {
    return Intl.message(
      'App Version 1.0.0',
      name: 'appVersion',
      desc: '',
      args: [],
    );
  }

  /// `Home`
  String get home {
    return Intl.message(
      'Home',
      name: 'home',
      desc: '',
      args: [],
    );
  }

  /// `Stats`
  String get stats {
    return Intl.message(
      'Stats',
      name: 'stats',
      desc: '',
      args: [],
    );
  }

  /// `Blocking`
  String get blocking {
    return Intl.message(
      'Blocking',
      name: 'blocking',
      desc: '',
      args: [],
    );
  }

  /// `App Locking`
  String get appLocking {
    return Intl.message(
      'App Locking',
      name: 'appLocking',
      desc: '',
      args: [],
    );
  }

  /// `Rules`
  String get rules {
    return Intl.message(
      'Rules',
      name: 'rules',
      desc: '',
      args: [],
    );
  }

  /// `Focus`
  String get focus {
    return Intl.message(
      'Focus',
      name: 'focus',
      desc: '',
      args: [],
    );
  }

  /// `Apps`
  String get apps {
    return Intl.message(
      'Apps',
      name: 'apps',
      desc: '',
      args: [],
    );
  }

  /// `Blocked`
  String get blocked {
    return Intl.message(
      'Blocked',
      name: 'blocked',
      desc: '',
      args: [],
    );
  }

  /// `Limited`
  String get limited {
    return Intl.message(
      'Limited',
      name: 'limited',
      desc: '',
      args: [],
    );
  }

  /// `Allowed`
  String get allowed {
    return Intl.message(
      'Allowed',
      name: 'allowed',
      desc: '',
      args: [],
    );
  }

  /// `App Status`
  String get appStatus {
    return Intl.message(
      'App Status',
      name: 'appStatus',
      desc: '',
      args: [],
    );
  }

  /// `Available Focus Modes`
  String get availableFocusModes {
    return Intl.message(
      'Available Focus Modes',
      name: 'availableFocusModes',
      desc: '',
      args: [],
    );
  }

  /// `No rules active right now - you should set some!`
  String get noActiveRulesWarning {
    return Intl.message(
      'No rules active right now - you should set some!',
      name: 'noActiveRulesWarning',
      desc: '',
      args: [],
    );
  }

  /// `apps targeted`
  String get appsTargeted {
    return Intl.message(
      'apps targeted',
      name: 'appsTargeted',
      desc: '',
      args: [],
    );
  }

  /// `Today`
  String get today {
    return Intl.message(
      'Today',
      name: 'today',
      desc: '',
      args: [],
    );
  }

  /// `Stop`
  String get stop {
    return Intl.message(
      'Stop',
      name: 'stop',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Start Indefinitely`
  String get startIndefinitely {
    return Intl.message(
      'Start Indefinitely',
      name: 'startIndefinitely',
      desc: '',
      args: [],
    );
  }

  /// `Duration`
  String get duration {
    return Intl.message(
      'Duration',
      name: 'duration',
      desc: '',
      args: [],
    );
  }

  /// `min`
  String get minutes {
    return Intl.message(
      'min',
      name: 'minutes',
      desc: '',
      args: [],
    );
  }

  /// `hour`
  String get hour {
    return Intl.message(
      'hour',
      name: 'hour',
      desc: '',
      args: [],
    );
  }

  /// `App Blocking Help`
  String get appBlockingHelp {
    return Intl.message(
      'App Blocking Help',
      name: 'appBlockingHelp',
      desc: '',
      args: [],
    );
  }

  /// `This screen helps you manage app blocking rules and focus modes.\n\n• Rules: Set time limits, schedules, and blocks for specific apps\n• Focus: Use predefined focus modes for different activities\n• Apps: View the current blocking status of all your apps\n\nToggle rules on/off using the switches, or start focus modes for immediate blocking.`
  String get appBlockingHelpContent {
    return Intl.message(
      'This screen helps you manage app blocking rules and focus modes.\\n\\n• Rules: Set time limits, schedules, and blocks for specific apps\\n• Focus: Use predefined focus modes for different activities\\n• Apps: View the current blocking status of all your apps\\n\\nToggle rules on/off using the switches, or start focus modes for immediate blocking.',
      name: 'appBlockingHelpContent',
      desc: '',
      args: [],
    );
  }

  /// `Got it!`
  String get gotIt {
    return Intl.message(
      'Got it!',
      name: 'gotIt',
      desc: '',
      args: [],
    );
  }

  /// `No focus mode is currently active. Select one below to start focusing.`
  String get noFocusModeActive {
    return Intl.message(
      'No focus mode is currently active. Select one below to start focusing.',
      name: 'noFocusModeActive',
      desc: '',
      args: [],
    );
  }

  /// `Start {focusModeName}?`
  String startFocusMode(Object focusModeName) {
    return Intl.message(
      'Start $focusModeName?',
      name: 'startFocusMode',
      desc: '',
      args: [focusModeName],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'vi'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
