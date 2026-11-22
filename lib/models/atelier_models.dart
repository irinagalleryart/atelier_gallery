/// Data models for Atelier Gallery (Artworks, Guestbook Entries, Artist Profile).
class ArtworkModel {
  final String id;
  final String title;
  final String titleMk;
  final String titleEn;
  final String description;
  final String descriptionMk;
  final String descriptionEn;
  final String technique;
  final int createdYear;
  final String imageUrl;
  final String dimensions;
  final bool isFeatured;

  const ArtworkModel({
    required this.id,
    required this.title,
    this.titleMk = '',
    this.titleEn = '',
    required this.description,
    this.descriptionMk = '',
    this.descriptionEn = '',
    required this.technique,
    required this.createdYear,
    required this.imageUrl,
    this.dimensions = '70 x 90 cm',
    this.isFeatured = false,
  });

  String localizedTitle(String localeCode) {
    final code = localeCode.toLowerCase();
    if (code == 'mk') {
      if (titleMk.isNotEmpty) return titleMk;
      if (titleEn.isNotEmpty) return titleEn;
      if (title.isNotEmpty) return title;
      return 'Untitled';
    } else {
      if (titleEn.isNotEmpty) return titleEn;
      if (titleMk.isNotEmpty) return titleMk;
      if (title.isNotEmpty) return title;
      return 'Untitled';
    }
  }

  String localizedDescription(String localeCode) {
    final code = localeCode.toLowerCase();
    if (code == 'mk') {
      if (descriptionMk.isNotEmpty) return descriptionMk;
      if (descriptionEn.isNotEmpty) return descriptionEn;
      if (description.isNotEmpty) return description;
      return '';
    } else {
      if (descriptionEn.isNotEmpty) return descriptionEn;
      if (descriptionMk.isNotEmpty) return descriptionMk;
      if (description.isNotEmpty) return description;
      return '';
    }
  }

