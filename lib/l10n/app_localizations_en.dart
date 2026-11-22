// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Atelier Gallery';

  @override
  String get home => 'Home';

  @override
  String get gallery => 'Gallery';

  @override
  String get aboutArtist => 'About the Artist';

  @override
  String get guestbook => 'Guestbook';

  @override
  String get admin => 'Admin';

  @override
  String get languageMacedonian => 'Macedonian';

  @override
  String get languageEnglish => 'English';

  @override
  String get technique => 'Technique';

  @override
  String get year => 'Year';

  @override
  String get storyBehindArtwork => 'Story Behind the Artwork';

  @override
  String get bio => 'Biography';

  @override
  String get artSchool => 'Art Education';

  @override
  String get favoriteTechniques => 'Favorite Techniques';

  @override
  String get featuredArtworks => 'Featured Artworks';

  @override
  String get latestCreations => 'Latest Creations';

  @override
  String get viewDetails => 'View Details';

  @override
  String get exploreGallery => 'Explore Gallery';

  @override
  String get dimensions => 'Dimensions';

  @override
  String get close => 'Close';

  @override
  String get allTechniques => 'All Techniques';

  @override
  String get allYears => 'All Years';

  @override
  String get myDreamWorld => 'My Dream World';

  @override
  String get leaveAMessage => 'Leave a Message';

  @override
  String get authorName => 'Your Name';

  @override
  String get message => 'Message';

  @override
  String get submit => 'Submit';

  @override
  String get messageSubmittedForApproval =>
      'Your message has been submitted for approval.';

  @override
  String get noArtworksFound => 'No artworks found.';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get all => 'All';

  @override
  String get approved => 'Approved';

  @override
  String get pendingApproval => 'Pending Approval';

  @override
  String get supabaseConnected => 'Supabase Connected';

  @override
  String get supabaseNotConnected => 'Supabase Not Configured';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get adminLogin => 'Admin Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign In';

  @override
  String get signOut => 'Sign Out';

  @override
  String get adminPanel => 'Admin Management Panel';

  @override
  String get webOnlyAdminNotice =>
      'The admin panel is accessible only via Web.';

  @override
  String get invalidCredentials => 'Invalid email or password.';

  @override
  String get manageArtworks => 'Manage Artworks';

  @override
  String get manageArtistProfile => 'Artist Profile & Site Texts';

  @override
  String get manageGuestbook => 'Guestbook Moderation';

  @override
  String get addArtwork => 'Add Artwork';

  @override
  String get editArtwork => 'Edit Artwork';

  @override
  String get deleteArtwork => 'Delete Artwork';

  @override
  String get title => 'Title';

  @override
  String get description => 'Description / Story';

  @override
  String get isFeatured => 'Featured Artwork';

  @override
  String get uploadImage => 'Upload Image';

  @override
  String get changeImage => 'Change Image';

  @override
  String get imageUrl => 'Image URL';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get confirmDeleteArtwork =>
      'Are you sure you want to delete this artwork?';

  @override
  String get confirmDeleteGuestbook =>
      'Are you sure you want to delete this guestbook entry?';

  @override
  String get artistName => 'Artist Name';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get profileUpdated => 'Artist profile updated successfully.';

  @override
  String get artworkSaved => 'Artwork saved successfully.';

  @override
  String get artworkDeleted => 'Artwork deleted successfully.';

  @override
  String get guestbookDeleted => 'Guestbook entry deleted.';

  @override
  String get guestbookStatusUpdated => 'Guestbook entry status updated.';

  @override
  String get approve => 'Approve';

  @override
  String get unapprove => 'Unapprove';

  @override
  String get status => 'Status';

  @override
  String get actions => 'Actions';

  @override
  String get noEntries => 'No entries found.';

  @override
  String get approvedMessages => 'Approved Guestbook Messages';

  @override
  String get copyLink => 'Copy Link';

  @override
  String get linkCopied => 'Artwork link copied to clipboard!';

  @override
  String get searchArtworks => 'Search artworks...';

  @override
  String get previousArtwork => 'Previous';

  @override
  String get nextArtwork => 'Next';

  @override
  String get shareArtworkHeader => 'Artwork from Atelier Gallery';

  @override
  String get titleMk => 'Title (Macedonian)';

  @override
  String get titleEn => 'Title (English)';

  @override
  String get descriptionMk => 'Description (Macedonian)';

  @override
  String get descriptionEn => 'Description (English)';

  @override
  String get featured => 'Featured';

  @override
  String get requiredEnOrMk => 'Required (EN or MK)';

  @override
  String imageUploadFailed(Object error) {
    return 'Image upload failed: $error. You can manually enter an Image URL.';
  }

  @override
  String errorSavingArtwork(Object error) {
    return 'Error saving artwork: $error';
  }

  @override
  String errorDeletingArtwork(Object error) {
    return 'Error deleting artwork: $error';
  }

  @override
  String errorGeneric(Object error) {
    return 'Error: $error';
  }

  @override
  String errorSavingProfile(Object error) {
    return 'Error saving profile: $error';
  }

  @override
  String errorDeletingEntry(Object error) {
    return 'Error deleting entry: $error';
  }

  @override
  String artWorldOfArtist(Object artistName) {
    return 'The Art World of $artistName';
  }

  @override
  String get guestbookNameLengthError =>
      'Name must be between 2 and 50 characters.';

  @override
  String get guestbookMessageLengthError =>
      'Message must be between 5 and 500 characters.';

  @override
  String get guestbookUrlNotAllowed =>
      'URLs and web links are not allowed in guestbook messages.';

  @override
  String guestbookCooldownActive(Object seconds) {
    return 'Please wait $seconds seconds before submitting another message.';
  }

  @override
  String get noApprovedGuestbookEntries =>
      'No approved guestbook messages yet. Be the first to leave one!';

  @override
  String get guestbookRateLimitError =>
      'Too many submissions. Please try again later.';

  @override
  String get captchaVerification => 'Math Verification';

  @override
  String captchaQuestion(Object a, Object b) {
    return 'What is $a + $b?';
  }

  @override
  String get captchaAnswerHint => 'Enter answer';

  @override
  String get captchaError => 'Incorrect math answer. Please try again.';

  @override
  String get refresh => 'Refresh';

  @override
  String errorUpdatingEntry(Object error) {
    return 'Error updating entry: $error';
  }

  @override
  String get viewOnWall => 'View on Wall';

  @override
  String get artworkView => 'Artwork Details';

  @override
  String get frameStyle => 'Frame Style';

  @override
  String get frameNone => 'Canvas Edge (No Frame)';

  @override
  String get frameOak => 'Natural Oak';

  @override
  String get frameWhite => 'Classic White';

  @override
  String get frameGold => 'Warm Gold';

  @override
  String get wallColor => 'Wall Color';

  @override
  String get wallGalleryOffWhite => 'Gallery White';

  @override
  String get wallSoftSage => 'Soft Sage';

  @override
  String get wallWarmSand => 'Warm Sand';

  @override
  String get wallPastelSky => 'Pastel Sky';

  @override
  String get passePartout => 'Inner white mat border (passe-partout)';

  @override
  String scaledToScaleHint(Object dimensions) {
    return 'Scaled proportionally ($dimensions)';
  }

  @override
  String get virtualExhibition => '360° Virtual Exhibition';

  @override
  String get virtualExhibitionSubtitle =>
      'Step inside our bright virtual gallery hall and explore artworks in 360°';

  @override
  String get enterVirtualExhibition => 'Enter 360° Exhibition';

  @override
  String get lookLeft => 'Look Left';

  @override
  String get lookRight => 'Look Right';

  @override
  String get resetView => 'Center View';

  @override
  String get virtualHallInstructions =>
      'Drag left or right to explore the 360° hall. Tap any artwork to inspect.';

  @override
  String get wallLeft => 'West Wall';

  @override
  String get wallCenter => 'Main Hall';

  @override
  String get wallRight => 'East Wall';

  @override
  String get wallBack => 'South Wall';

  @override
  String get tapToInspect => 'Tap to inspect artwork';

  @override
  String get stepCloser => 'Step Closer';

  @override
  String get stepBack => 'Step Back';

  @override
  String get roomThemeBright => 'Bright Modern Hall';

  @override
  String get roomThemeAtelier => 'Watercolor Atelier';

  @override
  String get roomThemeEvening => 'Soft Evening Gallery';

  @override
  String get galleryAtmosphere => 'Room Atmosphere';

  @override
  String get galleryLights => 'Gallery Lights';

  @override
  String get addToFavorites => 'Add to Favorites';

  @override
  String get removeFromFavorites => 'Remove from Favorites';

  @override
  String get favorites => 'Favorites';

  @override
  String get onlyFavorites => 'Favorites Only';

  @override
  String get reactionLike => 'Like';

  @override
  String get reactionLove => 'Lovely';

  @override
  String get reactionMagical => 'Magical';

  @override
  String get reactionArtistic => 'Artistic';

  @override
  String get reactionEmotional => 'Emotional';

  @override
  String get comments => 'Comments';

  @override
  String get leaveComment => 'Leave a Comment';

  @override
  String get commentText => 'Your Comment';

  @override
  String get commentSubmittedForApproval =>
      'Your comment has been submitted and is awaiting admin approval.';

  @override
  String get noCommentsYet =>
      'No comments yet. Be the first to share your thoughts!';

  @override
  String get manageArtworkComments => 'Artwork Comments';

  @override
  String get confirmDeleteComment =>
      'Are you sure you want to delete this comment?';

  @override
  String get commentDeleted => 'Comment deleted.';

  @override
  String get commentStatusUpdated => 'Comment status updated.';

  @override
  String favoritesWithCount(Object count) {
    return 'Favorites ($count)';
  }

  @override
  String get noFavoritesYet =>
      'No favorite artworks yet. Tap the heart icon on any artwork to add it to your favorites.';

  @override
  String get clearFavorites => 'Clear All';

  @override
  String get confirmClearFavorites =>
      'Are you sure you want to remove all artworks from your favorites?';

  @override
  String get gridView => 'Grid';

  @override
  String get timelineView => 'Timeline';

  @override
  String artworksCount(Object count) {
    return '$count artworks';
  }

  @override
  String get creativeJourney => 'Creative Journey';

  @override
  String get artPuzzle => 'Art Puzzle';

  @override
  String get artPuzzleSubtitle => 'Assemble the artwork';

  @override
  String get playPuzzle => 'Play Puzzle';

  @override
  String get chooseArtwork => 'Choose Artwork';

  @override
  String get gridSizeLabel => 'Grid Size';

  @override
  String get easy3x3 => '3×3 (Easy)';

  @override
  String get medium4x4 => '4×4 (Medium)';

  @override
  String get movesLabel => 'Moves';

  @override
  String get timeLabel => 'Time';

  @override
  String get previewLabel => 'Preview';

  @override
  String get peekLabel => 'Peek Original';

  @override
  String get shuffleLabel => 'Shuffle';

  @override
  String get restartLabel => 'Restart';

  @override
  String get puzzleCompleted => 'Masterpiece Completed!';

  @override
  String puzzleCompletedDesc(Object moves, Object time) {
    return 'Congratulations! You assembled the artwork in $moves moves and $time.';
  }

  @override
  String get playAgain => 'Play Again';

  @override
  String get selectAnotherArtwork => 'Pick Another Artwork';

  @override
  String bestScore(Object moves, Object time) {
    return 'Best: $time ($moves moves)';
  }

  @override
  String get noBestScore => 'Best: --';

  @override
  String get newBestScore => 'New Record!';

  @override
  String get hard5x5 => '5×5 (Hard)';

  @override
  String get nickname => 'Nickname';

  @override
  String get enterNickname => 'Enter Nickname';

  @override
  String get nicknameHint => 'e.g. ArtExplorer99';

  @override
  String get nicknameLengthError =>
      'Nickname must be between 2 and 15 characters.';

  @override
  String get nicknameCharError =>
      'Only letters, numbers, spaces, _ and - allowed.';

  @override
  String get nicknameNotice =>
      'Pick a fun nickname! Please do not use real personal info.';

  @override
  String get changeNickname => 'Change Nickname';

  @override
  String playingAs(Object nickname) {
    return 'Playing as: $nickname';
  }

  @override
  String get setNicknameToPlay =>
      'Set a nickname to submit scores & join the leaderboard!';

  @override
  String get leaderboardTitle => 'Puzzle Leaderboard';

  @override
  String get tabTotalPoints => 'Total Points';

  @override
  String get tabByLevel => 'Best by Level';

  @override
  String get rankLabel => 'Rank';

  @override
  String get playerLabel => 'Player';

  @override
  String get pointsLabel => 'Points';

  @override
  String ptsEarned(Object points) {
    return '+$points pts';
  }

  @override
  String totalPointsLabel(Object points) {
    return 'Total Points: $points';
  }

  @override
  String puzzlesCompletedCount(Object count) {
    return '$count solved';
  }

  @override
  String get noLeaderboardEntries =>
      'No scores recorded yet. Be the first to solve a puzzle!';

  @override
  String get scoreSubmitted => 'Score saved to leaderboard!';

  @override
  String get savedOffline => 'Saved locally (Offline)';

  @override
  String get submittingScore => 'Submitting score...';

  @override
  String get viewLeaderboard => 'Leaderboard';

  @override
  String get backToPuzzle => 'Back to Puzzle';

  @override
  String get level3x3 => '3×3 Easy';

  @override
  String get level4x4 => '4×4 Medium';

  @override
  String get level5x5 => '5×5 Hard';

  @override
  String get totalPoints => 'Total Points';

  @override
  String get puzzlesSolved => 'Puzzles Solved';

  @override
  String get bestTime => 'Best Time';

  @override
  String get bestMoves => 'Best Moves';

  @override
  String get saveNickname => 'Save Nickname';

  @override
  String get managePuzzleScores => 'Puzzle Nicknames';

  @override
  String get deleteScoresForNickname => 'Delete All Scores for Nickname';

  @override
  String confirmDeleteNicknameScores(Object nickname) {
    return 'Are you sure you want to delete all puzzle scores for nickname \"$nickname\"?';
  }

  @override
  String get confirmDeletePuzzleScore =>
      'Are you sure you want to delete this puzzle score entry?';

  @override
  String get scoreEntryDeleted => 'Puzzle score entry deleted.';

  @override
  String get nicknameScoresDeleted => 'All scores for nickname deleted.';

  @override
  String errorDeletingPuzzleScore(Object error) {
    return 'Error deleting puzzle score: $error';
  }

  @override
  String get searchNicknames => 'Search nicknames...';

  @override
  String get allLevels => 'All Levels';

  @override
  String get deleteEntry => 'Delete Entry';

  @override
  String get deleteAllNicknameScores => 'Delete All Scores';

  @override
  String scoresCount(Object count) {
    return '$count scores';
  }

  @override
  String get bioMk => 'Biography (MK)';

  @override
  String get bioEn => 'Biography (EN)';

  @override
  String get artSchoolMk => 'Art Education (MK)';

  @override
  String get artSchoolEn => 'Art Education (EN)';

  @override
  String get favoriteTechniquesMk => 'Favorite Techniques (MK)';

  @override
  String get favoriteTechniquesEn => 'Favorite Techniques (EN)';

  @override
  String get artistNameMk => 'Artist Name (MK)';

  @override
  String get artistNameEn => 'Artist Name (EN)';
}
