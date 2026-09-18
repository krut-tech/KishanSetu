import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';

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
    Locale('gu'),
    Locale('hi')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Farmer Market Linkage'**
  String get appName;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Farmer Market Linkage & Price Discovery'**
  String get appTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Farmer Market Linkage'**
  String get welcomeMessage;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Empowering farmers with direct market access and true price discovery'**
  String get tagline;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection available.'**
  String get noInternetConnection;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @emptyStateMessage.
  ///
  /// In en, this message translates to:
  /// **'No data available at the moment.'**
  String get emptyStateMessage;

  /// No description provided for @farmerRole.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get farmerRole;

  /// No description provided for @buyerRole.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get buyerRole;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi (हिंदी)'**
  String get hindi;

  /// No description provided for @gujarati.
  ///
  /// In en, this message translates to:
  /// **'Gujarati (ગુજરાતી)'**
  String get gujarati;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Initializing market linkage system...'**
  String get splashLoading;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @marketPrices.
  ///
  /// In en, this message translates to:
  /// **'Market Prices'**
  String get marketPrices;

  /// No description provided for @myProduce.
  ///
  /// In en, this message translates to:
  /// **'My Produce'**
  String get myProduce;

  /// No description provided for @offers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get offers;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @selectRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Your Role'**
  String get selectRoleTitle;

  /// No description provided for @selectRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to use the platform'**
  String get selectRoleSubtitle;

  /// No description provided for @farmerOptionTitle.
  ///
  /// In en, this message translates to:
  /// **'I am a Farmer (किसान)'**
  String get farmerOptionTitle;

  /// No description provided for @farmerOptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'List produce, view true net price realization, and get direct buyer offers.'**
  String get farmerOptionSubtitle;

  /// No description provided for @buyerOptionTitle.
  ///
  /// In en, this message translates to:
  /// **'I am a Buyer / Trader (खरीदार)'**
  String get buyerOptionTitle;

  /// No description provided for @buyerOptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Source quality produce directly from farmers, post requirements, and place bids.'**
  String get buyerOptionSubtitle;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get completeProfile;

  /// No description provided for @farmLocation.
  ///
  /// In en, this message translates to:
  /// **'Farm Location'**
  String get farmLocation;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @village.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get village;

  /// No description provided for @landSize.
  ///
  /// In en, this message translates to:
  /// **'Farm Size (Acres)'**
  String get landSize;

  /// No description provided for @primaryCrop.
  ///
  /// In en, this message translates to:
  /// **'Primary Crop'**
  String get primaryCrop;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Company / Business Name'**
  String get companyName;

  /// No description provided for @businessType.
  ///
  /// In en, this message translates to:
  /// **'Business Type'**
  String get businessType;

  /// No description provided for @buyingCapacity.
  ///
  /// In en, this message translates to:
  /// **'Buying Capacity (Quintals)'**
  String get buyingCapacity;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get saveProfile;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @farmerHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Farmer Dashboard'**
  String get farmerHomeTitle;

  /// No description provided for @buyerHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Buyer Dashboard'**
  String get buyerHomeTitle;

  /// No description provided for @marketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplace;

  /// No description provided for @myOffers.
  ///
  /// In en, this message translates to:
  /// **'My Offers'**
  String get myOffers;

  /// No description provided for @browseMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Browse Marketplace'**
  String get browseMarketplace;

  /// No description provided for @makeOffer.
  ///
  /// In en, this message translates to:
  /// **'Make Offer'**
  String get makeOffer;

  /// No description provided for @cancelOffer.
  ///
  /// In en, this message translates to:
  /// **'Cancel Offer'**
  String get cancelOffer;

  /// No description provided for @offeredPrice.
  ///
  /// In en, this message translates to:
  /// **'Offered Price'**
  String get offeredPrice;

  /// No description provided for @offerQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get offerQuantity;

  /// No description provided for @offerMessage.
  ///
  /// In en, this message translates to:
  /// **'Message to Farmer'**
  String get offerMessage;

  /// No description provided for @submitOffer.
  ///
  /// In en, this message translates to:
  /// **'Submit Offer'**
  String get submitOffer;

  /// No description provided for @availableProduce.
  ///
  /// In en, this message translates to:
  /// **'Available Produce'**
  String get availableProduce;

  /// No description provided for @activeOffers.
  ///
  /// In en, this message translates to:
  /// **'Active Offers'**
  String get activeOffers;

  /// No description provided for @pendingOffers.
  ///
  /// In en, this message translates to:
  /// **'Pending Offers'**
  String get pendingOffers;

  /// No description provided for @acceptedOffers.
  ///
  /// In en, this message translates to:
  /// **'Accepted Offers'**
  String get acceptedOffers;

  /// No description provided for @featuredProduce.
  ///
  /// In en, this message translates to:
  /// **'Featured Produce'**
  String get featuredProduce;

  /// No description provided for @recentOffers.
  ///
  /// In en, this message translates to:
  /// **'Recent Offers'**
  String get recentOffers;

  /// No description provided for @noProduceAvailable.
  ///
  /// In en, this message translates to:
  /// **'No produce available at the moment.'**
  String get noProduceAvailable;

  /// No description provided for @noOffersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No offers created yet.'**
  String get noOffersAvailable;
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
      <String>['en', 'gu', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