  factory ArtworkModel.fromJson(Map<String, dynamic> json) {
    final tMk = json['title_mk'] as String? ?? '';
    final tEn = json['title_en'] as String? ?? '';
    final legacyTitle = json['title'] as String? ?? 'Untitled';

    final dMk = json['description_mk'] as String? ?? '';
    final dEn = json['description_en'] as String? ?? '';
    final legacyDesc = json['description'] as String? ?? '';

    return ArtworkModel(
      id: json['id']?.toString() ?? '',
      title: legacyTitle,
      titleMk: tMk,
      titleEn: tEn,
      description: legacyDesc,
      descriptionMk: dMk,
      descriptionEn: dEn,
      technique: json['technique'] as String? ?? 'Oil on Canvas',
      createdYear: json['created_year'] as int? ?? 2024,
      imageUrl: json['image_url'] as String? ?? '',
      dimensions: json['dimensions'] as String? ?? '70 x 90 cm',
      isFeatured: json['is_featured'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'title_mk': titleMk,
        'title_en': titleEn,
        'description': description,
        'description_mk': descriptionMk,
        'description_en': descriptionEn,
        'technique': technique,
        'created_year': createdYear,
        'image_url': imageUrl,
        'dimensions': dimensions,
        'is_featured': isFeatured,
      };
}

class GuestbookModel {
  final String id;
  final String authorName;
  final String message;
  final bool isApproved;
  final DateTime createdAt;

  const GuestbookModel({
    required this.id,
    required this.authorName,
    required this.message,
    required this.isApproved,
    required this.createdAt,
  });

  factory GuestbookModel.fromJson(Map<String, dynamic> json) {
    return GuestbookModel(
      id: json['id']?.toString() ?? '',
      authorName: json['author_name'] as String? ?? 'Anonymous',
      message: json['message'] as String? ?? '',
      isApproved: json['is_approved'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ArtistProfileModel {
  final String artistName;
  final String artistNameMk;
  final String artistNameEn;
  final String bio;
  final String bioMk;
  final String bioEn;
  final String artSchool;
  final String artSchoolMk;
  final String artSchoolEn;
  final String favoriteTechniques;
  final String favoriteTechniquesMk;
  final String favoriteTechniquesEn;

  const ArtistProfileModel({
    required this.artistName,
    this.artistNameMk = '',
    this.artistNameEn = '',
    required this.bio,
    this.bioMk = '',
    this.bioEn = '',
    required this.artSchool,
    this.artSchoolMk = '',
    this.artSchoolEn = '',
    required this.favoriteTechniques,
    this.favoriteTechniquesMk = '',
    this.favoriteTechniquesEn = '',
  });

  String localizedArtistName(String localeCode) {
    final code = localeCode.toLowerCase();
    if (code == 'mk') {
      if (artistNameMk.isNotEmpty) return artistNameMk;
      if (artistNameEn.isNotEmpty) return artistNameEn;
      if (artistName.isNotEmpty) return artistName;
      return 'Atelier Artist';
    } else {
      if (artistNameEn.isNotEmpty) return artistNameEn;
      if (artistNameMk.isNotEmpty) return artistNameMk;
      if (artistName.isNotEmpty) return artistName;
      return 'Atelier Artist';
    }
  }

  String localizedBio(String localeCode) {
    final code = localeCode.toLowerCase();
    if (code == 'mk') {
      if (bioMk.isNotEmpty) return bioMk;
      if (bioEn.isNotEmpty) return bioEn;
      if (bio.isNotEmpty) return bio;
      return 'Contemporary painter exploring texture, light, and atmosphere.';
    } else {
      if (bioEn.isNotEmpty) return bioEn;
      if (bioMk.isNotEmpty) return bioMk;
      if (bio.isNotEmpty) return bio;
      return 'Contemporary painter exploring texture, light, and atmosphere.';
    }
  }

  String localizedArtSchool(String localeCode) {
    final code = localeCode.toLowerCase();
    if (code == 'mk') {
      if (artSchoolMk.isNotEmpty) return artSchoolMk;
      if (artSchoolEn.isNotEmpty) return artSchoolEn;
      if (artSchool.isNotEmpty) return artSchool;
      return 'Faculty of Fine Arts';
    } else {
      if (artSchoolEn.isNotEmpty) return artSchoolEn;
      if (artSchoolMk.isNotEmpty) return artSchoolMk;
      if (artSchool.isNotEmpty) return artSchool;
      return 'Faculty of Fine Arts';
    }
  }

  String localizedFavoriteTechniques(String localeCode) {
    final code = localeCode.toLowerCase();
    if (code == 'mk') {
      if (favoriteTechniquesMk.isNotEmpty) return favoriteTechniquesMk;
      if (favoriteTechniquesEn.isNotEmpty) return favoriteTechniquesEn;
      if (favoriteTechniques.isNotEmpty) return favoriteTechniques;
      return 'Oil on Canvas, Acrylic, Mixed Media';
    } else {
      if (favoriteTechniquesEn.isNotEmpty) return favoriteTechniquesEn;
      if (favoriteTechniquesMk.isNotEmpty) return favoriteTechniquesMk;
      if (favoriteTechniques.isNotEmpty) return favoriteTechniques;
      return 'Oil on Canvas, Acrylic, Mixed Media';
    }
  }

  factory ArtistProfileModel.fromJson(Map<String, dynamic> json) {
    final legacyName = json['artist_name'] as String? ?? 'Atelier Artist';
    final legacyBio = json['bio'] as String? ?? 'Contemporary painter exploring texture, light, and atmosphere.';
    final legacySchool = json['art_school'] as String? ?? 'Faculty of Fine Arts';
    final legacyTech = json['favorite_techniques'] as String? ?? 'Oil on Canvas, Acrylic, Mixed Media';

    return ArtistProfileModel(
      artistName: legacyName,
      artistNameMk: json['artist_name_mk'] as String? ?? '',
      artistNameEn: json['artist_name_en'] as String? ?? '',
      bio: legacyBio,
      bioMk: json['bio_mk'] as String? ?? '',
      bioEn: json['bio_en'] as String? ?? '',
      artSchool: legacySchool,
      artSchoolMk: json['art_school_mk'] as String? ?? '',
      artSchoolEn: json['art_school_en'] as String? ?? '',
      favoriteTechniques: legacyTech,
      favoriteTechniquesMk: json['favorite_techniques_mk'] as String? ?? '',
      favoriteTechniquesEn: json['favorite_techniques_en'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
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
}

class ArtworkCommentModel {
  final String id;
  final String artworkId;
  final String? visitorId;
  final String authorName;
  final String commentText;
  final bool isApproved;
  final DateTime createdAt;

  const ArtworkCommentModel({
    required this.id,
    required this.artworkId,
    this.visitorId,
    required this.authorName,
    required this.commentText,
    required this.isApproved,
    required this.createdAt,
  });

  factory ArtworkCommentModel.fromJson(Map<String, dynamic> json) {
    return ArtworkCommentModel(
      id: json['id']?.toString() ?? '',
      artworkId: json['artwork_id']?.toString() ?? '',
      visitorId: json['visitor_id']?.toString(),
      authorName: json['author_name'] as String? ?? 'Anonymous',
      commentText: json['comment_text'] as String? ?? '',
      isApproved: json['is_approved'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
