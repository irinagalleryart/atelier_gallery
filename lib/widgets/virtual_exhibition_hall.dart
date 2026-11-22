import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/gallery_data_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/atelier_models.dart';

/// Room atmosphere themes available in the modern 360° Virtual Exhibition.
enum GalleryRoomTheme {
  brightModern,
  watercolorAtelier,
  softEvening,
}

extension GalleryRoomThemeX on GalleryRoomTheme {
  String label(AppLocalizations l10n) {
    switch (this) {
      case GalleryRoomTheme.brightModern:
        return l10n.roomThemeBright;
      case GalleryRoomTheme.watercolorAtelier:
        return l10n.roomThemeAtelier;
      case GalleryRoomTheme.softEvening:
        return l10n.roomThemeEvening;
    }
  }

  Color get wallTopColor {
    switch (this) {
      case GalleryRoomTheme.brightModern:
        return const Color(0xFFFAFBFD);
      case GalleryRoomTheme.watercolorAtelier:
        return const Color(0xFFF7F8FA);
      case GalleryRoomTheme.softEvening:
        return const Color(0xFFF1F5F9); // Calm modern blue-grey off-white
    }
  }

  Color get wallBottomColor {
    switch (this) {
      case GalleryRoomTheme.brightModern:
        return const Color(0xFFECEFF4);
      case GalleryRoomTheme.watercolorAtelier:
        return const Color(0xFFE7ECF2);
      case GalleryRoomTheme.softEvening:
        return const Color(0xFFDCE5EE); // Soft slate blue-grey wall base
    }
  }

  Color get floorColor1 {
    switch (this) {
      case GalleryRoomTheme.brightModern:
        return const Color(0xFFD5DCE4);
      case GalleryRoomTheme.watercolorAtelier:
        return const Color(0xFFD0D8E2);
      case GalleryRoomTheme.softEvening:
        return const Color(0xFFC3D0DE); // Smooth polished blue-grey floor
    }
  }

  Color get floorColor2 {
    switch (this) {
      case GalleryRoomTheme.brightModern:
        return const Color(0xFFB4C0CE);
      case GalleryRoomTheme.watercolorAtelier:
        return const Color(0xFFAFBBD0);
      case GalleryRoomTheme.softEvening:
        return const Color(0xFF9EB0C4); // Deeper microcement blue-grey front
    }
  }

  Color get reflectionColor {
    switch (this) {
      case GalleryRoomTheme.brightModern:
        return const Color(0xFF7B8FA6);
      case GalleryRoomTheme.watercolorAtelier:
        return const Color(0xFF768BA3);
      case GalleryRoomTheme.softEvening:
        return const Color(0xFF5D7691);
    }
  }
}

/// Modernized 360° Virtual Exhibition Hall widget.
class VirtualExhibitionHall extends StatefulWidget {
  final List<ArtworkModel> artworks;
  final ValueChanged<ArtworkModel> onArtworkTap;
  final VoidCallback? onClose;
  final GalleryDataController? dataController;

  const VirtualExhibitionHall({
    super.key,
    required this.artworks,
    required this.onArtworkTap,
    this.onClose,
    this.dataController,
  });

  @override
  State<VirtualExhibitionHall> createState() => _VirtualExhibitionHallState();
}

