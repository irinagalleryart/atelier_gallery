import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/gallery_data_controller.dart';
import '../controllers/locale_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/atelier_models.dart';
import '../widgets/art_puzzle_dialog.dart';
import '../widgets/virtual_exhibition_hall.dart';
import '../widgets/virtual_wall_studio.dart';
import '../widgets/watercolor_background.dart';

/// Main public screen for Atelier Gallery matching the minimalist fine-art gallery layout.
class GalleryHomeScreen extends StatefulWidget {
  final LocaleController localeController;
  final GalleryDataController dataController;

  const GalleryHomeScreen({
    super.key,
    required this.localeController,
    required this.dataController,
  });

  @override
  State<GalleryHomeScreen> createState() => _GalleryHomeScreenState();
}

class _GalleryHomeScreenState extends State<GalleryHomeScreen> {
  int _selectedIndex = 0;
  bool _galleryInitialOnlyFavorites = false;

  void _showArtworkDetails(BuildContext context, List<ArtworkModel> artworks, ArtworkModel artwork) {
    final index = artworks.indexWhere((a) => a.id == artwork.id);
    showDialog(
      context: context,
      builder: (context) => _ArtworkDetailDialog(
        artworks: artworks,
        initialIndex: index >= 0 ? index : 0,
        dataController: widget.dataController,
      ),
    );
  }

