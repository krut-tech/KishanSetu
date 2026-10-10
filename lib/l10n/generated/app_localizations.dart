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
  /// **'KisanSetu'**
  String get appName;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'KisanSetu — Farmer Market Linkage & Price Discovery'**
  String get appTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to KisanSetu'**
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

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset Filters'**
  String get resetFilters;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @recentlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Recently'**
  String get recentlyLabel;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not Provided'**
  String get notProvided;

  /// No description provided for @unitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get unitsLabel;

  /// No description provided for @produceLabel.
  ///
  /// In en, this message translates to:
  /// **'Produce'**
  String get produceLabel;

  /// No description provided for @farmerLabel.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get farmerLabel;

  /// No description provided for @buyerLabel.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get buyerLabel;

  /// No description provided for @generalLabel.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalLabel;

  /// No description provided for @allLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLabel;

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// No description provided for @sourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get sourceLabel;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @cerealsCategory.
  ///
  /// In en, this message translates to:
  /// **'Cereals'**
  String get cerealsCategory;

  /// No description provided for @pulsesCategory.
  ///
  /// In en, this message translates to:
  /// **'Pulses'**
  String get pulsesCategory;

  /// No description provided for @vegetablesCategory.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get vegetablesCategory;

  /// No description provided for @fruitsCategory.
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get fruitsCategory;

  /// No description provided for @oilseedsCategory.
  ///
  /// In en, this message translates to:
  /// **'Oilseeds'**
  String get oilseedsCategory;

  /// No description provided for @spicesCategory.
  ///
  /// In en, this message translates to:
  /// **'Spices'**
  String get spicesCategory;

  /// No description provided for @grainsCategory.
  ///
  /// In en, this message translates to:
  /// **'Grains'**
  String get grainsCategory;

  /// No description provided for @commercialCropsCategory.
  ///
  /// In en, this message translates to:
  /// **'Commercial Crops'**
  String get commercialCropsCategory;

  /// No description provided for @cottonFiberCategory.
  ///
  /// In en, this message translates to:
  /// **'Cotton & Fiber'**
  String get cottonFiberCategory;

  /// No description provided for @otherCategory.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherCategory;

  /// No description provided for @welcomeSubtitleFarmer.
  ///
  /// In en, this message translates to:
  /// **'Direct market access & transparent price discovery for your crops.'**
  String get welcomeSubtitleFarmer;

  /// No description provided for @welcomeSubtitleBuyer.
  ///
  /// In en, this message translates to:
  /// **'Direct crop procurement portal & price discovery marketplace.'**
  String get welcomeSubtitleBuyer;

  /// No description provided for @unableToLoadDashboard.
  ///
  /// In en, this message translates to:
  /// **'Unable to load dashboard'**
  String get unableToLoadDashboard;

  /// No description provided for @farmerProfileDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Farmer Profile Details'**
  String get farmerProfileDetailsTitle;

  /// No description provided for @buyerBusinessDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Buyer Business Details'**
  String get buyerBusinessDetailsTitle;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @landSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Land Size'**
  String get landSizeLabel;

  /// No description provided for @primaryCropLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary Crop'**
  String get primaryCropLabel;

  /// No description provided for @companyBusinessLabel.
  ///
  /// In en, this message translates to:
  /// **'Company / Business'**
  String get companyBusinessLabel;

  /// No description provided for @contactNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Name'**
  String get contactNameLabel;

  /// No description provided for @businessTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Business Type'**
  String get businessTypeLabel;

  /// No description provided for @buyingCapacityLabel.
  ///
  /// In en, this message translates to:
  /// **'Buying Capacity'**
  String get buyingCapacityLabel;

  /// No description provided for @gstNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'GST Number'**
  String get gstNumberLabel;

  /// No description provided for @acresLabel.
  ///
  /// In en, this message translates to:
  /// **'Acres'**
  String get acresLabel;

  /// No description provided for @locationNotSet.
  ///
  /// In en, this message translates to:
  /// **'Location not set'**
  String get locationNotSet;

  /// No description provided for @quickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActionsTitle;

  /// No description provided for @addProduceLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Produce'**
  String get addProduceLabel;

  /// No description provided for @browseAndBuy.
  ///
  /// In en, this message translates to:
  /// **'Browse & Buy'**
  String get browseAndBuy;

  /// No description provided for @mandiRates.
  ///
  /// In en, this message translates to:
  /// **'Mandi Rates'**
  String get mandiRates;

  /// No description provided for @trackBids.
  ///
  /// In en, this message translates to:
  /// **'Track Bids'**
  String get trackBids;

  /// No description provided for @companyInfo.
  ///
  /// In en, this message translates to:
  /// **'Company Info'**
  String get companyInfo;

  /// No description provided for @myProfileLabel.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfileLabel;

  /// No description provided for @produceOffersSummary.
  ///
  /// In en, this message translates to:
  /// **'Produce & Offers Summary'**
  String get produceOffersSummary;

  /// No description provided for @activeListings.
  ///
  /// In en, this message translates to:
  /// **'Active Listings'**
  String get activeListings;

  /// No description provided for @draftListings.
  ///
  /// In en, this message translates to:
  /// **'Draft Listings'**
  String get draftListings;

  /// No description provided for @soldProduce.
  ///
  /// In en, this message translates to:
  /// **'Sold Produce'**
  String get soldProduce;

  /// No description provided for @procurementSummary.
  ///
  /// In en, this message translates to:
  /// **'Procurement Summary'**
  String get procurementSummary;

  /// No description provided for @totalOffers.
  ///
  /// In en, this message translates to:
  /// **'Total Offers'**
  String get totalOffers;

  /// No description provided for @searchMarketPricesHint.
  ///
  /// In en, this message translates to:
  /// **'Search market prices by crop name...'**
  String get searchMarketPricesHint;

  /// No description provided for @sortPrices.
  ///
  /// In en, this message translates to:
  /// **'Sort Prices'**
  String get sortPrices;

  /// No description provided for @latestDate.
  ///
  /// In en, this message translates to:
  /// **'Latest Date'**
  String get latestDate;

  /// No description provided for @priceLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: Low to High'**
  String get priceLowToHigh;

  /// No description provided for @priceHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Price: High to Low'**
  String get priceHighToLow;

  /// No description provided for @noMarketPricesFound.
  ///
  /// In en, this message translates to:
  /// **'No Market Prices Found'**
  String get noMarketPricesFound;

  /// No description provided for @noMarketPricesFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No market price records match your current search or category filter.'**
  String get noMarketPricesFoundMessage;

  /// No description provided for @failedToLoadMarketPrices.
  ///
  /// In en, this message translates to:
  /// **'Failed to load market prices'**
  String get failedToLoadMarketPrices;

  /// No description provided for @marketPriceDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Market Price Details'**
  String get marketPriceDetailsTitle;

  /// No description provided for @rising.
  ///
  /// In en, this message translates to:
  /// **'Rising'**
  String get rising;

  /// No description provided for @falling.
  ///
  /// In en, this message translates to:
  /// **'Falling'**
  String get falling;

  /// No description provided for @stableTrend.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get stableTrend;

  /// No description provided for @noTrendData.
  ///
  /// In en, this message translates to:
  /// **'No trend data'**
  String get noTrendData;

  /// No description provided for @marketDetails.
  ///
  /// In en, this message translates to:
  /// **'Market Details'**
  String get marketDetails;

  /// No description provided for @marketMandiLabel.
  ///
  /// In en, this message translates to:
  /// **'Market / Mandi'**
  String get marketMandiLabel;

  /// No description provided for @priceDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Price Date'**
  String get priceDateLabel;

  /// No description provided for @lastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last Synced'**
  String get lastSynced;

  /// No description provided for @priceDetailsFooterNote.
  ///
  /// In en, this message translates to:
  /// **'Prices shown are as last reported for this market and may change whenever updated data is published for this crop.'**
  String get priceDetailsFooterNote;

  /// No description provided for @marketPriceHighlightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Market Price Highlights'**
  String get marketPriceHighlightsTitle;

  /// No description provided for @noMarketPricesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Market Prices Available'**
  String get noMarketPricesAvailable;

  /// No description provided for @marketPricesWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Market price updates will appear here once published.'**
  String get marketPricesWillAppear;

  /// No description provided for @marketPriceInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Market Price Insights'**
  String get marketPriceInsightsTitle;

  /// No description provided for @averagePrice.
  ///
  /// In en, this message translates to:
  /// **'Average Price'**
  String get averagePrice;

  /// No description provided for @highestPrice.
  ///
  /// In en, this message translates to:
  /// **'Highest Price'**
  String get highestPrice;

  /// No description provided for @lowestPrice.
  ///
  /// In en, this message translates to:
  /// **'Lowest Price'**
  String get lowestPrice;

  /// No description provided for @noPriceDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No price data available to calculate market analytics.'**
  String get noPriceDataAvailable;

  /// No description provided for @recentOffersReceived.
  ///
  /// In en, this message translates to:
  /// **'Recent Offers Received'**
  String get recentOffersReceived;

  /// No description provided for @noOffersReceivedYet.
  ///
  /// In en, this message translates to:
  /// **'No Offers Received Yet'**
  String get noOffersReceivedYet;

  /// No description provided for @offersFromBuyersWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Offers from interested buyers will appear here.'**
  String get offersFromBuyersWillAppear;

  /// No description provided for @produceListingLabel.
  ///
  /// In en, this message translates to:
  /// **'Produce Listing'**
  String get produceListingLabel;

  /// No description provided for @recentLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentLabel;

  /// No description provided for @interestedBuyer.
  ///
  /// In en, this message translates to:
  /// **'Interested Buyer'**
  String get interestedBuyer;

  /// No description provided for @myRecentOffers.
  ///
  /// In en, this message translates to:
  /// **'My Recent Offers'**
  String get myRecentOffers;

  /// No description provided for @noSubmittedOffersYet.
  ///
  /// In en, this message translates to:
  /// **'No Submitted Offers Yet'**
  String get noSubmittedOffersYet;

  /// No description provided for @browseMarketplaceSubmitBids.
  ///
  /// In en, this message translates to:
  /// **'Browse marketplace listings and submit bids directly to farmers.'**
  String get browseMarketplaceSubmitBids;

  /// No description provided for @noProduceListedYet.
  ///
  /// In en, this message translates to:
  /// **'No Produce Listed Yet'**
  String get noProduceListedYet;

  /// No description provided for @activeFarmerListingsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Active farmer crop listings will appear here dynamically.'**
  String get activeFarmerListingsWillAppear;

  /// No description provided for @produceDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Produce Details'**
  String get produceDetailsTitle;

  /// No description provided for @youHaveActiveOffer.
  ///
  /// In en, this message translates to:
  /// **'You have an active offer'**
  String get youHaveActiveOffer;

  /// No description provided for @produceListingInactive.
  ///
  /// In en, this message translates to:
  /// **'Produce Listing Inactive'**
  String get produceListingInactive;

  /// No description provided for @quantityAndPricing.
  ///
  /// In en, this message translates to:
  /// **'Quantity & Pricing'**
  String get quantityAndPricing;

  /// No description provided for @availableQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Available Quantity'**
  String get availableQuantityLabel;

  /// No description provided for @expectedPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Expected Price'**
  String get expectedPriceLabel;

  /// No description provided for @farmerLocationDetails.
  ///
  /// In en, this message translates to:
  /// **'Farmer & Location Details'**
  String get farmerLocationDetails;

  /// No description provided for @cropDescription.
  ///
  /// In en, this message translates to:
  /// **'Crop Description'**
  String get cropDescription;

  /// No description provided for @editOfferLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit Offer'**
  String get editOfferLabel;

  /// No description provided for @searchCropCategoryLocation.
  ///
  /// In en, this message translates to:
  /// **'Search crop, category, or location...'**
  String get searchCropCategoryLocation;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Sort: Newest'**
  String get sortNewest;

  /// No description provided for @priceHighToLowArrow.
  ///
  /// In en, this message translates to:
  /// **'Price: High → Low'**
  String get priceHighToLowArrow;

  /// No description provided for @priceLowToHighArrow.
  ///
  /// In en, this message translates to:
  /// **'Price: Low → High'**
  String get priceLowToHighArrow;

  /// No description provided for @quantityHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Quantity: High → Low'**
  String get quantityHighToLow;

  /// No description provided for @noProduceAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'No produce available'**
  String get noProduceAvailableTitle;

  /// No description provided for @noFarmerProduceMatches.
  ///
  /// In en, this message translates to:
  /// **'No farmer produce matches your search or filter criteria.'**
  String get noFarmerProduceMatches;

  /// No description provided for @failedToLoadMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Failed to load marketplace'**
  String get failedToLoadMarketplace;

  /// No description provided for @makeAnOffer.
  ///
  /// In en, this message translates to:
  /// **'Make an Offer'**
  String get makeAnOffer;

  /// No description provided for @askingPrice.
  ///
  /// In en, this message translates to:
  /// **'Asking Price'**
  String get askingPrice;

  /// No description provided for @availableLabel.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableLabel;

  /// No description provided for @messageToFarmerOptional.
  ///
  /// In en, this message translates to:
  /// **'Message to Farmer (Optional)'**
  String get messageToFarmerOptional;

  /// No description provided for @saveUpdateOffer.
  ///
  /// In en, this message translates to:
  /// **'Save / Update Offer'**
  String get saveUpdateOffer;

  /// No description provided for @offeredPriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Offered price is required'**
  String get offeredPriceRequired;

  /// No description provided for @offeredPriceMustBeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Offered price must be greater than 0'**
  String get offeredPriceMustBeGreaterThanZero;

  /// No description provided for @enterValidPriceGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price greater than 0'**
  String get enterValidPriceGreaterThanZero;

  /// No description provided for @quantityIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Quantity is required'**
  String get quantityIsRequired;

  /// No description provided for @quantityMustBeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be greater than 0'**
  String get quantityMustBeGreaterThanZero;

  /// No description provided for @enterValidQuantityGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid quantity greater than 0'**
  String get enterValidQuantityGreaterThanZero;

  /// No description provided for @messageExceeds250.
  ///
  /// In en, this message translates to:
  /// **'Message cannot exceed 250 characters'**
  String get messageExceeds250;

  /// No description provided for @mustBeLoggedInToOffer.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to make or edit an offer'**
  String get mustBeLoggedInToOffer;

  /// No description provided for @offerSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Offer submitted successfully!'**
  String get offerSubmittedSuccessfully;

  /// No description provided for @offerUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Offer updated successfully!'**
  String get offerUpdatedSuccessfully;

  /// No description provided for @failedToSubmitOffer.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit offer'**
  String get failedToSubmitOffer;

  /// No description provided for @refreshOffers.
  ///
  /// In en, this message translates to:
  /// **'Refresh Offers'**
  String get refreshOffers;

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// No description provided for @acceptedStatus.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get acceptedStatus;

  /// No description provided for @rejectedStatus.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejectedStatus;

  /// No description provided for @cancelledStatus.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledStatus;

  /// No description provided for @noOffersFound.
  ///
  /// In en, this message translates to:
  /// **'No offers found'**
  String get noOffersFound;

  /// No description provided for @noOffersMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'You have not created any offers matching this filter.'**
  String get noOffersMatchFilter;

  /// No description provided for @failedToLoadOffers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load offers'**
  String get failedToLoadOffers;

  /// No description provided for @failedToCancelOffer.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel offer'**
  String get failedToCancelOffer;

  /// No description provided for @offerCancelledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Offer cancelled successfully'**
  String get offerCancelledSuccessfully;

  /// No description provided for @keepOffer.
  ///
  /// In en, this message translates to:
  /// **'Keep Offer'**
  String get keepOffer;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @cropProduceListing.
  ///
  /// In en, this message translates to:
  /// **'Crop Produce Listing'**
  String get cropProduceListing;

  /// No description provided for @offerAcceptedStatus.
  ///
  /// In en, this message translates to:
  /// **'Offer Accepted'**
  String get offerAcceptedStatus;

  /// No description provided for @offerRejectedStatus.
  ///
  /// In en, this message translates to:
  /// **'Offer Rejected'**
  String get offerRejectedStatus;

  /// No description provided for @noOffersYet.
  ///
  /// In en, this message translates to:
  /// **'No offers yet'**
  String get noOffersYet;

  /// No description provided for @noOffersMatchFilterFarmer.
  ///
  /// In en, this message translates to:
  /// **'No buyer offers match your current filter criteria.'**
  String get noOffersMatchFilterFarmer;

  /// No description provided for @counterOfferComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Counter offer negotiation feature coming soon'**
  String get counterOfferComingSoon;

  /// No description provided for @searchMyProduceHint.
  ///
  /// In en, this message translates to:
  /// **'Search my produce by crop name...'**
  String get searchMyProduceHint;

  /// No description provided for @failedToLoadProduce.
  ///
  /// In en, this message translates to:
  /// **'Failed to load produce'**
  String get failedToLoadProduce;

  /// No description provided for @noProduceListedYetFarmer.
  ///
  /// In en, this message translates to:
  /// **'No produce listed yet'**
  String get noProduceListedYetFarmer;

  /// No description provided for @noProduceInCategory.
  ///
  /// In en, this message translates to:
  /// **'You have not added any produce listings in this category.'**
  String get noProduceInCategory;

  /// No description provided for @locationNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Location not specified'**
  String get locationNotSpecified;

  /// No description provided for @produceDeleted.
  ///
  /// In en, this message translates to:
  /// **'Produce deleted'**
  String get produceDeleted;

  /// No description provided for @deleteProduceListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Produce Listing'**
  String get deleteProduceListingTitle;

  /// No description provided for @addProduceListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Produce Listing'**
  String get addProduceListingTitle;

  /// No description provided for @listYourCropProduce.
  ///
  /// In en, this message translates to:
  /// **'List Your Crop Produce'**
  String get listYourCropProduce;

  /// No description provided for @provideAccurateCropDetails.
  ///
  /// In en, this message translates to:
  /// **'Provide accurate crop details so interested buyers can make offers.'**
  String get provideAccurateCropDetails;

  /// No description provided for @cropProduceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Crop / Produce Name'**
  String get cropProduceNameLabel;

  /// No description provided for @pleaseEnterCropName.
  ///
  /// In en, this message translates to:
  /// **'Please enter crop produce name'**
  String get pleaseEnterCropName;

  /// No description provided for @nameMinTwoChars.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameMinTwoChars;

  /// No description provided for @produceCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Produce Category'**
  String get produceCategoryLabel;

  /// No description provided for @enterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter quantity'**
  String get enterQuantity;

  /// No description provided for @enterValidPositivePrice.
  ///
  /// In en, this message translates to:
  /// **'Enter valid positive price'**
  String get enterValidPositivePrice;

  /// No description provided for @enterValidQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter valid quantity'**
  String get enterValidQuantityLabel;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @pleaseEnterExpectedPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter expected price'**
  String get pleaseEnterExpectedPrice;

  /// No description provided for @harvestPickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Harvest / Pickup Location'**
  String get harvestPickupLocation;

  /// No description provided for @pleaseEnterLocation.
  ///
  /// In en, this message translates to:
  /// **'Please enter location'**
  String get pleaseEnterLocation;

  /// No description provided for @additionalQualityDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional Quality Details (Optional)'**
  String get additionalQualityDetailsOptional;

  /// No description provided for @publishListing.
  ///
  /// In en, this message translates to:
  /// **'Publish Listing'**
  String get publishListing;

  /// No description provided for @produceListedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Produce listed successfully!'**
  String get produceListedSuccessfully;

  /// No description provided for @authenticationRequired.
  ///
  /// In en, this message translates to:
  /// **'Authentication required'**
  String get authenticationRequired;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection Error'**
  String get connectionError;

  /// No description provided for @retryConnection.
  ///
  /// In en, this message translates to:
  /// **'Retry Connection'**
  String get retryConnection;

  /// No description provided for @hideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide Details'**
  String get hideDetails;

  /// No description provided for @showDetails.
  ///
  /// In en, this message translates to:
  /// **'Show Details'**
  String get showDetails;

  /// No description provided for @serviceInitializationFailed.
  ///
  /// In en, this message translates to:
  /// **'Service initialization failed.'**
  String get serviceInitializationFailed;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Direct Farm-to-Buyer Marketplace & Real-time Prices'**
  String get splashTagline;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// No description provided for @completeYourProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeYourProfileTitle;

  /// No description provided for @completeYourFarmerProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Farmer Profile'**
  String get completeYourFarmerProfileTitle;

  /// No description provided for @completeYourBuyerProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Buyer Profile'**
  String get completeYourBuyerProfileTitle;

  /// No description provided for @tellUsAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Tell us a little about yourself to personalize your KisanSetu experience.'**
  String get tellUsAboutYourself;

  /// No description provided for @sellProduceDiscoverPrices.
  ///
  /// In en, this message translates to:
  /// **'Sell produce and discover market prices.'**
  String get sellProduceDiscoverPrices;

  /// No description provided for @discoverProduceConnectFarmers.
  ///
  /// In en, this message translates to:
  /// **'Discover produce and connect with farmers.'**
  String get discoverProduceConnectFarmers;

  /// No description provided for @profileDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Details'**
  String get profileDetailsTitle;

  /// No description provided for @googleAccount.
  ///
  /// In en, this message translates to:
  /// **'Google Account'**
  String get googleAccount;

  /// No description provided for @googleUser.
  ///
  /// In en, this message translates to:
  /// **'Google User'**
  String get googleUser;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @continueArrow.
  ///
  /// In en, this message translates to:
  /// **'Continue →'**
  String get continueArrow;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// No description provided for @phoneNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneNumberRequired;

  /// No description provided for @enterValid10DigitMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter valid 10-digit mobile number'**
  String get enterValid10DigitMobile;

  /// No description provided for @stateRequired.
  ///
  /// In en, this message translates to:
  /// **'State is required'**
  String get stateRequired;

  /// No description provided for @districtRequired.
  ///
  /// In en, this message translates to:
  /// **'District is required'**
  String get districtRequired;

  /// No description provided for @districtCityRequired.
  ///
  /// In en, this message translates to:
  /// **'District / City is required'**
  String get districtCityRequired;

  /// No description provided for @villageRequired.
  ///
  /// In en, this message translates to:
  /// **'Village is required'**
  String get villageRequired;

  /// No description provided for @enterYourVillageName.
  ///
  /// In en, this message translates to:
  /// **'Enter your village name'**
  String get enterYourVillageName;

  /// No description provided for @primaryCropRequired.
  ///
  /// In en, this message translates to:
  /// **'Primary crop is required'**
  String get primaryCropRequired;

  /// No description provided for @companyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Company name is required'**
  String get companyNameRequired;

  /// No description provided for @failedToSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile'**
  String get failedToSaveProfile;

  /// No description provided for @preferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred Language'**
  String get preferredLanguage;

  /// No description provided for @primaryMandiDistrictCity.
  ///
  /// In en, this message translates to:
  /// **'Primary Mandi District / City'**
  String get primaryMandiDistrictCity;

  /// No description provided for @gstNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'GST Number (Optional)'**
  String get gstNumberOptional;

  /// No description provided for @contactNameFullName.
  ///
  /// In en, this message translates to:
  /// **'Contact Name / Full Name'**
  String get contactNameFullName;

  /// No description provided for @contactNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Contact name is required'**
  String get contactNameRequired;

  /// No description provided for @wholesalerTrader.
  ///
  /// In en, this message translates to:
  /// **'Wholesaler / Trader'**
  String get wholesalerTrader;

  /// No description provided for @retailer.
  ///
  /// In en, this message translates to:
  /// **'Retailer'**
  String get retailer;

  /// No description provided for @processorMillOwner.
  ///
  /// In en, this message translates to:
  /// **'Processor / Mill Owner'**
  String get processorMillOwner;

  /// No description provided for @exporter.
  ///
  /// In en, this message translates to:
  /// **'Exporter'**
  String get exporter;

  /// No description provided for @farmerProfileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Farmer Profile Setup'**
  String get farmerProfileSetupTitle;

  /// No description provided for @buyerProfileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Buyer Profile Setup'**
  String get buyerProfileSetupTitle;

  /// No description provided for @completeFarmContactInfo.
  ///
  /// In en, this message translates to:
  /// **'Complete your farm & contact information'**
  String get completeFarmContactInfo;

  /// No description provided for @provideBusinessContactDetails.
  ///
  /// In en, this message translates to:
  /// **'Provide business & contact details to connect with farmers'**
  String get provideBusinessContactDetails;

  /// No description provided for @pleaseEnterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterYourEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterYourPassword;

  /// No description provided for @loginFailedCheckCredentials.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your credentials.'**
  String get loginFailedCheckCredentials;

  /// No description provided for @googleAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Google authentication failed.'**
  String get googleAuthFailed;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @pleaseEnterAPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get pleaseEnterAPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters long'**
  String get passwordMinLength;

  /// No description provided for @pleaseConfirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmYourPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @pleaseEnterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get pleaseEnterYourFullName;

  /// No description provided for @pleaseEnterYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterYourPhoneNumber;

  /// No description provided for @enterValid10DigitIndianMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter valid 10-digit Indian mobile number'**
  String get enterValid10DigitIndianMobile;

  /// No description provided for @pleaseSelectAccountType.
  ///
  /// In en, this message translates to:
  /// **'Please select an account type'**
  String get pleaseSelectAccountType;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// No description provided for @selectAccountType.
  ///
  /// In en, this message translates to:
  /// **'Select Account Type'**
  String get selectAccountType;

  /// No description provided for @failedToUpdateRole.
  ///
  /// In en, this message translates to:
  /// **'Failed to update role'**
  String get failedToUpdateRole;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @enterAValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterAValidEmail;

  /// No description provided for @enterRegisteredEmailForReset.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered email address to receive a password reset link.'**
  String get enterRegisteredEmailForReset;

  /// No description provided for @failedToSendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset link'**
  String get failedToSendResetLink;

  /// No description provided for @passwordResetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to your email!'**
  String get passwordResetLinkSent;

  /// No description provided for @quintalsLabel.
  ///
  /// In en, this message translates to:
  /// **'Quintals'**
  String get quintalsLabel;

  /// No description provided for @namaste.
  ///
  /// In en, this message translates to:
  /// **'Namaste'**
  String get namaste;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @offeredPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Offered Price'**
  String get offeredPriceLabel;

  /// No description provided for @quantityCannotExceedAvailable.
  ///
  /// In en, this message translates to:
  /// **'Quantity cannot exceed available produce quantity'**
  String get quantityCannotExceedAvailable;

  /// No description provided for @exceedsAvailableQuantity.
  ///
  /// In en, this message translates to:
  /// **'Exceeds available quantity'**
  String get exceedsAvailableQuantity;

  /// No description provided for @cancelOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Offer'**
  String get cancelOfferTitle;

  /// No description provided for @cancelOfferConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this pending offer of'**
  String get cancelOfferConfirmMessage;

  /// No description provided for @messageLabelColon.
  ///
  /// In en, this message translates to:
  /// **'Message:'**
  String get messageLabelColon;

  /// No description provided for @listedLabel.
  ///
  /// In en, this message translates to:
  /// **'Listed'**
  String get listedLabel;

  /// No description provided for @deleteProduceConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete'**
  String get deleteProduceConfirmMessage;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// No description provided for @newVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'A new version of KisanSetu is available.'**
  String get newVersionAvailable;

  /// No description provided for @currentVersion.
  ///
  /// In en, this message translates to:
  /// **'Current Version'**
  String get currentVersion;

  /// No description provided for @latestVersion.
  ///
  /// In en, this message translates to:
  /// **'Latest Version'**
  String get latestVersion;

  /// No description provided for @whatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s New'**
  String get whatsNew;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @downloadingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Downloading update...'**
  String get downloadingUpdate;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download update'**
  String get downloadFailed;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequired;

  /// No description provided for @installPermissionNotice.
  ///
  /// In en, this message translates to:
  /// **'To install updates, please allow KisanSetu to install unknown apps in Android Settings.'**
  String get installPermissionNotice;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @openingInstaller.
  ///
  /// In en, this message translates to:
  /// **'Opening system package installer...'**
  String get openingInstaller;

  /// No description provided for @viewOnMap.
  ///
  /// In en, this message translates to:
  /// **'View on Map'**
  String get viewOnMap;

  /// No description provided for @openChat.
  ///
  /// In en, this message translates to:
  /// **'Chat with farmer'**
  String get openChat;

  /// No description provided for @mapLatitudeOptional.
  ///
  /// In en, this message translates to:
  /// **'Map Latitude (optional)'**
  String get mapLatitudeOptional;

  /// No description provided for @mapLongitudeOptional.
  ///
  /// In en, this message translates to:
  /// **'Map Longitude (optional)'**
  String get mapLongitudeOptional;
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