class _VirtualExhibitionHallState extends State<VirtualExhibitionHall>
    with SingleTickerProviderStateMixin {
  double _yawAngle = 0.0; // Camera rotation angle in radians [0, 2*pi]
  double _zoomDistance = 1.0; // Room zoom / distance depth
  GalleryRoomTheme _currentTheme = GalleryRoomTheme.softEvening;
  bool _showGalleryLights = true;
  ArtworkModel? _selectedArtwork;
  ArtworkModel? _hoveredArtwork;
  bool _userDismissedCard = false;
  double _yawAtDismiss = 0.0;

  late AnimationController _animController;
  Animation<double>? _yawAnimation;
  Animation<double>? _zoomAnimation;

  ArtworkModel? _getClosestCenteredArtwork() {
    if (_userDismissedCard) {
      if ((_yawAngle - _yawAtDismiss).abs() > 0.35) {
        _userDismissedCard = false;
      } else {
        return null;
      }
    }
    final artworks = widget.artworks;
    if (artworks.isEmpty) return null;
    ArtworkModel best = artworks.first;
    double minDiff = double.infinity;
    final count = artworks.length;
    for (int i = 0; i < count; i++) {
      final artwork = artworks[i];
      final double baseAngle = (i * 2 * math.pi) / count;
      double diff = (baseAngle - _yawAngle).abs();
      while (diff > math.pi) {
        diff = (diff - 2 * math.pi).abs();
      }
      if (diff < minDiff) {
        minDiff = diff;
        best = artwork;
      }
    }
    if (minDiff < 0.65) {
      return best;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..addListener(() {
        setState(() {
          if (_yawAnimation != null) {
            _yawAngle = _yawAnimation!.value;
          }
          if (_zoomAnimation != null) {
            _zoomDistance = _zoomAnimation!.value;
          }
          _selectedArtwork = _getClosestCenteredArtwork();
        });
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _selectedArtwork = _getClosestCenteredArtwork();
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _animateTo({double? targetYaw, double? targetZoom}) {
    final startYaw = _yawAngle;
    final startZoom = _zoomDistance;
    final endYaw = targetYaw ?? _yawAngle;
    final endZoom = targetZoom ?? _zoomDistance;

    _yawAnimation = targetYaw != null
        ? Tween<double>(begin: startYaw, end: endYaw).animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
          )
        : null;

    _zoomAnimation = targetZoom != null
        ? Tween<double>(begin: startZoom, end: endZoom).animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
          )
        : null;

    _animController.forward(from: 0.0);
  }

  void _stepLook(bool lookRight) {
    final step = math.pi / 4; // 45 degrees
    _animateTo(targetYaw: _yawAngle + (lookRight ? step : -step));
  }

  void _resetView() {
    _animateTo(targetYaw: 0.0, targetZoom: 1.0);
  }

  void _stepCloser() {
    final newZoom = math.min(1.4, _zoomDistance + 0.18);
    _animateTo(targetZoom: newZoom);
  }

  void _stepBack() {
    final newZoom = math.max(0.75, _zoomDistance - 0.18);
    _animateTo(targetZoom: newZoom);
  }

  void _cycleTheme() {
    setState(() {
      final themes = GalleryRoomTheme.values;
      final nextIndex = (_currentTheme.index + 1) % themes.length;
      _currentTheme = themes[nextIndex];
    });
  }

  String _getWallLabel(AppLocalizations l10n) {
    double norm = _yawAngle % (2 * math.pi);
    if (norm < 0) norm += 2 * math.pi;

    if (norm >= 7 * math.pi / 4 || norm < math.pi / 4) {
      return l10n.wallCenter;
    } else if (norm >= math.pi / 4 && norm < 3 * math.pi / 4) {
      return l10n.wallRight;
    } else if (norm >= 3 * math.pi / 4 && norm < 5 * math.pi / 4) {
      return l10n.wallBack;
    } else {
      return l10n.wallLeft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 600;
    const accentSlate = Color(0xFF3B6E8C);
    const warmBulbAccent = Color(0xFFD99B26);

    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      body: SafeArea(
        child: ClipRect(
          child: Stack(
            children: [
              // 1. Modern Bright Architectural Gallery Room Background Stage
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _yawAngle -= details.delta.dx * 0.0035;
                      _selectedArtwork = _getClosestCenteredArtwork();
                    });
                  },
                  child: CustomPaint(
                    size: size,
                    painter: _ModernGalleryRoomPainter(
                      yawAngle: _yawAngle,
                      zoomDistance: _zoomDistance,
                      roomTheme: _currentTheme,
                    ),
                  ),
                ),
              ),

              // 2. Multiple Artworks, Floor Reflections & Centered Picture Lights
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: _buildArtworkWidgets(constraints, localeCode, isCompact),
                    );
                  },
                ),
              ),

              // 3. Top Header Bar (Responsive for mobile vs desktop)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: isCompact
                    ? Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildGlassPill(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.view_in_ar_rounded,
                                          color: accentSlate,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getWallLabel(l10n),
                                          style: const TextStyle(
                                            color: Color(0xFF1E293B),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: _cycleTheme,
                                    borderRadius: BorderRadius.circular(20),
                                    child: _buildGlassPill(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 5,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.palette_outlined,
                                            color: accentSlate,
                                            size: 13,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _currentTheme.label(l10n),
                                            style: const TextStyle(
                                              color: Color(0xFF334155),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Tooltip(
                                    message: l10n.galleryLights,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _showGalleryLights = !_showGalleryLights;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _showGalleryLights
                                              ? const Color(0xFFFFFBEB)
                                              : Colors.white.withValues(alpha: 0.92),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: _showGalleryLights
                                                ? warmBulbAccent
                                                : Colors.grey.shade300,
                                            width: _showGalleryLights ? 1.3 : 1.0,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.08),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          _showGalleryLights
                                              ? Icons.lightbulb
                                              : Icons.lightbulb_outline,
                                          color: _showGalleryLights
                                              ? warmBulbAccent
                                              : Colors.grey.shade500,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: const CircleBorder(),
                            elevation: 2,
                            shadowColor: Colors.black26,
                            child: SizedBox(
                              width: 34,
                              height: 34,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.close,
                                  color: Color(0xFF1E293B),
                                  size: 17,
                                ),
                                tooltip: l10n.close,
                                onPressed: widget.onClose ??
                                    () => Navigator.of(context).maybePop(),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildGlassPill(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.view_in_ar_rounded,
                                          color: accentSlate,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _getWallLabel(l10n),
                                          style: const TextStyle(
                                            color: Color(0xFF1E293B),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: _cycleTheme,
                                    borderRadius: BorderRadius.circular(20),
                                    child: _buildGlassPill(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.palette_outlined,
                                            color: accentSlate,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _currentTheme.label(l10n),
                                            style: const TextStyle(
                                              color: Color(0xFF334155),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _showGalleryLights = !_showGalleryLights;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _showGalleryLights
                                            ? const Color(0xFFFFFBEB)
                                            : Colors.white.withValues(alpha: 0.92),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _showGalleryLights
                                              ? warmBulbAccent
                                              : Colors.grey.shade300,
                                          width: _showGalleryLights ? 1.3 : 1.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _showGalleryLights
                                                ? Icons.lightbulb
                                                : Icons.lightbulb_outline,
                                            color: _showGalleryLights
                                                ? warmBulbAccent
                                                : Colors.grey.shade500,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            l10n.galleryLights,
                                            style: TextStyle(
                                              color: _showGalleryLights
                                                  ? const Color(0xFF1E293B)
                                                  : Colors.grey.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Material(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: const CircleBorder(),
                            elevation: 2,
                            shadowColor: Colors.black26,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Color(0xFF1E293B),
                                size: 20,
                              ),
                              tooltip: l10n.close,
                              onPressed: widget.onClose ??
                                  () => Navigator.of(context).maybePop(),
                            ),
                          ),
                        ],
                      ),
              ),

              // 4. Bottom Floating Glass Controls Bar (Single row on compact screens)
              Positioned(
                bottom: _selectedArtwork != null ? 100 : 20,
                left: isCompact ? 8 : 16,
                right: isCompact ? 8 : 16,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 2 : 12,
                      vertical: isCompact ? 4 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: isCompact
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 26,
                                height: 30,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.arrow_back_ios_rounded,
                                    size: 13,
                                  ),
                                  color: const Color(0xFF334155),
                                  tooltip: l10n.lookLeft,
                                  onPressed: () => _stepLook(false),
                                ),
                              ),
                              Tooltip(
                                message: l10n.stepCloser,
                                child: TextButton.icon(
                                  onPressed: _stepCloser,
                                  icon: const Icon(
                                    Icons.zoom_in,
                                    size: 14,
                                    color: accentSlate,
                                  ),
                                  label: Text(
                                    l10n.stepCloser,
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF334155),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 2,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                              Tooltip(
                                message: l10n.resetView,
                                child: TextButton.icon(
                                  onPressed: _resetView,
                                  icon: const Icon(
                                    Icons.center_focus_strong,
                                    size: 14,
                                    color: accentSlate,
                                  ),
                                  label: Text(
                                    l10n.resetView,
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF1E293B),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 2,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                              Tooltip(
                                message: l10n.stepBack,
                                child: TextButton.icon(
                                  onPressed: _stepBack,
                                  icon: const Icon(
                                    Icons.zoom_out,
                                    size: 14,
                                    color: accentSlate,
                                  ),
                                  label: Text(
                                    l10n.stepBack,
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF334155),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 2,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 26,
                                height: 30,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 13,
                                  ),
                                  color: const Color(0xFF334155),
                                  tooltip: l10n.lookRight,
                                  onPressed: () => _stepLook(true),
                                ),
                              ),
                            ],
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_rounded,
                                  size: 16,
                                ),
                                color: const Color(0xFF334155),
                                tooltip: l10n.lookLeft,
                                onPressed: () => _stepLook(false),
                              ),
                              TextButton.icon(
                                onPressed: _stepCloser,
                                icon: const Icon(
                                  Icons.zoom_in,
                                  size: 16,
                                  color: accentSlate,
                                ),
                                label: Text(
                                  l10n.stepCloser,
                                  style: const TextStyle(
                                    color: Color(0xFF334155),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _resetView,
                                icon: const Icon(
                                  Icons.center_focus_strong,
                                  size: 16,
                                  color: accentSlate,
                                ),
                                label: Text(
                                  l10n.resetView,
                                  style: const TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _stepBack,
                                icon: const Icon(
                                  Icons.zoom_out,
                                  size: 16,
                                  color: accentSlate,
                                ),
                                label: Text(
                                  l10n.stepBack,
                                  style: const TextStyle(
                                    color: Color(0xFF334155),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                ),
                                color: const Color(0xFF334155),
                                tooltip: l10n.lookRight,
                                onPressed: () => _stepLook(true),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              // 5. Selected Artwork Floating Card
              if (_selectedArtwork != null)
                Positioned(
                  bottom: 16,
                  left: isCompact ? 12 : (size.width - 480) / 2,
                  right: isCompact ? 12 : null,
                  child: widget.dataController != null
                      ? ListenableBuilder(
                          listenable: widget.dataController!,
                          builder: (context, _) {
                            final isFav = widget.dataController!
                                .isFavorite(_selectedArtwork!.id);
                            return _SelectedArtworkCard(
                              artwork: _selectedArtwork!,
                              localeCode: localeCode,
                              isFavorite: isFav,
                              isCompact: isCompact,
                              onToggleFavorite: () {
                                widget.dataController!
                                    .toggleFavorite(_selectedArtwork!.id);
                              },
                              onInspect: () {
                                final art = _selectedArtwork!;
                                widget.onArtworkTap(art);
                              },
                              onDismiss: () {
                                setState(() {
                                  _userDismissedCard = true;
                                  _yawAtDismiss = _yawAngle;
                                  _selectedArtwork = null;
                                });
                              },
                            );
                          },
                        )
                      : _SelectedArtworkCard(
                          artwork: _selectedArtwork!,
                          localeCode: localeCode,
                          isCompact: isCompact,
                          onInspect: () {
                            final art = _selectedArtwork!;
                            widget.onArtworkTap(art);
                          },
                          onDismiss: () {
                            setState(() {
                              _userDismissedCard = true;
                              _yawAtDismiss = _yawAngle;
                              _selectedArtwork = null;
                            });
                          },
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassPill({
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Builds multiple visible artworks and centered picture lights along walls.
  /// Positions are locked so toggling gallery lights never shifts the artwork or fixture.
  List<Widget> _buildArtworkWidgets(
    BoxConstraints constraints,
    String localeCode,
    bool isCompact,
  ) {
    final artworks = widget.artworks;
    if (artworks.isEmpty) return [];

    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final centerX = width / 2;
    final double floorTopY = height * 0.73;

    final List<Widget> widgets = [];
    final int count = artworks.length;

    for (int i = 0; i < count; i++) {
      final artwork = artworks[i];
      final double baseAngle = (i * 2 * math.pi) / count;

      double diffAngle = baseAngle - _yawAngle;
      while (diffAngle > math.pi) {
        diffAngle -= 2 * math.pi;
      }
      while (diffAngle < -math.pi) {
        diffAngle += 2 * math.pi;
      }

      if (diffAngle.abs() < 1.55) {
        final double screenX =
            centerX + diffAngle * (isCompact ? width * 0.88 : width * 0.68) * _zoomDistance;
        final double depthFactor = math.cos(diffAngle);
        final double scale = (isCompact ? (0.70 + 0.30 * depthFactor) : (0.76 + 0.32 * depthFactor)) * _zoomDistance;
        final double opacity = (1.0 - (diffAngle.abs() / 1.55)).clamp(0.0, 1.0);
        final double lightIntensity =
            (1.0 - (diffAngle.abs() / 1.55)).clamp(0.35, 1.0);

        final double baseCardW = width > 700 ? 255.0 : (isCompact ? 138.0 : 196.0);
        final double cardW = baseCardW * scale;
        final double cardH = cardW * 1.24;
        final double lightW = math.max(isCompact ? 90.0 : 116.0, cardW * 0.86);
        final double fixtureH = (isCompact ? 22.0 : 26.0) * scale;
        const double gapAboveFrame = 6.0;

        final double frameBottomY =
            math.min(floorTopY - 24.0 * scale, height * 0.63);
        final double cardTopY = frameBottomY - cardH;
        final double blockTopY = cardTopY - gapAboveFrame - fixtureH;

        final bool isSelected = _selectedArtwork?.id == artwork.id;
        final bool isHovered = _hoveredArtwork?.id == artwork.id;

        // Soft floor reflection beneath each visible artwork
        widgets.add(
          Positioned(
            left: screenX - (cardW * 0.44),
            top: floorTopY + 2,
            child: IgnorePointer(
              child: Opacity(
                opacity: (opacity * 0.24 * depthFactor).clamp(0.0, 0.28),
                child: Container(
                  width: cardW * 0.88,
                  height: math.min(64.0, (height - floorTopY) * 0.52),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _currentTheme.reflectionColor.withValues(alpha: 0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        final double coneW = lightW * 1.8;
        final double coneH = math.min(90.0 * scale, math.max(24.0, cardTopY - (blockTopY + fixtureH)));

        // Downward warm light cone wash painted cleanly in its own bounded box
        widgets.add(
          Positioned(
            left: screenX - (coneW / 2),
            top: blockTopY + fixtureH - 1,
            width: coneW,
            height: coneH,
            child: IgnorePointer(
              child: Opacity(
                opacity: (opacity * (_showGalleryLights ? 1.0 : 0.0)).clamp(0.0, 1.0),
                child: CustomPaint(
                  size: Size(coneW, coneH),
                  painter: _LightConePainter(intensity: lightIntensity),
                ),
              ),
            ),
          ),
        );

        // Picture light fixture locked directly above the artwork frame
        widgets.add(
          Positioned(
            left: screenX - (lightW / 2),
            top: blockTopY,
            width: lightW,
            height: fixtureH,
            child: IgnorePointer(
              child: Opacity(
                opacity: opacity,
                child: _GalleryPictureLight(
                  width: lightW,
                  scale: scale,
                  intensity: lightIntensity,
                  enabled: _showGalleryLights,
                ),
              ),
            ),
          ),
        );

        // Framed artwork card with explicit bounded height (no Column overflow)
        widgets.add(
          Positioned(
            left: screenX - (cardW / 2),
            top: cardTopY,
            width: cardW,
            height: cardH,
            child: Opacity(
              opacity: opacity,
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoveredArtwork = artwork),
                onExit: (_) => setState(() => _hoveredArtwork = null),
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _userDismissedCard = false;
                      _selectedArtwork = artwork;
                    });
                    widget.onArtworkTap(artwork);
                  },
                  child: Container(
                    width: cardW,
                    height: cardH,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF3B6E8C)
                            : (isHovered
                                ? const Color(0xFF7C8B99)
                                : const Color(0xFFCBD5E1)),
                        width: isSelected ? 3.0 : (isHovered ? 2.0 : 1.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isSelected ? 0.24 : 0.14,
                          ),
                          blurRadius: isSelected ? 22 : 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.fromLTRB(
                              isCompact ? 8 : 10,
                              isCompact ? 8 : 10,
                              isCompact ? 8 : 10,
                              isCompact ? 4 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 0.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: artwork.imageUrl.isNotEmpty
                                  ? Image.network(
                                      artwork.imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (_, __, ___) =>
                                          const Center(
                                        child: Icon(
                                          Icons.palette_outlined,
                                          size: 32,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.palette_outlined,
                                        size: 32,
                                        color: Colors.grey,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            isCompact ? 6 : 10,
                            0,
                            isCompact ? 6 : 10,
                            isCompact ? 6 : 8,
                          ),
                          child: Text(
                            artwork.localizedTitle(localeCode),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF1E293B),
                              fontWeight: FontWeight.w600,
                              fontSize: isCompact ? 10 : (cardW > 230 ? 13 : 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }
}

/// Museum-style picture light mounted directly centered above each framed artwork.
class _GalleryPictureLight extends StatelessWidget {
  final double width;
  final double scale;
  final double intensity;
  final bool enabled;

  const _GalleryPictureLight({
    required this.width,
    required this.scale,
    required this.intensity,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final double fixtureH = 26.0 * scale;

    return SizedBox(
      width: width,
      height: fixtureH,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 3.0 * scale,
            height: 16.0 * scale,
            color: const Color(0xFF334155),
          ),
          Container(
            width: width,
            height: 7.5 * scale,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: const Color(0xFF64748B),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFEE99).withValues(
                    alpha: enabled ? (0.55 * intensity) : 0.0,
                  ),
                  blurRadius: 12 * scale,
                  spreadRadius: 2.0 * scale,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LightConePainter extends CustomPainter {
  final double intensity;

  _LightConePainter({required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        [
          const Color(0xFFFFF7D6).withValues(alpha: (0.36 * intensity).clamp(0.0, 1.0)),
          const Color(0xFFFFEE99).withValues(alpha: (0.12 * intensity).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
        [0.0, 0.45, 1.0],
      );

    final path = Path()
      ..moveTo(size.width / 2 - 12, 0)
      ..lineTo(size.width / 2 + 12, 0)
      ..lineTo(size.width * 0.92, size.height)
      ..lineTo(size.width * 0.08, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LightConePainter oldDelegate) {
    return oldDelegate.intensity != intensity;
  }
}

/// Floating Card shown when an artwork is tapped.
class _SelectedArtworkCard extends StatelessWidget {
  final ArtworkModel artwork;
  final String localeCode;
  final VoidCallback onInspect;
  final VoidCallback onDismiss;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final bool isCompact;

  const _SelectedArtworkCard({
    required this.artwork,
    required this.localeCode,
    required this.onInspect,
    required this.onDismiss,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const accentSlate = Color(0xFF3B6E8C);

    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 16,
        vertical: isCompact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentSlate, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              artwork.imageUrl,
              width: isCompact ? 42 : 52,
              height: isCompact ? 42 : 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: isCompact ? 42 : 52,
                height: isCompact ? 42 : 52,
                color: Colors.grey.shade200,
                child: const Icon(Icons.palette, color: Colors.grey, size: 20),
              ),
            ),
          ),
          SizedBox(width: isCompact ? 8 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  artwork.localizedTitle(localeCode),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                    fontSize: isCompact ? 12 : 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${artwork.technique} • ${artwork.createdYear}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: isCompact ? 10.5 : 12,
                  ),
                ),
              ],
            ),
          ),
          if (onToggleFavorite != null) ...[
            const SizedBox(width: 2),
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? const Color(0xFFD64550) : Colors.grey.shade600,
                size: isCompact ? 18 : 20,
              ),
              tooltip: isFavorite
                  ? l10n.removeFromFavorites
                  : l10n.addToFavorites,
              onPressed: () {
                HapticFeedback.lightImpact();
                onToggleFavorite!();
              },
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
          SizedBox(width: isCompact ? 4 : 8),
          ElevatedButton.icon(
            onPressed: onInspect,
            icon: Icon(Icons.visibility_outlined, size: isCompact ? 14 : 16),
            label: Text(l10n.viewDetails),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentSlate,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 14,
                vertical: isCompact ? 6 : 10,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isCompact ? 10.5 : 12,
              ),
            ),
          ),
          SizedBox(width: isCompact ? 2 : 4),
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey, size: isCompact ? 16 : 18),
            onPressed: onDismiss,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter rendering a smooth, contemporary architectural gallery room
/// with a seamless wall, ceiling light strip, clean baseboard, and natural floor.
class _ModernGalleryRoomPainter extends CustomPainter {
  final double yawAngle;
  final double zoomDistance;
  final GalleryRoomTheme roomTheme;

  _ModernGalleryRoomPainter({
    required this.yawAngle,
    required this.zoomDistance,
    required this.roomTheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final cx = width / 2;
    final double floorTopY = height * 0.73;

    // 1. Seamless Smooth Gallery Wall Gradient (no harsh vertical panel seams)
    final wallPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(cx, 0),
        Offset(cx, floorTopY),
        [roomTheme.wallTopColor, roomTheme.wallBottomColor],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, width, floorTopY), wallPaint);

    // Subtle soft ambient wall tone shift with yaw for depth without grid lines
    final double shiftX = -yawAngle * (width * 0.25) * zoomDistance;
    final softWashPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx + (shiftX % (width * 0.8)), floorTopY * 0.42),
        width * 0.55,
        [
          Colors.white.withValues(alpha: 0.28),
          Colors.transparent,
        ],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, width, floorTopY), softWashPaint);

    // 2. Refined Architectural Ceiling Cove / Track Strip
    const double ceilingH = 38.0;
    final ceilingPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(cx, 0),
        Offset(cx, ceilingH),
        const [Color(0xFF1E293B), Color(0xFF334155)],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, width, ceilingH), ceilingPaint);

    final coveGlow = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
    canvas.drawRect(Rect.fromLTWH(0, ceilingH - 2, width, 5), coveGlow);

    // 3. Natural Polished Gallery Floor (Microcement / Stone without CAD grid lines)
    final floorRect = Rect.fromLTWH(0, floorTopY, width, height - floorTopY);
    final floorPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(cx, floorTopY),
        Offset(cx, height),
        [roomTheme.floorColor1, roomTheme.floorColor2],
        [0.0, 1.0],
      );
    canvas.drawRect(floorRect, floorPaint);

    // Soft overhead light sheen across the center of the floor
    final floorSheen = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx, floorTopY + (height - floorTopY) * 0.25),
        width * 0.5,
        [
          Colors.white.withValues(alpha: 0.22),
          Colors.transparent,
        ],
      );
    canvas.drawRect(floorRect, floorSheen);

    // Clean baseboard trim & subtle contact shadow along wall-floor seam
    final contactShadow = Paint()
      ..shader = ui.Gradient.linear(
        Offset(cx, floorTopY),
        Offset(cx, floorTopY + 24),
        [
          roomTheme.reflectionColor.withValues(alpha: 0.24),
          Colors.transparent,
        ],
      );
    canvas.drawRect(Rect.fromLTWH(0, floorTopY, width, 24), contactShadow);

    canvas.drawLine(
      Offset(0, floorTopY),
      Offset(width, floorTopY),
      Paint()
        ..color = roomTheme.reflectionColor.withValues(alpha: 0.38)
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_ModernGalleryRoomPainter oldDelegate) {
    return oldDelegate.yawAngle != yawAngle ||
        oldDelegate.zoomDistance != zoomDistance ||
        oldDelegate.roomTheme != roomTheme;
  }
}
