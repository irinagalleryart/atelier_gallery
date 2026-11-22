import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_mk.dart';

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
    Locale('en'),
    Locale('mk'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Atelier Gallery'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @aboutArtist.
  ///
  /// In en, this message translates to:
  /// **'About the Artist'**
  String get aboutArtist;

  /// No description provided for @guestbook.
  ///
  /// In en, this message translates to:
  /// **'Guestbook'**
  String get guestbook;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @languageMacedonian.
  ///
  /// In en, this message translates to:
  /// **'Macedonian'**
  String get languageMacedonian;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @technique.
  ///
  /// In en, this message translates to:
  /// **'Technique'**
  String get technique;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @storyBehindArtwork.
  ///
  /// In en, this message translates to:
  /// **'Story Behind the Artwork'**
  String get storyBehindArtwork;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Biography'**
  String get bio;

  /// No description provided for @artSchool.
  ///
  /// In en, this message translates to:
  /// **'Art Education'**
  String get artSchool;

  /// No description provided for @favoriteTechniques.
  ///
  /// In en, this message translates to:
  /// **'Favorite Techniques'**
  String get favoriteTechniques;

  /// No description provided for @featuredArtworks.
  ///
  /// In en, this message translates to:
  /// **'Featured Artworks'**
  String get featuredArtworks;

  /// No description provided for @latestCreations.
  ///
  /// In en, this message translates to:
  /// **'Latest Creations'**
  String get latestCreations;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @exploreGallery.
  ///
  /// In en, this message translates to:
  /// **'Explore Gallery'**
  String get exploreGallery;

  /// No description provided for @dimensions.
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get dimensions;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @allTechniques.
  ///
  /// In en, this message translates to:
  /// **'All Techniques'**
  String get allTechniques;

  /// No description provided for @allYears.
  ///
  /// In en, this message translates to:
  /// **'All Years'**
  String get allYears;

  /// No description provided for @myDreamWorld.
  ///
  /// In en, this message translates to:
  /// **'My Dream World'**
  String get myDreamWorld;

  /// No description provided for @leaveAMessage.
  ///
  /// In en, this message translates to:
  /// **'Leave a Message'**
  String get leaveAMessage;

  /// No description provided for @authorName.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get authorName;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @messageSubmittedForApproval.
  ///
  /// In en, this message translates to:
  /// **'Your message has been submitted for approval.'**
  String get messageSubmittedForApproval;

  /// No description provided for @noArtworksFound.
  ///
  /// In en, this message translates to:
  /// **'No artworks found.'**
  String get noArtworksFound;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @pendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get pendingApproval;

  /// No description provided for @supabaseConnected.
  ///
  /// In en, this message translates to:
  /// **'Supabase Connected'**
  String get supabaseConnected;

  /// No description provided for @supabaseNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Supabase Not Configured'**
  String get supabaseNotConnected;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @adminLogin.
  ///
  /// In en, this message translates to:
  /// **'Admin Login'**
  String get adminLogin;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Management Panel'**
  String get adminPanel;

  /// No description provided for @webOnlyAdminNotice.
  ///
  /// In en, this message translates to:
  /// **'The admin panel is accessible only via Web.'**
  String get webOnlyAdminNotice;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get invalidCredentials;

  /// No description provided for @manageArtworks.
  ///
  /// In en, this message translates to:
  /// **'Manage Artworks'**
  String get manageArtworks;

  /// No description provided for @manageArtistProfile.
  ///
  /// In en, this message translates to:
  /// **'Artist Profile & Site Texts'**
  String get manageArtistProfile;

  /// No description provided for @manageGuestbook.
  ///
  /// In en, this message translates to:
  /// **'Guestbook Moderation'**
  String get manageGuestbook;

  /// No description provided for @addArtwork.
  ///
  /// In en, this message translates to:
  /// **'Add Artwork'**
  String get addArtwork;

  /// No description provided for @editArtwork.
  ///
  /// In en, this message translates to:
  /// **'Edit Artwork'**
  String get editArtwork;

  /// No description provided for @deleteArtwork.
  ///
  /// In en, this message translates to:
  /// **'Delete Artwork'**
  String get deleteArtwork;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description / Story'**
  String get description;

  /// No description provided for @isFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured Artwork'**
  String get isFeatured;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// No description provided for @changeImage.
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get changeImage;

  /// No description provided for @imageUrl.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get imageUrl;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirmDeleteArtwork.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this artwork?'**
  String get confirmDeleteArtwork;

  /// No description provided for @confirmDeleteGuestbook.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this guestbook entry?'**
  String get confirmDeleteGuestbook;

  /// No description provided for @artistName.
  ///
  /// In en, this message translates to:
  /// **'Artist Name'**
  String get artistName;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Artist profile updated successfully.'**
  String get profileUpdated;

  /// No description provided for @artworkSaved.
  ///
  /// In en, this message translates to:
  /// **'Artwork saved successfully.'**
  String get artworkSaved;

  /// No description provided for @artworkDeleted.
  ///
  /// In en, this message translates to:
  /// **'Artwork deleted successfully.'**
  String get artworkDeleted;

  /// No description provided for @guestbookDeleted.
  ///
  /// In en, this message translates to:
  /// **'Guestbook entry deleted.'**
  String get guestbookDeleted;

  /// No description provided for @guestbookStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Guestbook entry status updated.'**
  String get guestbookStatusUpdated;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @unapprove.
  ///
  /// In en, this message translates to:
  /// **'Unapprove'**
  String get unapprove;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @noEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries found.'**
  String get noEntries;

  /// No description provided for @approvedMessages.
  ///
  /// In en, this message translates to:
  /// **'Approved Guestbook Messages'**
  String get approvedMessages;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Artwork link copied to clipboard!'**
  String get linkCopied;

  /// No description provided for @searchArtworks.
  ///
  /// In en, this message translates to:
  /// **'Search artworks...'**
  String get searchArtworks;

  /// No description provided for @previousArtwork.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousArtwork;

  /// No description provided for @nextArtwork.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextArtwork;

  /// No description provided for @shareArtworkHeader.
  ///
  /// In en, this message translates to:
  /// **'Artwork from Atelier Gallery'**
  String get shareArtworkHeader;

  /// No description provided for @titleMk.
  ///
  /// In en, this message translates to:
  /// **'Title (Macedonian)'**
  String get titleMk;

  /// No description provided for @titleEn.
  ///
  /// In en, this message translates to:
  /// **'Title (English)'**
  String get titleEn;

  /// No description provided for @descriptionMk.
  ///
  /// In en, this message translates to:
  /// **'Description (Macedonian)'**
  String get descriptionMk;

  /// No description provided for @descriptionEn.
  ///
  /// In en, this message translates to:
  /// **'Description (English)'**
  String get descriptionEn;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @requiredEnOrMk.
  ///
  /// In en, this message translates to:
  /// **'Required (EN or MK)'**
  String get requiredEnOrMk;

  /// No description provided for @imageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed: {error}. You can manually enter an Image URL.'**
  String imageUploadFailed(Object error);

  /// No description provided for @errorSavingArtwork.
  ///
  /// In en, this message translates to:
  /// **'Error saving artwork: {error}'**
  String errorSavingArtwork(Object error);

  /// No description provided for @errorDeletingArtwork.
  ///
  /// In en, this message translates to:
  /// **'Error deleting artwork: {error}'**
  String errorDeletingArtwork(Object error);

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorGeneric(Object error);

  /// No description provided for @errorSavingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error saving profile: {error}'**
  String errorSavingProfile(Object error);

  /// No description provided for @errorDeletingEntry.
  ///
  /// In en, this message translates to:
  /// **'Error deleting entry: {error}'**
  String errorDeletingEntry(Object error);

  /// No description provided for @artWorldOfArtist.
  ///
  /// In en, this message translates to:
  /// **'The Art World of {artistName}'**
  String artWorldOfArtist(Object artistName);

  /// No description provided for @guestbookNameLengthError.
  ///
  /// In en, this message translates to:
  /// **'Name must be between 2 and 50 characters.'**
  String get guestbookNameLengthError;

  /// No description provided for @guestbookMessageLengthError.
  ///
  /// In en, this message translates to:
  /// **'Message must be between 5 and 500 characters.'**
  String get guestbookMessageLengthError;

  /// No description provided for @guestbookUrlNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'URLs and web links are not allowed in guestbook messages.'**
  String get guestbookUrlNotAllowed;

  /// No description provided for @guestbookCooldownActive.
  ///
  /// In en, this message translates to:
  /// **'Please wait {seconds} seconds before submitting another message.'**
  String guestbookCooldownActive(Object seconds);

  /// No description provided for @noApprovedGuestbookEntries.
  ///
  /// In en, this message translates to:
  /// **'No approved guestbook messages yet. Be the first to leave one!'**
  String get noApprovedGuestbookEntries;

  /// No description provided for @guestbookRateLimitError.
  ///
  /// In en, this message translates to:
  /// **'Too many submissions. Please try again later.'**
  String get guestbookRateLimitError;

  /// No description provided for @captchaVerification.
  ///
  /// In en, this message translates to:
  /// **'Math Verification'**
  String get captchaVerification;

  /// No description provided for @captchaQuestion.
  ///
  /// In en, this message translates to:
  /// **'What is {a} + {b}?'**
  String captchaQuestion(Object a, Object b);

  /// No description provided for @captchaAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Enter answer'**
  String get captchaAnswerHint;

  /// No description provided for @captchaError.
  ///
  /// In en, this message translates to:
  /// **'Incorrect math answer. Please try again.'**
  String get captchaError;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @errorUpdatingEntry.
  ///
  /// In en, this message translates to:
  /// **'Error updating entry: {error}'**
  String errorUpdatingEntry(Object error);

  /// No description provided for @viewOnWall.
  ///
  /// In en, this message translates to:
  /// **'View on Wall'**
  String get viewOnWall;

  /// No description provided for @artworkView.
  ///
  /// In en, this message translates to:
  /// **'Artwork Details'**
  String get artworkView;

  /// No description provided for @frameStyle.
  ///
  /// In en, this message translates to:
  /// **'Frame Style'**
  String get frameStyle;

  /// No description provided for @frameNone.
  ///
  /// In en, this message translates to:
  /// **'Canvas Edge (No Frame)'**
  String get frameNone;

  /// No description provided for @frameOak.
  ///
  /// In en, this message translates to:
  /// **'Natural Oak'**
  String get frameOak;

  /// No description provided for @frameWhite.
  ///
  /// In en, this message translates to:
  /// **'Classic White'**
  String get frameWhite;

  /// No description provided for @frameGold.
  ///
  /// In en, this message translates to:
  /// **'Warm Gold'**
  String get frameGold;

  /// No description provided for @wallColor.
  ///
  /// In en, this message translates to:
  /// **'Wall Color'**
  String get wallColor;

  /// No description provided for @wallGalleryOffWhite.
  ///
  /// In en, this message translates to:
  /// **'Gallery White'**
  String get wallGalleryOffWhite;

  /// No description provided for @wallSoftSage.
  ///
  /// In en, this message translates to:
  /// **'Soft Sage'**
  String get wallSoftSage;

  /// No description provided for @wallWarmSand.
  ///
  /// In en, this message translates to:
  /// **'Warm Sand'**
  String get wallWarmSand;

  /// No description provided for @wallPastelSky.
  ///
  /// In en, this message translates to:
  /// **'Pastel Sky'**
  String get wallPastelSky;

  /// No description provided for @passePartout.
  ///
  /// In en, this message translates to:
  /// **'Inner white mat border (passe-partout)'**
  String get passePartout;

  /// No description provided for @scaledToScaleHint.
  ///
  /// In en, this message translates to:
  /// **'Scaled proportionally ({dimensions})'**
  String scaledToScaleHint(Object dimensions);

  /// No description provided for @virtualExhibition.
  ///
  /// In en, this message translates to:
  /// **'360° Virtual Exhibition'**
  String get virtualExhibition;

  /// No description provided for @virtualExhibitionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Step inside our bright virtual gallery hall and explore artworks in 360°'**
  String get virtualExhibitionSubtitle;

  /// No description provided for @enterVirtualExhibition.
  ///
  /// In en, this message translates to:
  /// **'Enter 360° Exhibition'**
  String get enterVirtualExhibition;

  /// No description provided for @lookLeft.
  ///
  /// In en, this message translates to:
  /// **'Look Left'**
  String get lookLeft;

  /// No description provided for @lookRight.
  ///
  /// In en, this message translates to:
  /// **'Look Right'**
  String get lookRight;

  /// No description provided for @resetView.
  ///
  /// In en, this message translates to:
  /// **'Center View'**
  String get resetView;

  /// No description provided for @virtualHallInstructions.
  ///
  /// In en, this message translates to:
  /// **'Drag left or right to explore the 360° hall. Tap any artwork to inspect.'**
  String get virtualHallInstructions;

  /// No description provided for @wallLeft.
  ///
  /// In en, this message translates to:
  /// **'West Wall'**
  String get wallLeft;

  /// No description provided for @wallCenter.
  ///
  /// In en, this message translates to:
  /// **'Main Hall'**
  String get wallCenter;

  /// No description provided for @wallRight.
  ///
  /// In en, this message translates to:
  /// **'East Wall'**
  String get wallRight;

  /// No description provided for @wallBack.
  ///
  /// In en, this message translates to:
  /// **'South Wall'**
  String get wallBack;

  /// No description provided for @tapToInspect.
  ///
  /// In en, this message translates to:
  /// **'Tap to inspect artwork'**
  String get tapToInspect;

  /// No description provided for @stepCloser.
  ///
  /// In en, this message translates to:
  /// **'Step Closer'**
  String get stepCloser;

  /// No description provided for @stepBack.
  ///
  /// In en, this message translates to:
  /// **'Step Back'**
  String get stepBack;

  /// No description provided for @roomThemeBright.
  ///
  /// In en, this message translates to:
  /// **'Bright Modern Hall'**
  String get roomThemeBright;

  /// No description provided for @roomThemeAtelier.
  ///
  /// In en, this message translates to:
  /// **'Watercolor Atelier'**
  String get roomThemeAtelier;

  /// No description provided for @roomThemeEvening.
  ///
  /// In en, this message translates to:
  /// **'Soft Evening Gallery'**
  String get roomThemeEvening;

  /// No description provided for @galleryAtmosphere.
  ///
  /// In en, this message translates to:
  /// **'Room Atmosphere'**
  String get galleryAtmosphere;

  /// No description provided for @galleryLights.
  ///
  /// In en, this message translates to:
  /// **'Gallery Lights'**
  String get galleryLights;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFromFavorites;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @onlyFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites Only'**
  String get onlyFavorites;

  /// No description provided for @reactionLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get reactionLike;

  /// No description provided for @reactionLove.
  ///
  /// In en, this message translates to:
  /// **'Lovely'**
  String get reactionLove;

  /// No description provided for @reactionMagical.
  ///
  /// In en, this message translates to:
  /// **'Magical'**
  String get reactionMagical;

  /// No description provided for @reactionArtistic.
  ///
  /// In en, this message translates to:
  /// **'Artistic'**
  String get reactionArtistic;

  /// No description provided for @reactionEmotional.
  ///
  /// In en, this message translates to:
  /// **'Emotional'**
  String get reactionEmotional;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @leaveComment.
  ///
  /// In en, this message translates to:
  /// **'Leave a Comment'**
  String get leaveComment;

  /// No description provided for @commentText.
  ///
  /// In en, this message translates to:
  /// **'Your Comment'**
  String get commentText;

  /// No description provided for @commentSubmittedForApproval.
  ///
  /// In en, this message translates to:
  /// **'Your comment has been submitted and is awaiting admin approval.'**
  String get commentSubmittedForApproval;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Be the first to share your thoughts!'**
  String get noCommentsYet;

  /// No description provided for @manageArtworkComments.
  ///
  /// In en, this message translates to:
  /// **'Artwork Comments'**
  String get manageArtworkComments;

  /// No description provided for @confirmDeleteComment.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this comment?'**
  String get confirmDeleteComment;

  /// No description provided for @commentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Comment deleted.'**
  String get commentDeleted;

  /// No description provided for @commentStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Comment status updated.'**
  String get commentStatusUpdated;

  /// No description provided for @favoritesWithCount.
  ///
  /// In en, this message translates to:
  /// **'Favorites ({count})'**
  String favoritesWithCount(Object count);

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No favorite artworks yet. Tap the heart icon on any artwork to add it to your favorites.'**
  String get noFavoritesYet;

  /// No description provided for @clearFavorites.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearFavorites;

  /// No description provided for @confirmClearFavorites.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all artworks from your favorites?'**
  String get confirmClearFavorites;

  /// No description provided for @gridView.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get gridView;

  /// No description provided for @timelineView.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timelineView;

  /// No description provided for @artworksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} artworks'**
  String artworksCount(Object count);

  /// No description provided for @creativeJourney.
  ///
  /// In en, this message translates to:
  /// **'Creative Journey'**
  String get creativeJourney;

  /// No description provided for @artPuzzle.
  ///
  /// In en, this message translates to:
  /// **'Art Puzzle'**
  String get artPuzzle;

  /// No description provided for @artPuzzleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assemble the artwork'**
  String get artPuzzleSubtitle;

  /// No description provided for @playPuzzle.
  ///
  /// In en, this message translates to:
  /// **'Play Puzzle'**
  String get playPuzzle;

  /// No description provided for @chooseArtwork.
  ///
  /// In en, this message translates to:
  /// **'Choose Artwork'**
  String get chooseArtwork;

  /// No description provided for @gridSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Grid Size'**
  String get gridSizeLabel;

  /// No description provided for @easy3x3.
  ///
  /// In en, this message translates to:
  /// **'3×3 (Easy)'**
  String get easy3x3;

  /// No description provided for @medium4x4.
  ///
  /// In en, this message translates to:
  /// **'4×4 (Medium)'**
  String get medium4x4;

  /// No description provided for @movesLabel.
  ///
  /// In en, this message translates to:
  /// **'Moves'**
  String get movesLabel;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @previewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewLabel;

  /// No description provided for @peekLabel.
  ///
  /// In en, this message translates to:
  /// **'Peek Original'**
  String get peekLabel;

  /// No description provided for @shuffleLabel.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffleLabel;

  /// No description provided for @restartLabel.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restartLabel;

  /// No description provided for @puzzleCompleted.
  ///
  /// In en, this message translates to:
  /// **'Masterpiece Completed!'**
  String get puzzleCompleted;

  /// No description provided for @puzzleCompletedDesc.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You assembled the artwork in {moves} moves and {time}.'**
  String puzzleCompletedDesc(Object moves, Object time);

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get playAgain;

  /// No description provided for @selectAnotherArtwork.
  ///
  /// In en, this message translates to:
  /// **'Pick Another Artwork'**
  String get selectAnotherArtwork;

  /// No description provided for @bestScore.
  ///
  /// In en, this message translates to:
  /// **'Best: {time} ({moves} moves)'**
  String bestScore(Object moves, Object time);

  /// No description provided for @noBestScore.
  ///
  /// In en, this message translates to:
  /// **'Best: --'**
  String get noBestScore;

  /// No description provided for @newBestScore.
  ///
  /// In en, this message translates to:
  /// **'New Record!'**
  String get newBestScore;

  /// No description provided for @hard5x5.
  ///
  /// In en, this message translates to:
  /// **'5×5 (Hard)'**
  String get hard5x5;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @enterNickname.
  ///
  /// In en, this message translates to:
  /// **'Enter Nickname'**
  String get enterNickname;

  /// No description provided for @nicknameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. ArtExplorer99'**
  String get nicknameHint;

  /// No description provided for @nicknameLengthError.
  ///
  /// In en, this message translates to:
  /// **'Nickname must be between 2 and 15 characters.'**
  String get nicknameLengthError;

  /// No description provided for @nicknameCharError.
  ///
  /// In en, this message translates to:
  /// **'Only letters, numbers, spaces, _ and - allowed.'**
  String get nicknameCharError;

  /// No description provided for @nicknameNotice.
  ///
  /// In en, this message translates to:
  /// **'Pick a fun nickname! Please do not use real personal info.'**
  String get nicknameNotice;

  /// No description provided for @changeNickname.
  ///
  /// In en, this message translates to:
  /// **'Change Nickname'**
  String get changeNickname;

  /// No description provided for @playingAs.
  ///
  /// In en, this message translates to:
  /// **'Playing as: {nickname}'**
  String playingAs(Object nickname);

  /// No description provided for @setNicknameToPlay.
  ///
  /// In en, this message translates to:
  /// **'Set a nickname to submit scores & join the leaderboard!'**
  String get setNicknameToPlay;

  /// No description provided for @leaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Puzzle Leaderboard'**
  String get leaderboardTitle;

  /// No description provided for @tabTotalPoints.
  ///
  /// In en, this message translates to:
  /// **'Total Points'**
  String get tabTotalPoints;

  /// No description provided for @tabByLevel.
  ///
  /// In en, this message translates to:
  /// **'Best by Level'**
  String get tabByLevel;

  /// No description provided for @rankLabel.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get rankLabel;

  /// No description provided for @playerLabel.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get playerLabel;

  /// No description provided for @pointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get pointsLabel;

  /// No description provided for @ptsEarned.
  ///
  /// In en, this message translates to:
  /// **'+{points} pts'**
  String ptsEarned(Object points);

  /// No description provided for @totalPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Points: {points}'**
  String totalPointsLabel(Object points);

  /// No description provided for @puzzlesCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} solved'**
  String puzzlesCompletedCount(Object count);

  /// No description provided for @noLeaderboardEntries.
  ///
  /// In en, this message translates to:
  /// **'No scores recorded yet. Be the first to solve a puzzle!'**
  String get noLeaderboardEntries;

  /// No description provided for @scoreSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Score saved to leaderboard!'**
  String get scoreSubmitted;

  /// No description provided for @savedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved locally (Offline)'**
  String get savedOffline;

  /// No description provided for @submittingScore.
  ///
  /// In en, this message translates to:
  /// **'Submitting score...'**
  String get submittingScore;

  /// No description provided for @viewLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get viewLeaderboard;

  /// No description provided for @backToPuzzle.
  ///
  /// In en, this message translates to:
  /// **'Back to Puzzle'**
  String get backToPuzzle;

  /// No description provided for @level3x3.
  ///
  /// In en, this message translates to:
  /// **'3×3 Easy'**
  String get level3x3;

  /// No description provided for @level4x4.
  ///
  /// In en, this message translates to:
  /// **'4×4 Medium'**
  String get level4x4;

  /// No description provided for @level5x5.
  ///
  /// In en, this message translates to:
  /// **'5×5 Hard'**
  String get level5x5;

  /// No description provided for @totalPoints.
  ///
  /// In en, this message translates to:
  /// **'Total Points'**
  String get totalPoints;

  /// No description provided for @puzzlesSolved.
  ///
  /// In en, this message translates to:
  /// **'Puzzles Solved'**
  String get puzzlesSolved;

  /// No description provided for @bestTime.
  ///
  /// In en, this message translates to:
  /// **'Best Time'**
  String get bestTime;

  /// No description provided for @bestMoves.
  ///
  /// In en, this message translates to:
  /// **'Best Moves'**
  String get bestMoves;

  /// No description provided for @saveNickname.
  ///
  /// In en, this message translates to:
  /// **'Save Nickname'**
  String get saveNickname;

  /// No description provided for @managePuzzleScores.
  ///
  /// In en, this message translates to:
  /// **'Puzzle Nicknames'**
  String get managePuzzleScores;

  /// No description provided for @deleteScoresForNickname.
  ///
  /// In en, this message translates to:
  /// **'Delete All Scores for Nickname'**
  String get deleteScoresForNickname;

  /// No description provided for @confirmDeleteNicknameScores.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all puzzle scores for nickname \"{nickname}\"?'**
  String confirmDeleteNicknameScores(Object nickname);

  /// No description provided for @confirmDeletePuzzleScore.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this puzzle score entry?'**
  String get confirmDeletePuzzleScore;

  /// No description provided for @scoreEntryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Puzzle score entry deleted.'**
  String get scoreEntryDeleted;

  /// No description provided for @nicknameScoresDeleted.
  ///
  /// In en, this message translates to:
  /// **'All scores for nickname deleted.'**
  String get nicknameScoresDeleted;

  /// No description provided for @errorDeletingPuzzleScore.
  ///
  /// In en, this message translates to:
  /// **'Error deleting puzzle score: {error}'**
  String errorDeletingPuzzleScore(Object error);

  /// No description provided for @searchNicknames.
  ///
  /// In en, this message translates to:
  /// **'Search nicknames...'**
  String get searchNicknames;

  /// No description provided for @allLevels.
  ///
  /// In en, this message translates to:
  /// **'All Levels'**
  String get allLevels;

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry'**
  String get deleteEntry;

  /// No description provided for @deleteAllNicknameScores.
  ///
  /// In en, this message translates to:
  /// **'Delete All Scores'**
  String get deleteAllNicknameScores;

  /// No description provided for @scoresCount.
  ///
  /// In en, this message translates to:
  /// **'{count} scores'**
  String scoresCount(Object count);

  /// No description provided for @bioMk.
  ///
  /// In en, this message translates to:
  /// **'Biography (MK)'**
  String get bioMk;

  /// No description provided for @bioEn.
  ///
  /// In en, this message translates to:
  /// **'Biography (EN)'**
  String get bioEn;

  /// No description provided for @artSchoolMk.
  ///
  /// In en, this message translates to:
  /// **'Art Education (MK)'**
  String get artSchoolMk;

  /// No description provided for @artSchoolEn.
  ///
  /// In en, this message translates to:
  /// **'Art Education (EN)'**
  String get artSchoolEn;

  /// No description provided for @favoriteTechniquesMk.
  ///
  /// In en, this message translates to:
  /// **'Favorite Techniques (MK)'**
  String get favoriteTechniquesMk;

  /// No description provided for @favoriteTechniquesEn.
  ///
  /// In en, this message translates to:
  /// **'Favorite Techniques (EN)'**
  String get favoriteTechniquesEn;

  /// No description provided for @artistNameMk.
  ///
  /// In en, this message translates to:
  /// **'Artist Name (MK)'**
  String get artistNameMk;

  /// No description provided for @artistNameEn.
  ///
  /// In en, this message translates to:
  /// **'Artist Name (EN)'**
  String get artistNameEn;
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
      <String>['en', 'mk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'mk':
      return AppLocalizationsMk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