  void _open360VirtualExhibition(BuildContext context, List<ArtworkModel> artworks) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VirtualExhibitionHall(
          artworks: artworks,
          dataController: widget.dataController,
          onArtworkTap: (artwork) {
            _showArtworkDetails(context, artworks, artwork);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return ListenableBuilder(
      listenable: widget.dataController,
      builder: (context, _) {
        final artworks = widget.dataController.artworks;
        final profile = widget.dataController.artistProfile;

        return Scaffold(
          body: WatercolorBackground(
            child: SafeArea(
              child: Column(
                children: [
                  _TopGalleryNavBar(
                    selectedIndex: _selectedIndex,
                    onTabSelected: (index) => setState(() {
                      _selectedIndex = index;
                      if (index != 1) _galleryInitialOnlyFavorites = false;
                    }),
                    localeController: widget.localeController,
                    dataController: widget.dataController,
                    onFavoritesTap: () => setState(() {
                      _selectedIndex = 1;
                      _galleryInitialOnlyFavorites = true;
                    }),
                    isDesktop: isDesktop,
                  ),
                  Expanded(
                    child: widget.dataController.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : IndexedStack(
                            index: _selectedIndex,
                            children: [
                              _HomeTab(
                                artworks: artworks,
                                artistName: profile.artistName,
                                dataController: widget.dataController,
                                onArtworkTap: (artwork) =>
                                    _showArtworkDetails(context, artworks, artwork),
                                onExploreGallery: () =>
                                    setState(() => _selectedIndex = 1),
                                onOpenVirtualExhibition: () =>
                                    _open360VirtualExhibition(context, artworks),
                              ),
                              _GalleryTab(
                                artworks: artworks,
                                dataController: widget.dataController,
                                onArtworkTap: (artwork) =>
                                    _showArtworkDetails(context, artworks, artwork),
                                onOpenVirtualExhibition: () =>
                                    _open360VirtualExhibition(context, artworks),
                                initialOnlyFavorites: _galleryInitialOnlyFavorites,
                              ),
                              _AboutArtistTab(profile: profile),
                              _GuestbookTab(dataController: widget.dataController),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: !isDesktop
              ? BottomNavigationBar(
                  currentIndex: _selectedIndex > 3 ? 0 : _selectedIndex,
                  type: BottomNavigationBarType.fixed,
                  onTap: (index) => setState(() {
                    _selectedIndex = index;
                    if (index != 1) _galleryInitialOnlyFavorites = false;
                  }),
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.home_outlined),
                      activeIcon: const Icon(Icons.home),
                      label: AppLocalizations.of(context)!.home,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.palette_outlined),
                      activeIcon: const Icon(Icons.palette),
                      label: AppLocalizations.of(context)!.gallery,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.person_outlined),
                      activeIcon: const Icon(Icons.person),
                      label: AppLocalizations.of(context)!.aboutArtist,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.book_outlined),
                      activeIcon: const Icon(Icons.book),
                      label: AppLocalizations.of(context)!.guestbook,
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}

/// Minimal centered top navigation bar with compact MK / EN pill toggle.
class _TopGalleryNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final LocaleController localeController;
  final GalleryDataController dataController;
  final VoidCallback onFavoritesTap;
  final bool isDesktop;

  const _TopGalleryNavBar({
    required this.selectedIndex,
    required this.onTabSelected,
    required this.localeController,
    required this.dataController,
    required this.onFavoritesTap,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final publicTabs = [
      l10n.home,
      l10n.gallery,
      l10n.aboutArtist,
      l10n.guestbook,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App Title & Logo branding on the left
          Flexible(
            child: InkWell(
              onTap: () => onTabSelected(0),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/branding/logo_iriart.png',
                      height: isDesktop ? 30 : 24,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.palette_outlined, size: 24, color: Color(0xFF7B5E4B));
                      },
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n.appTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D2D2D),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Centered navigation tabs for desktop
          if (isDesktop)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(publicTabs.length, (index) {
                      final isSelected = selectedIndex == index;
                      return InkWell(
                        onTap: () => onTabSelected(index),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14.0, vertical: 8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                publicTabs[index],
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? const Color(0xFF7B5E4B)
                                      : const Color(0xFF2D2D2D),
                                ),
                              ),
                              const SizedBox(height: 5),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 1.5,
                                width: isSelected ? 36 : 0,
                                color: const Color(0xFFD4B9A5),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          // Compact language toggle and favorites quick button on the right
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FavoritesQuickButton(
                dataController: dataController,
                onTap: onFavoritesTap,
              ),
              const SizedBox(width: 8),
              _CompactLanguageToggle(localeController: localeController),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact favorites quick access button with badge count
class _FavoritesQuickButton extends StatelessWidget {
  final GalleryDataController dataController;
  final VoidCallback onTap;

  const _FavoritesQuickButton({
    required this.dataController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final count = dataController.favoriteArtworkIds.length;
    final l10n = AppLocalizations.of(context)!;

    return Tooltip(
      message: l10n.favorites,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, size: 14, color: Color(0xFFD64550)),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Clean minimal pill toggle (`MK | EN`)
class _CompactLanguageToggle extends StatelessWidget {
  final LocaleController localeController;

  const _CompactLanguageToggle({required this.localeController});

  @override
  Widget build(BuildContext context) {
    final isMk = localeController.isMacedonian;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLangOption(
            label: 'MK',
            selected: isMk,
            onTap: () => localeController.setLanguageCode('mk'),
          ),
          _buildLangOption(
            label: 'EN',
            selected: !isMk,
            onTap: () => localeController.setLanguageCode('en'),
          ),
        ],
      ),
    );
  }

  Widget _buildLangOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2D2D2D) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: selected ? Colors.white : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}

/// Home Tab matching fine-art layout with responsive artwork scale and balanced spacing.
class _HomeTab extends StatefulWidget {
  final List<ArtworkModel> artworks;
  final String artistName;
  final GalleryDataController dataController;
  final ValueChanged<ArtworkModel> onArtworkTap;
  final VoidCallback onExploreGallery;
  final VoidCallback? onOpenVirtualExhibition;

  const _HomeTab({
    required this.artworks,
    required this.artistName,
    required this.dataController,
    required this.onArtworkTap,
    required this.onExploreGallery,
    this.onOpenVirtualExhibition,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> with SingleTickerProviderStateMixin {
  int _featuredIndex = 0;
  Timer? _autoRotateTimer;
  bool _isHovered = false;
  DateTime? _lastManualInteractionTime;
  late final AnimationController _puzzleAnimController;
  late final Animation<double> _puzzleScaleAnim;

  @override
  void initState() {
    super.initState();
    _puzzleAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _puzzleScaleAnim = Tween<double>(begin: 1.0, end: 1.035).animate(
      CurvedAnimation(parent: _puzzleAnimController, curve: Curves.easeInOut),
    );
    _startTimer();
  }

  @override
  void dispose() {
    _autoRotateTimer?.cancel();
    _puzzleAnimController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _autoRotateTimer?.cancel();
    _autoRotateTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted) return;
      if (_isHovered) return;
      if (_lastManualInteractionTime != null) {
        if (DateTime.now().difference(_lastManualInteractionTime!).inSeconds < 10) {
          return;
        }
      }

      final list = _featuredArtworks;
      if (list.length > 1) {
        setState(() {
          _featuredIndex = (_featuredIndex + 1) % list.length;
        });
      }
    });
  }

  void _onManualNavigate(int newIndex) {
    setState(() {
      _featuredIndex = newIndex;
      _lastManualInteractionTime = DateTime.now();
    });
  }

  List<ArtworkModel> get _featuredArtworks {
    final featured = widget.artworks.where((a) => a.isFeatured).toList();
    if (featured.isNotEmpty) {
      return featured;
    }
    if (widget.artworks.isNotEmpty) {
      return [widget.artworks.first];
    }
    return [
      const ArtworkModel(
        id: '1',
        title: 'My Dream World',
        description: '',
        technique: 'Watercolor',
        createdYear: 2025,
        imageUrl: '',
      ),
    ];
  }

  @override
  void didUpdateWidget(covariant _HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final featuredList = _featuredArtworks;
    if (_featuredIndex >= featuredList.length) {
      _featuredIndex = featuredList.isEmpty ? 0 : featuredList.length - 1;
    }
    if (_featuredIndex < 0) {
      _featuredIndex = 0;
    }
  }

  void _nextSlide() {
    final list = _featuredArtworks;
    if (list.length > 1) {
      _onManualNavigate((_featuredIndex + 1) % list.length);
    }
  }

  void _prevSlide() {
    final list = _featuredArtworks;
    if (list.length > 1) {
      _onManualNavigate((_featuredIndex - 1 + list.length) % list.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final screenWidth = MediaQuery.of(context).size.width;

    final featuredList = _featuredArtworks;
    if (_featuredIndex >= featuredList.length) {
      _featuredIndex = featuredList.isEmpty ? 0 : featuredList.length - 1;
    }
    final activeFeatured = featuredList[_featuredIndex.clamp(0, featuredList.length - 1)];
    final hasMultipleFeatured = featuredList.length > 1;

    final heroDisplayTitle = l10n.artWorldOfArtist(widget.artistName);

    final latestList = widget.artworks.take(4).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Hero Artwork floating above watercolor background with slide showcase controls & BoxFit.contain
              Column(
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _isHovered = true),
                    onExit: (_) => setState(() => _isHovered = false),
                    child: GestureDetector(
                      onTap: () => widget.onArtworkTap(activeFeatured),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Hero(
                            tag: 'artwork_${activeFeatured.id}',
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    screenWidth > 760 ? 680 : screenWidth * 0.92,
                                maxHeight: screenWidth > 760 ? 400 : 280,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF9F6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.16),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: activeFeatured.imageUrl.isNotEmpty
                                  ? Image.network(
                                      activeFeatured.imageUrl,
                                      fit: BoxFit.contain,
                                      alignment: Alignment.center,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const _ArtworkPlaceholder(height: 340),
                                    )
                                  : const _ArtworkPlaceholder(height: 340),
                            ),
                          ),
                          if (hasMultipleFeatured) ...[
                            Positioned(
                              left: 12,
                              child: Tooltip(
                                message: l10n.previousArtwork,
                                child: Material(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
                                    onPressed: _prevSlide,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 12,
                              child: Tooltip(
                                message: l10n.nextArtwork,
                                child: Material(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    icon: const Icon(Icons.chevron_right, color: Colors.white, size: 24),
                                    onPressed: _nextSlide,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      Text(
                        activeFeatured.title == 'Sunset Over Atelier'
                            ? l10n.myDreamWorld
                            : activeFeatured.localizedTitle(localeCode),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF4A4A4A),
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (hasMultipleFeatured) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(featuredList.length, (index) {
                            final isActive = index == _featuredIndex;
                            return GestureDetector(
                              onTap: () => _onManualNavigate(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: isActive ? 20 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFF1F1F1F)
                                      : Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 2. Large Display Title ("The Art World of ...")
              Text(
                heroDisplayTitle,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: screenWidth > 760 ? 40 : 26,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF1F1F1F),
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 18),

              // Action Buttons Row (Explore Gallery, Art Puzzle, & 360° Virtual Exhibition)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.onExploreGallery,
                    icon: const Icon(Icons.explore_outlined, size: 18),
                    label: Text(
                      l10n.exploreGallery,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1F1F1F),
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  ScaleTransition(
                    scale: _puzzleScaleAnim,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final artworks = widget.artworks.isNotEmpty
                            ? widget.artworks
                            : widget.dataController.artworks;
                        if (artworks.isNotEmpty) {
                          ArtPuzzleDialog.show(
                            context,
                            initialArtwork: activeFeatured,
                            artworks: artworks,
                            dataController: widget.dataController,
                          );
                        }
                      },
                      icon: const Icon(Icons.extension_outlined, size: 18, color: Color(0xFF7B5E4B)),
                      label: Text(
                        l10n.artPuzzle,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F1F1F),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1F1F1F),
                        side: BorderSide(color: const Color(0xFF7B5E4B).withValues(alpha: 0.6)),
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  if (widget.onOpenVirtualExhibition != null)
                    ElevatedButton.icon(
                      onPressed: widget.onOpenVirtualExhibition,
                      icon: const Icon(Icons.view_in_ar_rounded, size: 18),
                      label: Text(
                        l10n.virtualExhibition,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E2026),
                        foregroundColor: const Color(0xFFD4AF37),
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 28),

              // 3. Centered "Latest Creations" heading
              Text(
                l10n.latestCreations,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: screenWidth > 760 ? 22 : 19,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF2B2B2B),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // 4. Grid row of framed artwork cards
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: screenWidth > 760 ? 4 : 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: latestList.length,
                  itemBuilder: (context, index) {
                    final artwork = latestList[index];
                    return _FramedArtworkCard(
                      artwork: artwork,
                      dataController: widget.dataController,
                      onTap: () => widget.onArtworkTap(artwork),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  final double height;

  const _ArtworkPlaceholder({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: const Color(0xFFECEAE4),
      child: const Center(
        child: Icon(
          Icons.palette_outlined,
          size: 48,
          color: Color(0xFF9A968E),
        ),
      ),
    );
  }
}

/// Gallery Tab with Filtering, Search, and Responsive Grid
enum _GalleryViewMode { grid, timeline }

class _GalleryViewModeToggle extends StatelessWidget {
  final _GalleryViewMode currentMode;
  final ValueChanged<_GalleryViewMode> onChanged;

  const _GalleryViewModeToggle({
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPillOption(
            context,
            mode: _GalleryViewMode.grid,
            icon: Icons.grid_view_rounded,
            label: l10n.gridView,
          ),
          const SizedBox(width: 4),
          _buildPillOption(
            context,
            mode: _GalleryViewMode.timeline,
            icon: Icons.timeline_rounded,
            label: l10n.timelineView,
          ),
        ],
      ),
    );
  }

  Widget _buildPillOption(
    BuildContext context, {
    required _GalleryViewMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentMode == mode;
    return InkWell(
      onTap: () {
        if (!isSelected) {
          HapticFeedback.lightImpact();
          onChanged(mode);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7B5E4B) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : const Color(0xFF1F1F1F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryTab extends StatefulWidget {
  final List<ArtworkModel> artworks;
  final GalleryDataController dataController;
  final ValueChanged<ArtworkModel> onArtworkTap;
  final VoidCallback? onOpenVirtualExhibition;
  final bool initialOnlyFavorites;

  const _GalleryTab({
    required this.artworks,
    required this.dataController,
    required this.onArtworkTap,
    this.onOpenVirtualExhibition,
    this.initialOnlyFavorites = false,
  });

  @override
  State<_GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends State<_GalleryTab> {
  String _selectedTechnique = 'All';
  String _selectedYear = 'All';
  late bool _onlyFavorites;
  _GalleryViewMode _viewMode = _GalleryViewMode.grid;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _onlyFavorites = widget.initialOnlyFavorites;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void didUpdateWidget(covariant _GalleryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialOnlyFavorites != oldWidget.initialOnlyFavorites &&
        widget.initialOnlyFavorites) {
      setState(() {
        _onlyFavorites = true;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final screenWidth = MediaQuery.of(context).size.width;
    final favCount = widget.dataController.favoriteArtworkIds.length;

    final techniques = [
      'All',
      ...widget.artworks.map((a) => a.technique).toSet()
    ];
    final years = [
      'All',
      ...widget.artworks.map((a) => a.createdYear.toString()).toSet()
    ];

    final filteredArtworks = widget.artworks.where((artwork) {
      final matchesTechnique =
          _selectedTechnique == 'All' || artwork.technique == _selectedTechnique;
      final matchesYear = _selectedYear == 'All' ||
          artwork.createdYear.toString() == _selectedYear;
      final matchesSearch = _searchQuery.isEmpty ||
          artwork.localizedTitle(localeCode).toLowerCase().contains(_searchQuery) ||
          artwork.localizedDescription(localeCode).toLowerCase().contains(_searchQuery) ||
          artwork.technique.toLowerCase().contains(_searchQuery);
      final matchesFavorite = !_onlyFavorites || widget.dataController.isFavorite(artwork.id);
      return matchesTechnique && matchesYear && matchesSearch && matchesFavorite;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1020),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              screenWidth >= 600
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.gallery,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                final artworks = widget.artworks.isNotEmpty
                                    ? widget.artworks
                                    : widget.dataController.artworks;
                                if (artworks.isNotEmpty) {
                                  ArtPuzzleDialog.show(
                                    context,
                                    initialArtwork: artworks.first,
                                    artworks: artworks,
                                    dataController: widget.dataController,
                                  );
                                }
                              },
                              icon: const Icon(Icons.extension_outlined, size: 18, color: Color(0xFF7B5E4B)),
                              label: Text(
                                l10n.artPuzzle,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF1F1F1F),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: const Color(0xFF7B5E4B).withValues(alpha: 0.4)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            if (widget.onOpenVirtualExhibition != null) ...[
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: widget.onOpenVirtualExhibition,
                                icon: const Icon(Icons.view_in_ar_rounded, size: 18, color: Color(0xFFD4AF37)),
                                label: Text(
                                  l10n.virtualExhibition,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF1F1F1F),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: const Color(0xFFD4AF37).withValues(alpha: 0.6)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.gallery,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                final artworks = widget.artworks.isNotEmpty
                                    ? widget.artworks
                                    : widget.dataController.artworks;
                                if (artworks.isNotEmpty) {
                                  ArtPuzzleDialog.show(
                                    context,
                                    initialArtwork: artworks.first,
                                    artworks: artworks,
                                    dataController: widget.dataController,
                                  );
                                }
                              },
                              icon: const Icon(Icons.extension_outlined, size: 18, color: Color(0xFF7B5E4B)),
                              label: Text(
                                l10n.artPuzzle,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF1F1F1F),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: const Color(0xFF7B5E4B).withValues(alpha: 0.4)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            if (widget.onOpenVirtualExhibition != null)
                              OutlinedButton.icon(
                                onPressed: widget.onOpenVirtualExhibition,
                                icon: const Icon(Icons.view_in_ar_rounded, size: 18, color: Color(0xFFD4AF37)),
                                label: Text(
                                  l10n.virtualExhibition,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF1F1F1F),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: const Color(0xFFD4AF37).withValues(alpha: 0.6)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
              const SizedBox(height: 20),
              if (widget.onOpenVirtualExhibition != null) ...[
                _VirtualExhibitionBanner(
                  onTap: widget.onOpenVirtualExhibition!,
                ),
                const SizedBox(height: 24),
              ],
              // View Mode Switcher, Search & Filter controls in responsive Wrap
              Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _GalleryViewModeToggle(
                    currentMode: _viewMode,
                    onChanged: (mode) => setState(() => _viewMode = mode),
                  ),
                  SizedBox(
                    width: screenWidth > 700 ? 280 : double.infinity,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.searchArtworks,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: DropdownButton<String>(
                        value: _selectedTechnique,
                        isDense: true,
                        items: techniques
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t == 'All' ? l10n.allTechniques : t),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedTechnique = val ?? 'All'),
                      ),
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: DropdownButton<String>(
                        value: _selectedYear,
                        isDense: true,
                        items: years
                            .map(
                              (y) => DropdownMenuItem(
                                value: y,
                                child: Text(y == 'All' ? l10n.allYears : y),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedYear = val ?? 'All'),
                      ),
                    ),
                  ),
                  FilterChip(
                    selected: _onlyFavorites,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _onlyFavorites ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: _onlyFavorites
                              ? const Color(0xFFD64550)
                              : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.favoritesWithCount(favCount),
                          style: TextStyle(
                            color: _onlyFavorites
                                ? const Color(0xFFD64550)
                                : const Color(0xFF1F1F1F),
                            fontWeight: _onlyFavorites
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    onSelected: (selected) {
                      HapticFeedback.lightImpact();
                      setState(() => _onlyFavorites = selected);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFFD64550).withValues(alpha: 0.08),
                    side: BorderSide(
                      color: _onlyFavorites
                          ? const Color(0xFFD64550)
                          : Colors.grey.shade400,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ],
              ),
              if (_onlyFavorites && favCount > 0) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.clearFavorites),
                            content: Text(l10n.confirmClearFavorites),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(l10n.cancel),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  await widget.dataController.clearFavorites();
                                },
                                child: Text(l10n.clearFavorites),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_sweep_outlined,
                          size: 16, color: Color(0xFFD64550)),
                      label: Text(
                        l10n.clearFavorites,
                        style: const TextStyle(
                            color: Color(0xFFD64550), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                child: _viewMode == _GalleryViewMode.grid
                    ? (filteredArtworks.isEmpty
                        ? Center(
                            key: const ValueKey('grid_empty'),
                            child: Padding(
                              padding: const EdgeInsets.all(64.0),
                              child: Text(
                                _onlyFavorites
                                    ? l10n.noFavoritesYet
                                    : l10n.noArtworksFound,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _onlyFavorites
                                      ? const Color(0xFF7B5E4B)
                                      : Colors.grey.shade700,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          )
                        : GridView.builder(
                            key: const ValueKey('grid_view'),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: screenWidth > 1000
                                  ? 4
                                  : screenWidth > 700
                                      ? 3
                                      : 2,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 24,
                              childAspectRatio: 0.78,
                            ),
                            itemCount: filteredArtworks.length,
                            itemBuilder: (context, index) {
                              final artwork = filteredArtworks[index];
                              return _FramedArtworkCard(
                                artwork: artwork,
                                dataController: widget.dataController,
                                showSubtitle: true,
                                onTap: () => widget.onArtworkTap(artwork),
                              );
                            },
                          ))
                    : _TimelineView(
                        key: const ValueKey('timeline_view'),
                        artworks: filteredArtworks,
                        dataController: widget.dataController,
                        onArtworkTap: widget.onArtworkTap,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interactive Timeline View grouping artworks chronologically along a visual spine.
class _TimelineView extends StatefulWidget {
  final List<ArtworkModel> artworks;
  final GalleryDataController dataController;
  final ValueChanged<ArtworkModel> onArtworkTap;

  const _TimelineView({
    super.key,
    required this.artworks,
    required this.dataController,
    required this.onArtworkTap,
  });

  @override
  State<_TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<_TimelineView> {
  bool _descending = true;
  final Map<int, GlobalKey> _yearKeys = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    // Group artworks by year
    final Map<int, List<ArtworkModel>> grouped = {};
    for (final artwork in widget.artworks) {
      grouped.putIfAbsent(artwork.createdYear, () => []).add(artwork);
    }

    final sortedYears = grouped.keys.toList()
      ..sort((a, b) => _descending ? b.compareTo(a) : a.compareTo(b));

    // Ensure GlobalKeys exist for each year
    for (final yr in sortedYears) {
      _yearKeys.putIfAbsent(yr, () => GlobalKey());
    }

    if (sortedYears.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(64.0),
          child: Text(
            l10n.noArtworksFound,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Quick Jump Bar & Sorting Toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF9F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF7B5E4B).withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.history_edu_rounded,
                        size: 20,
                        color: Color(0xFF7B5E4B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.creativeJourney,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F1F1F),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _descending = !_descending);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            _descending
                                ? Icons.south_rounded
                                : Icons.north_rounded,
                            size: 14,
                            color: const Color(0xFF7B5E4B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _descending
                                ? '${sortedYears.first} → ${sortedYears.last}'
                                : '${sortedYears.first} → ${sortedYears.last}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF7B5E4B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Horizontal scrollable year quick-jump pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: sortedYears.map((yr) {
                    final count = grouped[yr]!.length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          final key = _yearKeys[yr];
                          if (key?.currentContext != null) {
                            Scrollable.ensureVisible(
                              key!.currentContext!,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF7B5E4B)
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$yr',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF7B5E4B),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7B5E4B),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Vertical Timeline Axis Stream
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedYears.length,
          itemBuilder: (context, yearIndex) {
            final year = sortedYears[yearIndex];
            final yearArtworks = grouped[year]!;
            final techniquesSummary = yearArtworks
                .map((a) => a.technique)
                .toSet()
                .join(' • ');

            return Container(
              key: _yearKeys[year],
              margin: const EdgeInsets.only(bottom: 36),
              child: Stack(
                children: [
                  // Continuous vertical line spine
                  Positioned(
                    left: isDesktop ? 23 : 15,
                    top: 36,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: const Color(0xFFD6B9A5).withValues(alpha: 0.6),
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Milestone Header per Year
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Node Circle Badge
                          Container(
                            width: isDesktop ? 48 : 32,
                            height: isDesktop ? 48 : 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7B5E4B),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD6B9A5),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7B5E4B)
                                      .withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              size: isDesktop ? 20 : 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Year Title & Count Badge
                          Expanded(
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '$year',
                                  style: TextStyle(
                                    fontSize: isDesktop ? 26 : 20,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1F1F1F),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7B5E4B)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF7B5E4B)
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.artworksCount(yearArtworks.length),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF7B5E4B),
                                    ),
                                  ),
                                ),
                                if (techniquesSummary.isNotEmpty)
                                  Text(
                                    techniquesSummary,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Artworks List along the Year Milestone
                      Padding(
                        padding: EdgeInsets.only(left: isDesktop ? 64 : 44),
                        child: Column(
                          children: yearArtworks.map((artwork) {
                            return Padding(
                              padding: EdgeInsets.only(
                                  bottom: isDesktop ? 20.0 : 16.0),
                              child: _EditorialTimelineCard(
                                artwork: artwork,
                                dataController: widget.dataController,
                                onTap: () => widget.onArtworkTap(artwork),
                                localeCode: localeCode,
                                isDesktop: isDesktop,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Editorial framed artwork card for the timeline view.
class _EditorialTimelineCard extends StatelessWidget {
  final ArtworkModel artwork;
  final GalleryDataController dataController;
  final VoidCallback onTap;
  final String localeCode;
  final bool isDesktop;

  const _EditorialTimelineCard({
    required this.artwork,
    required this.dataController,
    required this.onTap,
    required this.localeCode,
    this.isDesktop = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = artwork.localizedTitle(localeCode);
    final desc = artwork.localizedDescription(localeCode);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image framing
                  SizedBox(
                    width: 220,
                    height: 190,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            color: const Color(0xFFFAF9F6),
                            child: artwork.imageUrl.isNotEmpty
                                ? Image.network(
                                    artwork.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) =>
                                        const _ArtworkPlaceholder(height: 190),
                                  )
                                : const _ArtworkPlaceholder(height: 190),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _FavoriteHeartButton(
                            artworkId: artwork.id,
                            dataController: dataController,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Editorial Info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1F1F1F),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7B5E4B)
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${artwork.createdYear}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7B5E4B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${artwork.technique} • ${artwork.dimensions}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF7B5E4B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (desc.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              desc,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.black87,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                AppLocalizations.of(context)!.viewDetails,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF7B5E4B),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: Color(0xFF7B5E4B),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            color: const Color(0xFFFAF9F6),
                            child: artwork.imageUrl.isNotEmpty
                                ? Image.network(
                                    artwork.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) =>
                                        const _ArtworkPlaceholder(height: 200),
                                  )
                                : const _ArtworkPlaceholder(height: 200),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _FavoriteHeartButton(
                            artworkId: artwork.id,
                            dataController: dataController,
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${artwork.createdYear}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F1F1F),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${artwork.technique} • ${artwork.dimensions}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF7B5E4B),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (desc.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            desc,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.black87,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Compact circular heart button overlay for artwork cards.
class _FavoriteHeartButton extends StatelessWidget {
  final String artworkId;
  final GalleryDataController dataController;

  const _FavoriteHeartButton({
    required this.artworkId,
    required this.dataController,
  });

  @override
  Widget build(BuildContext context) {
    final isFav = dataController.isFavorite(artworkId);
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.lightImpact();
          dataController.toggleFavorite(artworkId);
        },
        child: Tooltip(
          message: isFav ? l10n.removeFromFavorites : l10n.addToFavorites,
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              size: 16,
              color: isFav ? const Color(0xFFD64550) : Colors.black45,
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimalist gallery-framed artwork card (mat border & drop shadow).
class _FramedArtworkCard extends StatelessWidget {
  final ArtworkModel artwork;
  final VoidCallback onTap;
  final bool showSubtitle;
  final GalleryDataController dataController;

  const _FramedArtworkCard({
    required this.artwork,
    required this.onTap,
    required this.dataController,
    this.showSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.08),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: artwork.imageUrl.isNotEmpty
                      ? Image.network(
                          artwork.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              const _ArtworkPlaceholder(height: 140),
                        )
                      : const _ArtworkPlaceholder(height: 140),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _FavoriteHeartButton(
                    artworkId: artwork.id,
                    dataController: dataController,
                  ),
                ),
              ],
            ),
          ),
          if (showSubtitle) ...[
            const SizedBox(height: 8),
            Text(
              artwork.localizedTitle(Localizations.localeOf(context).languageCode),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${artwork.technique} • ${artwork.createdYear}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// Artwork Detail Lightbox / Modal Dialog with InteractiveViewer, "View on Wall" & Navigation
class _ArtworkDetailDialog extends StatefulWidget {
  final List<ArtworkModel> artworks;
  final int initialIndex;
  final GalleryDataController dataController;

  const _ArtworkDetailDialog({
    required this.artworks,
    required this.initialIndex,
    required this.dataController,
  });

  @override
  State<_ArtworkDetailDialog> createState() => _ArtworkDetailDialogState();
}

class _ArtworkDetailDialogState extends State<_ArtworkDetailDialog> {
  late int _currentIndex;
  int _activeTab = 0; // 0: Artwork View, 1: View on Wall

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  Widget _buildModeToggle(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFECE6),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _activeTab = 0),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _activeTab == 0 ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                boxShadow: _activeTab == 0
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        )
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 15,
                    color: _activeTab == 0
                        ? const Color(0xFF7B5E4B)
                        : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    l10n.artworkView,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _activeTab == 0
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: _activeTab == 0
                          ? const Color(0xFF7B5E4B)
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _activeTab = 1),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _activeTab == 1 ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                boxShadow: _activeTab == 1
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        )
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.balcony_outlined,
                    size: 15,
                    color: _activeTab == 1
                        ? const Color(0xFF7B5E4B)
                        : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    l10n.viewOnWall,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _activeTab == 1
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: _activeTab == 1
                          ? const Color(0xFF7B5E4B)
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final size = MediaQuery.of(context).size;
    final artwork = widget.artworks[_currentIndex];
    final isCompact = size.width < 580;

    return ListenableBuilder(
      listenable: widget.dataController,
      builder: (context, _) {
        final isFavorite = widget.dataController.isFavorite(artwork.id);

        return Dialog(
          backgroundColor: const Color(0xFFFAF9F6),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Container(
            width: size.width > 900 ? 840 : size.width * 0.95,
            constraints: BoxConstraints(maxHeight: size.height * 0.92),
            child: Column(
              children: [
                // Top action bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
                  child: isCompact
                      ? Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back_ios,
                                          size: 16),
                                      tooltip: l10n.previousArtwork,
                                      onPressed: _currentIndex > 0
                                          ? () => setState(() => _currentIndex--)
                                          : null,
                                    ),
                                    Text(
                                      '${_currentIndex + 1} / ${widget.artworks.length}',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF666666),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.arrow_forward_ios,
                                          size: 16),
                                      tooltip: l10n.nextArtwork,
                                      onPressed: _currentIndex <
                                              widget.artworks.length - 1
                                          ? () => setState(() => _currentIndex++)
                                          : null,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isFavorite
                                            ? const Color(0xFFD64550)
                                            : const Color(0xFF666666),
                                        size: 18,
                                      ),
                                      tooltip: isFavorite
                                          ? l10n.removeFromFavorites
                                          : l10n.addToFavorites,
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        widget.dataController
                                            .toggleFavorite(artwork.id);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.extension_outlined, size: 18, color: Color(0xFF7B5E4B)),
                                      tooltip: l10n.artPuzzle,
                                      onPressed: () {
                                        ArtPuzzleDialog.show(
                                          context,
                                          initialArtwork: artwork,
                                          artworks: widget.artworks,
                                          dataController: widget.dataController,
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.share_outlined,
                                          size: 18),
                                      tooltip: l10n.copyLink,
                                      onPressed: () {
                                        final shareText =
                                            '${l10n.shareArtworkHeader}:\n'
                                            '• ${l10n.title}: ${artwork.localizedTitle(localeCode)}\n'
                                            '• ${l10n.technique}: ${artwork.technique}\n'
                                            '• ${l10n.year}: ${artwork.createdYear}\n'
                                            '• ${l10n.dimensions}: ${artwork.dimensions}\n'
                                            '🔗 ${artwork.imageUrl}';
                                        Clipboard.setData(
                                            ClipboardData(text: shareText));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(l10n.linkCopied)),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20),
                                      tooltip: l10n.close,
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _buildModeToggle(l10n),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                                  tooltip: l10n.previousArtwork,
                                  onPressed: _currentIndex > 0
                                      ? () => setState(() => _currentIndex--)
                                      : null,
                                ),
                                Text(
                                  '${_currentIndex + 1} / ${widget.artworks.length}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF666666),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios,
                                      size: 18),
                                  tooltip: l10n.nextArtwork,
                                  onPressed: _currentIndex <
                                          widget.artworks.length - 1
                                      ? () => setState(() => _currentIndex++)
                                      : null,
                                ),
                              ],
                            ),
                            _buildModeToggle(l10n),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isFavorite
                                        ? const Color(0xFFD64550)
                                        : const Color(0xFF666666),
                                    size: 20,
                                  ),
                                  tooltip: isFavorite
                                      ? l10n.removeFromFavorites
                                      : l10n.addToFavorites,
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    widget.dataController
                                        .toggleFavorite(artwork.id);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.extension_outlined, size: 20, color: Color(0xFF7B5E4B)),
                                  tooltip: l10n.artPuzzle,
                                  onPressed: () {
                                    ArtPuzzleDialog.show(
                                      context,
                                      initialArtwork: artwork,
                                      artworks: widget.artworks,
                                      dataController: widget.dataController,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share_outlined, size: 20),
                                  tooltip: l10n.copyLink,
                                  onPressed: () {
                                    final shareText =
                                        '${l10n.shareArtworkHeader}:\n'
                                        '• ${l10n.title}: ${artwork.localizedTitle(localeCode)}\n'
                                        '• ${l10n.technique}: ${artwork.technique}\n'
                                        '• ${l10n.year}: ${artwork.createdYear}\n'
                                        '• ${l10n.dimensions}: ${artwork.dimensions}\n'
                                        '🔗 ${artwork.imageUrl}';
                                    Clipboard.setData(
                                        ClipboardData(text: shareText));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(l10n.linkCopied)),
                                    );
                                  },
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  tooltip: l10n.close,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
                const Divider(height: 16),

                // Content Area based on selected mode
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _activeTab == 1
                          ? VirtualWallStudio(
                              key: ValueKey('wall_${artwork.id}'),
                              artwork: artwork,
                              isFavorite: isFavorite,
                              onToggleFavorite: () =>
                                  widget.dataController.toggleFavorite(artwork.id),
                            )
                          : SingleChildScrollView(
                              key: ValueKey('details_${artwork.id}'),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxHeight: size.height * 0.45,
                                        maxWidth: 700,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.12),
                                            blurRadius: 18,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: artwork.imageUrl.isNotEmpty
                                          ? InteractiveViewer(
                                              minScale: 0.8,
                                              maxScale: 4.0,
                                              child: Image.network(
                                                artwork.imageUrl,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    const _ArtworkPlaceholder(
                                                        height: 260),
                                              ),
                                            )
                                          : const _ArtworkPlaceholder(height: 260),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          artwork.localizedTitle(localeCode),
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        icon: Icon(
                                          isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: isFavorite
                                              ? const Color(0xFFD64550)
                                              : const Color(0xFF7B5E4B),
                                        ),
                                        tooltip: isFavorite
                                            ? l10n.removeFromFavorites
                                            : l10n.addToFavorites,
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          widget.dataController
                                              .toggleFavorite(artwork.id);
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      OutlinedButton.icon(
                                        onPressed: () =>
                                            setState(() => _activeTab = 1),
                                        icon: const Icon(
                                          Icons.balcony_outlined,
                                          size: 16,
                                        ),
                                        label: Text(l10n.viewOnWall),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF7B5E4B),
                                          side: const BorderSide(
                                            color: Color(0xFF7B5E4B),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 24,
                                    runSpacing: 8,
                                    children: [
                                      Text('${l10n.technique}: ${artwork.technique}'),
                                      Text('${l10n.year}: ${artwork.createdYear}'),
                                      Text('${l10n.dimensions}: ${artwork.dimensions}'),
                                    ],
                                  ),
                                  const Divider(height: 32),
                                  Text(
                                    l10n.storyBehindArtwork,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    artwork.localizedDescription(localeCode),
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(height: 1.6),
                                  ),
                                  const SizedBox(height: 24),
                                  _buildReactionsBar(l10n, artwork),
                                  const Divider(height: 32),
                                  _ArtworkCommentsSection(
                                    artwork: artwork,
                                    dataController: widget.dataController,
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReactionsBar(AppLocalizations l10n, ArtworkModel artwork) {
    const reactionTypes = ['like', 'love', 'magical', 'artistic', 'emotional'];

    IconData getIconForType(String type) {
      switch (type) {
        case 'like':
          return Icons.thumb_up_alt_rounded;
        case 'love':
          return Icons.favorite_rounded;
        case 'magical':
          return Icons.auto_awesome_rounded;
        case 'artistic':
          return Icons.palette_rounded;
        case 'emotional':
          return Icons.sentiment_satisfied_alt_rounded;
        default:
          return Icons.star_rounded;
      }
    }

    String getLabelForType(String type, AppLocalizations l10n) {
      switch (type) {
        case 'like':
          return l10n.reactionLike;
        case 'love':
          return l10n.reactionLove;
        case 'magical':
          return l10n.reactionMagical;
        case 'artistic':
          return l10n.reactionArtistic;
        case 'emotional':
          return l10n.reactionEmotional;
        default:
          return type;
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: reactionTypes.map((type) {
        final count = widget.dataController.getReactionCount(artwork.id, type);
        final hasReacted =
            widget.dataController.hasVisitorReacted(artwork.id, type);

        return Material(
          color: hasReacted
              ? const Color(0xFF7B5E4B).withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              HapticFeedback.lightImpact();
              widget.dataController.toggleReaction(artwork.id, type);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasReacted
                      ? const Color(0xFF7B5E4B)
                      : Colors.black.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    getIconForType(type),
                    size: 16,
                    color: hasReacted
                        ? const Color(0xFF7B5E4B)
                        : const Color(0xFF666666),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    getLabelForType(type, l10n),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          hasReacted ? FontWeight.w600 : FontWeight.normal,
                      color: hasReacted
                          ? const Color(0xFF7B5E4B)
                          : const Color(0xFF4A4A4A),
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: hasReacted
                            ? const Color(0xFF7B5E4B)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color:
                              hasReacted ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Comments Section inside Artwork Details Modal
class _ArtworkCommentsSection extends StatefulWidget {
  final ArtworkModel artwork;
  final GalleryDataController dataController;

  const _ArtworkCommentsSection({
    required this.artwork,
    required this.dataController,
  });

  @override
  State<_ArtworkCommentsSection> createState() =>
      _ArtworkCommentsSectionState();
}

class _ArtworkCommentsSectionState extends State<_ArtworkCommentsSection> {
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();
    final text = _commentController.text.trim();

    if (name.length < 2 || name.length > 50) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.guestbookNameLengthError)),
      );
      return;
    }

    if (text.length < 5 || text.length > 500) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.guestbookMessageLengthError)),
      );
      return;
    }

    if (text.contains('http://') ||
        text.contains('https://') ||
        text.contains('www.')) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.guestbookUrlNotAllowed)),
      );
      return;
    }

    // Cooldown check (30 seconds)
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSub =
          prefs.getInt('last_comment_sub_${widget.artwork.id}') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      const cooldown = 30 * 1000;
      if (now - lastSub < cooldown) {
        final rem = ((cooldown - (now - lastSub)) / 1000).ceil();
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.guestbookCooldownActive(rem.toString()))),
        );
        return;
      }
      await prefs.setInt('last_comment_sub_${widget.artwork.id}', now);
    } catch (_) {}

    setState(() => _isSubmitting = true);
    try {
      await widget.dataController.submitArtworkComment(
        artworkId: widget.artwork.id,
        authorName: name,
        commentText: text,
      );
      _nameController.clear();
      _commentController.clear();
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.commentSubmittedForApproval)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final approvedComments =
        widget.dataController.getApprovedComments(widget.artwork.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.comments,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        approvedComments.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  l10n.noCommentsYet,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: approvedComments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final comment = approvedComments[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              comment.authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF2B2B2B),
                              ),
                            ),
                            Text(
                              '${comment.createdAt.day}.${comment.createdAt.month}.${comment.createdAt.year}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          comment.commentText,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  );
                },
              ),
        const SizedBox(height: 20),
        // Comment submission form
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.leaveComment,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.authorName,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.commentText,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B5E4B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.submit),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// About Artist Tab
class _AboutArtistTab extends StatelessWidget {
  final ArtistProfileModel profile;

  const _AboutArtistTab({required this.profile});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Card(
            elevation: 0,
            color: Colors.white.withValues(alpha: 0.9),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCF7EA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            'assets/branding/logo_iriart.png',
                            height: 48,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const CircleAvatar(
                              radius: 24,
                              backgroundColor: Color(0xFFE7DFD5),
                              child: Icon(Icons.brush, size: 24, color: Color(0xFF5D4B3E)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.localizedArtistName(localeCode),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.localizedArtSchool(localeCode),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 36),
                  Text(
                    l10n.bio,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile.localizedBio(localeCode),
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.favoriteTechniques,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile.localizedFavoriteTechniques(localeCode),
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Guestbook Tab with Submission Form & List of Approved Guestbook Messages
class _GuestbookTab extends StatefulWidget {
  final GalleryDataController dataController;

  const _GuestbookTab({required this.dataController});

  @override
  State<_GuestbookTab> createState() => _GuestbookTabState();
}

class _GuestbookTabState extends State<_GuestbookTab> {
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();
  final _honeypotController = TextEditingController();
  final _captchaController = TextEditingController();
  int _captchaA = 1;
  int _captchaB = 1;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  void _generateCaptcha() {
    final random = Random();
    setState(() {
      _captchaA = random.nextInt(9) + 1; // 1 to 9
      _captchaB = random.nextInt(9) + 1; // 1 to 9
      _captchaController.clear();
    });
  }

  Future<void> _submitMessage(AppLocalizations l10n) async {
    final name = _nameController.text.trim();
    final message = _messageController.text.trim();

    // 1. Hidden honeypot field anti-spam check
    if (_honeypotController.text.trim().isNotEmpty) {
      setState(() => _isSubmitting = true);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.messageSubmittedForApproval)),
        );
        _nameController.clear();
        _messageController.clear();
        _honeypotController.clear();
        _generateCaptcha();
        setState(() => _isSubmitting = false);
      }
      return;
    }

    // 2. Math CAPTCHA verification check
    final userAnswer = int.tryParse(_captchaController.text.trim());
    if (userAnswer == null || userAnswer != (_captchaA + _captchaB)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.captchaError)),
      );
      _generateCaptcha();
      return;
    }

    // 3. Enforce input length limits (2–50 chars for name, 5–500 chars for message)
    if (name.length < 2 || name.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.guestbookNameLengthError)),
      );
      return;
    }
    if (message.length < 5 || message.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.guestbookMessageLengthError)),
      );
      return;
    }

    // 4. Reject messages or names containing URLs (http://, https://, www.)
    final urlRegex = RegExp(r'(http://|https://|www\.)', caseSensitive: false);
    if (urlRegex.hasMatch(message) || urlRegex.hasMatch(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.guestbookUrlNotAllowed)),
      );
      return;
    }

    // 5. Enforce submission cooldown (60 seconds)
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSubMillis = prefs.getInt('last_guestbook_submission_timestamp') ?? 0;
      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      const cooldownMs = 60 * 1000;
      if (nowMillis - lastSubMillis < cooldownMs) {
        final remainingSeconds = ((cooldownMs - (nowMillis - lastSubMillis)) / 1000).ceil();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.guestbookCooldownActive(remainingSeconds.toString()))),
          );
        }
        return;
      }
    } catch (_) {}

    setState(() => _isSubmitting = true);
    try {
      await widget.dataController.submitGuestbookMessage(
        authorName: name,
        message: message,
      );

      // Persist last submission timestamp for cooldown
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('last_guestbook_submission_timestamp', DateTime.now().millisecondsSinceEpoch);
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.messageSubmittedForApproval)),
        );
        _nameController.clear();
        _messageController.clear();
        _honeypotController.clear();
        _generateCaptcha();
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        final errorMessage = (errorStr.contains('429') || errorStr.contains('rate limit') || errorStr.contains('too many'))
            ? l10n.guestbookRateLimitError
            : l10n.errorGeneric(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    _honeypotController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final approvedEntries = widget.dataController.approvedGuestbookEntries;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              Card(
                elevation: 0,
                color: Colors.white.withValues(alpha: 0.9),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.leaveAMessage,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Hidden honeypot field to trap bots
                      Offstage(
                        offstage: true,
                        child: TextFormField(
                          controller: _honeypotController,
                          decoration: const InputDecoration(
                            labelText: 'Website (leave blank)',
                          ),
                        ),
                      ),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n.authorName,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _messageController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: l10n.message,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Math CAPTCHA verification challenge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.captchaQuestion(_captchaA, _captchaB),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF7B5E4B),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            tooltip: l10n.refresh,
                            onPressed: _generateCaptcha,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _captchaController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.captchaAnswerHint,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isSubmitting ? null : () => _submitMessage(l10n),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send_outlined, size: 18),
                          label: Text(l10n.submit),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF7B5E4B),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.approvedMessages,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (approvedEntries.isEmpty)
                Card(
                  elevation: 0,
                  color: Colors.white.withValues(alpha: 0.85),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        l10n.noApprovedGuestbookEntries,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: approvedEntries.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = approvedEntries[index];
                    return Card(
                      elevation: 0,
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.authorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '${item.createdAt.year}-${item.createdAt.month.toString().padLeft(2, '0')}-${item.createdAt.day.toString().padLeft(2, '0')}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.message,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Elegant 360° Virtual Exhibition Entry Card inside Gallery tab
class _VirtualExhibitionBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _VirtualExhibitionBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 640;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1B1C22),
            Color(0xFF2D303A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Icon(
                              Icons.view_in_ar_rounded,
                              color: Color(0xFFD4AF37),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.virtualExhibition,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.virtualExhibitionSubtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                          label: Text(l10n.enterVirtualExhibition),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.view_in_ar_rounded,
                          color: Color(0xFFD4AF37),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.virtualExhibition,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.virtualExhibitionSubtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: Text(l10n.enterVirtualExhibition),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
