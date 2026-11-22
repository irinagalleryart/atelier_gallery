import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/atelier_models.dart';
import '../services/supabase_service.dart';

/// Centralized controller managing gallery data state (artworks, artist profile, guestbook)
/// with real-time refresh across public views and admin panel.
class GalleryDataController extends ChangeNotifier {
  static final List<ArtworkModel> _fallbackArtworks = const [
    ArtworkModel(
      id: '1',
      title: 'My Dream World',
      titleMk: 'Мојот свет од соништата',
      titleEn: 'My Dream World',
      description:
          'Colorful mountains, pine trees, and a bright river painted with joy and imagination.',
      descriptionMk:
          'Шредести планини, борови и светла река насликани со радост и имагинација.',
      descriptionEn:
          'Colorful mountains, pine trees, and a bright river painted with joy and imagination.',
      technique: 'Acrylic & Tempera on Paper',
      createdYear: 2025,
      dimensions: '50 x 70 cm',
      imageUrl:
          'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?auto=format&fit=crop&w=1200&q=80',
      isFeatured: true,
    ),
    ArtworkModel(
      id: '2',
      title: 'Sunny Meadow',
      titleMk: 'Сончева ливада',
      titleEn: 'Sunny Meadow',
      description:
          'Playful brushstrokes of yellow, blue, and coral celebrating spring outdoors.',
      descriptionMk:
          'Разиграни потези со четка во жолта, сина и корална боја што ја слават пролетта.',
      descriptionEn:
          'Playful brushstrokes of yellow, blue, and coral celebrating spring outdoors.',
      technique: 'Watercolor',
      createdYear: 2025,
      dimensions: '35 x 50 cm',
      imageUrl:
          'https://images.unsplash.com/photo-1541961817774-9231f7779f5f?auto=format&fit=crop&w=1200&q=80',
      isFeatured: false,
    ),
    ArtworkModel(
      id: '3',
      title: 'Golden Spiral',
      titleMk: 'Златна спирала',
      titleEn: 'Golden Spiral',
      description:
          'A gentle exploration of curves, warm ochre tones, and curious patterns.',
      descriptionMk:
          'Нежно истражување на криви линии, топли окер нивни и љубопитни обрасци.',
      descriptionEn:
          'A gentle exploration of curves, warm ochre tones, and curious patterns.',
      technique: 'Pastel & Pencil',
      createdYear: 2024,
      dimensions: '30 x 40 cm',
      imageUrl:
          'https://images.unsplash.com/photo-1578301978693-85fa9c0320b9?auto=format&fit=crop&w=1200&q=80',
      isFeatured: false,
    ),
    ArtworkModel(
      id: '4',
      title: 'Midnight Garden',
      titleMk: 'Полноќна градина',
      titleEn: 'Midnight Garden',
      description:
          'Deep cobalt skies and glowing autumn leaves painted after art class.',
      descriptionMk:
          'Длабоки кобалтни небеса и светачки есенски лисја насликани по часот по уметност.',
      descriptionEn:
          'Deep cobalt skies and glowing autumn leaves painted after art class.',
      technique: 'Tempera on Paper',
      createdYear: 2024,
      dimensions: '40 x 50 cm',
      imageUrl:
          'https://images.unsplash.com/photo-1513364776144-60967b0f800f?auto=format&fit=crop&w=1200&q=80',
      isFeatured: false,
    ),
  ];

  static const ArtistProfileModel _fallbackProfile = ArtistProfileModel(
    artistName: 'Mia',
    artistNameMk: 'Миа',
    artistNameEn: 'Mia',
    bio:
        'Young artist who loves painting colorful landscapes, animals, and imaginative worlds.',
    bioMk: 'Млада уметница која обожава да слика шарени пејзажи, животни и светови од имагинацијата.',
    bioEn: 'Young artist who loves painting colorful landscapes, animals, and imaginative worlds.',
    artSchool: 'Children’s Art Studio',
    artSchoolMk: 'Детско уметничко студио',
    artSchoolEn: 'Children’s Art Studio',
    favoriteTechniques: 'Watercolor, Tempera, Acrylic, Colored Pencils',
    favoriteTechniquesMk: 'Акварел, Темпера, Акрилик, Водени боички',
    favoriteTechniquesEn: 'Watercolor, Tempera, Acrylic, Colored Pencils',
  );

  List<ArtworkModel> _artworks = _fallbackArtworks;
  ArtistProfileModel _artistProfile = _fallbackProfile;
  List<GuestbookModel> _guestbookEntries = [];
  Set<String> _favoriteArtworkIds = {};
  String _visitorId = '';
  List<Map<String, dynamic>> _reactions = [];
  List<ArtworkCommentModel> _comments = [];
  bool _isLoading = true;
  RealtimeChannel? _guestbookChannel;

  List<ArtworkModel> get artworks => _artworks;
  ArtistProfileModel get artistProfile => _artistProfile;
  List<GuestbookModel> get allGuestbookEntries => _guestbookEntries;
  List<GuestbookModel> get approvedGuestbookEntries {
    final approved = _guestbookEntries.where((entry) => entry.isApproved).toList();
    approved.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return approved;
  }
  Set<String> get favoriteArtworkIds => Set.unmodifiable(_favoriteArtworkIds);
  List<ArtworkModel> get favoriteArtworks {
    return _artworks.where((a) => _favoriteArtworkIds.contains(a.id)).toList();
  }
  bool get isLoading => _isLoading;
  String get visitorId => _visitorId;

  bool isFavorite(String artworkId) => _favoriteArtworkIds.contains(artworkId);

  Future<void> toggleFavorite(String artworkId) async {
    if (_favoriteArtworkIds.contains(artworkId)) {
      _favoriteArtworkIds.remove(artworkId);
    } else {
      _favoriteArtworkIds.add(artworkId);
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'favorite_artwork_ids',
        _favoriteArtworkIds.toList(),
      );
    } catch (e) {
      debugPrint('GalleryDataController: Error persisting favorites: $e');
    }
  }

  Future<void> clearFavorites() async {
    _favoriteArtworkIds.clear();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorite_artwork_ids', []);
    } catch (e) {
      debugPrint('GalleryDataController: Error clearing favorites: $e');
    }
  }

  Future<void> _initVisitorId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString('atelier_visitor_id');
      if (id == null || id.isEmpty) {
        id = 'visitor_${DateTime.now().microsecondsSinceEpoch}';
        await prefs.setString('atelier_visitor_id', id);
      }
      _visitorId = id;
    } catch (e) {
      debugPrint('GalleryDataController: Error initializing visitor ID: $e');
      _visitorId = 'visitor_fallback';
    }
  }

  int getReactionCount(String artworkId, String reactionType) {
    return _reactions
        .where((r) =>
            r['artwork_id']?.toString() == artworkId &&
            r['reaction_type']?.toString() == reactionType)
        .length;
  }

  bool hasVisitorReacted(String artworkId, String reactionType) {
    return _reactions.any((r) =>
        r['artwork_id']?.toString() == artworkId &&
        r['visitor_id']?.toString() == _visitorId &&
        r['reaction_type']?.toString() == reactionType);
  }

  Future<void> toggleReaction(String artworkId, String reactionType) async {
    if (_visitorId.isEmpty) {
      await _initVisitorId();
    }

    final hasReacted = hasVisitorReacted(artworkId, reactionType);

    // Optimistic local update
    if (hasReacted) {
      _reactions.removeWhere((r) =>
          r['artwork_id']?.toString() == artworkId &&
          r['visitor_id']?.toString() == _visitorId &&
          r['reaction_type']?.toString() == reactionType);
    } else {
      _reactions.add({
        'artwork_id': artworkId,
        'visitor_id': _visitorId,
        'reaction_type': reactionType,
      });
    }
    notifyListeners();

    if (SupabaseService.isInitialized) {
      try {
        if (hasReacted) {
          await SupabaseService.client
              .from('artwork_reactions')
              .delete()
              .match({
            'artwork_id': artworkId,
            'visitor_id': _visitorId,
            'reaction_type': reactionType,
          });
        } else {
          await SupabaseService.client.from('artwork_reactions').insert({
            'artwork_id': artworkId,
            'visitor_id': _visitorId,
            'reaction_type': reactionType,
          });
        }
      } catch (e) {
        debugPrint('GalleryDataController: Error toggling reaction: $e');
        await loadAllData();
      }
    }
  }

  List<ArtworkCommentModel> getApprovedComments(String artworkId) {
    final list = _comments
        .where((c) => c.artworkId == artworkId && c.isApproved)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<ArtworkCommentModel> get allArtworkComments => _comments;

  Future<void> submitArtworkComment({
    required String artworkId,
    required String authorName,
    required String commentText,
  }) async {
    if (_visitorId.isEmpty) {
      await _initVisitorId();
    }

    if (SupabaseService.isInitialized) {
      await SupabaseService.client.from('artwork_comments').insert({
        'artwork_id': artworkId,
        'visitor_id': _visitorId,
        'author_name': authorName,
        'comment_text': commentText,
        'is_approved': false,
      });
    }
    await loadAllData();
  }

  Future<void> toggleCommentApproval(String commentId, bool currentStatus) async {
    if (SupabaseService.isInitialized && isValidUuid(commentId)) {
      await SupabaseService.client
          .from('artwork_comments')
          .update({'is_approved': !currentStatus})
          .eq('id', commentId);
    }
    await loadAllData();
  }

  Future<void> deleteComment(String commentId) async {
    if (SupabaseService.isInitialized && isValidUuid(commentId)) {
      await SupabaseService.client
          .from('artwork_comments')
          .delete()
          .eq('id', commentId);
    }
    await loadAllData();
  }

  void _setupRealtimeSubscription() {
    if (!SupabaseService.isInitialized) return;
    if (_guestbookChannel != null) return;

    try {
      _guestbookChannel = SupabaseService.client
          .channel('public:guestbook_realtime')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'guestbook',
            callback: (payload) {
              debugPrint('GalleryDataController: Realtime guestbook change: ${payload.eventType}');
              loadAllData();
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('GalleryDataController: Realtime subscription error: $e');
    }
  }

  @override
  void dispose() {
    if (_guestbookChannel != null && SupabaseService.isInitialized) {
      try {
        SupabaseService.client.removeChannel(_guestbookChannel!);
      } catch (_) {}
    }
    super.dispose();
  }

  /// Helper to validate if a string matches standard UUID v4 format.
  static bool isValidUuid(String value) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(value);
  }

  /// Loads all data from Supabase DB or uses fallback mock data if unavailable.
  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFavorites = prefs.getStringList('favorite_artwork_ids');
      if (savedFavorites != null) {
        _favoriteArtworkIds = savedFavorites.toSet();
      }
    } catch (e) {
      debugPrint('GalleryDataController: Error loading favorites: $e');
    }

    await _initVisitorId();

    if (!SupabaseService.isInitialized) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _setupRealtimeSubscription();

    try {
      // 1. Fetch Artworks
      final List artworkRes = await SupabaseService.client
          .from('artworks')
          .select()
          .order('created_at', ascending: false);

      if (artworkRes.isNotEmpty) {
        _artworks = artworkRes
            .map((e) => ArtworkModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      // 2. Fetch Artist Profile
      final profileRes = await SupabaseService.client
          .from('artist_profile')
          .select()
          .limit(1)
          .maybeSingle();

      if (profileRes != null) {
        _artistProfile =
            ArtistProfileModel.fromJson(Map<String, dynamic>.from(profileRes));
      }

      // 3. Fetch Guestbook Entries
      final List guestbookRes = await SupabaseService.client
          .from('guestbook')
          .select()
          .order('created_at', ascending: false);

      if (guestbookRes.isNotEmpty) {
        _guestbookEntries = guestbookRes
            .map((e) => GuestbookModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      // 4. Fetch Reactions
      final List reactionRes = await SupabaseService.client
          .from('artwork_reactions')
          .select();
      if (reactionRes.isNotEmpty) {
        _reactions = reactionRes
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        _reactions = [];
      }

      // 5. Fetch Comments
      final List commentRes = await SupabaseService.client
          .from('artwork_comments')
          .select()
          .order('created_at', ascending: false);
      if (commentRes.isNotEmpty) {
        _comments = commentRes
            .map((e) => ArtworkCommentModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        _comments = [];
      }
    } catch (e) {
      debugPrint('GalleryDataController: Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create or update an artwork in Supabase with proper UUID validation.
  Future<void> saveArtwork({
    String? id,
    required String title,
    required String titleMk,
    required String titleEn,
    required String description,
    required String descriptionMk,
    required String descriptionEn,
    required String technique,
    required int createdYear,
    required String dimensions,
    required bool isFeatured,
    required String imageUrl,
  }) async {
    final effectiveTitle = titleEn.isNotEmpty ? titleEn : (titleMk.isNotEmpty ? titleMk : title);
    final effectiveDescription = descriptionEn.isNotEmpty ? descriptionEn : (descriptionMk.isNotEmpty ? descriptionMk : description);

    final payload = {
      'title': effectiveTitle,
      'title_mk': titleMk,
      'title_en': titleEn,
      'description': effectiveDescription,
      'description_mk': descriptionMk,
      'description_en': descriptionEn,
      'technique': technique,
      'created_year': createdYear,
      'dimensions': dimensions,
      'is_featured': isFeatured,
      'image_url': imageUrl,
    };

    if (SupabaseService.isInitialized) {
      if (id != null && id.isNotEmpty && isValidUuid(id)) {
        // Update existing database record with a valid UUID
        await SupabaseService.client
            .from('artworks')
            .update(payload)
            .eq('id', id)
            .select()
            .single();
      } else {
        // Omit non-UUID/fallback ID so Supabase auto-generates a valid UUID
        await SupabaseService.client
            .from('artworks')
            .insert(payload)
            .select()
            .single();
      }
    }

    await loadAllData();
  }

  /// Delete artwork by ID safely validating UUIDs.
  Future<void> deleteArtwork(String id) async {
    if (_favoriteArtworkIds.contains(id)) {
      _favoriteArtworkIds.remove(id);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          'favorite_artwork_ids',
          _favoriteArtworkIds.toList(),
        );
      } catch (e) {
        debugPrint('GalleryDataController: Error persisting favorites on delete: $e');
      }
    }
    if (SupabaseService.isInitialized && isValidUuid(id)) {
      await SupabaseService.client.from('artworks').delete().eq('id', id);
    }
    await loadAllData();
  }

  /// Update Artist Profile in Supabase
  Future<void> saveArtistProfile({
    required String artistName,
    required String artistNameMk,
    required String artistNameEn,
    required String bio,
    required String bioMk,
    required String bioEn,
    required String artSchool,
    required String artSchoolMk,
    required String artSchoolEn,
    required String favoriteTechniques,
    required String favoriteTechniquesMk,
    required String favoriteTechniquesEn,
  }) async {
    final payload = {
      'artist_name': artistName,
      'artist_name_mk': artistNameMk,
      'artist_name_en': artistNameEn,
      'bio': bio,
      'bio_mk': bioMk,
      'bio_en': bioEn,
      'art_school': artSchool,
      'art_school_mk': artSchoolMk,
      'art_school_en': artSchoolEn,
      'favorite_techniques': favoriteTechniques,
      'favorite_techniques_mk': favoriteTechniquesMk,
      'favorite_techniques_en': favoriteTechniquesEn,
    };

    if (SupabaseService.isInitialized) {
      final existing = await SupabaseService.client
          .from('artist_profile')
          .select('id')
          .limit(1)
          .maybeSingle();

      if (existing != null && existing['id'] != null) {
        await SupabaseService.client
            .from('artist_profile')
            .update(payload)
            .eq('id', existing['id']);
      } else {
        await SupabaseService.client.from('artist_profile').insert(payload);
      }
    }

    await loadAllData();
  }

  /// Toggle Guestbook entry approval status safely validating UUIDs
  Future<void> toggleGuestbookApproval(String id, bool currentStatus) async {
    if (SupabaseService.isInitialized && isValidUuid(id)) {
      await SupabaseService.client
          .from('guestbook')
          .update({'is_approved': !currentStatus})
          .eq('id', id)
          .select()
          .single();

      final index = _guestbookEntries.indexWhere((e) => e.id == id);
      if (index != -1) {
        final old = _guestbookEntries[index];
        _guestbookEntries[index] = GuestbookModel(
          id: old.id,
          authorName: old.authorName,
          message: old.message,
          isApproved: !currentStatus,
          createdAt: old.createdAt,
        );
        notifyListeners();
      }
    }
    await loadAllData();
  }

  /// Delete Guestbook entry by ID safely validating UUIDs
  Future<void> deleteGuestbookEntry(String id) async {
    if (SupabaseService.isInitialized && isValidUuid(id)) {
      await SupabaseService.client
          .from('guestbook')
          .delete()
          .eq('id', id)
          .select();

      _guestbookEntries.removeWhere((e) => e.id == id);
      notifyListeners();
    }
    await loadAllData();
  }

  /// Submit new guestbook message from public view
  Future<void> submitGuestbookMessage({
    required String authorName,
    required String message,
  }) async {
    if (SupabaseService.isInitialized) {
      await SupabaseService.client.from('guestbook').insert({
        'author_name': authorName,
        'message': message,
        'is_approved': false,
      });
    }
    await loadAllData();
  }
}
