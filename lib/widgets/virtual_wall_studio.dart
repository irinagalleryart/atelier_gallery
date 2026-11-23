import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../models/atelier_models.dart';

/// Available frame styles in the Virtual Wall & Frame Studio.
enum VirtualFrameStyle { none, oak, white, gold }

/// Available wall colors in the Virtual Wall & Frame Studio.
enum VirtualWallColor { galleryOffWhite, softSage, warmSand, pastelSky }

/// Helper to parse artwork dimensions in centimeters (e.g. "70 x 90 cm").
class ArtworkDimensions {
  final double widthCm;
  final double heightCm;

  const ArtworkDimensions(this.widthCm, this.heightCm);

  double get aspectRatio =>
      (widthCm > 0 && heightCm > 0) ? (widthCm / heightCm) : 1.0;

  static ArtworkDimensions? parse(String dimensionsStr) {
    if (dimensionsStr.trim().isEmpty) return null;
    final regExp =
        RegExp(r'(\d+(?:\.\d+)?)\s*x\s*(\d+(?:\.\d+)?)', caseSensitive: false);
    final match = regExp.firstMatch(dimensionsStr);
    if (match != null) {
      final w = double.tryParse(match.group(1) ?? '');
      final h = double.tryParse(match.group(2) ?? '');
      if (w != null && h != null && w > 0 && h > 0) {
        return ArtworkDimensions(w, h);
      }
    }
    return null;
  }
}

extension VirtualWallColorX on VirtualWallColor {
  Color get color {
    switch (this) {
      case VirtualWallColor.galleryOffWhite:
        return const Color(0xFFF4F1EA);
      case VirtualWallColor.softSage:
        return const Color(0xFFDEE5DD);
      case VirtualWallColor.warmSand:
        return const Color(0xFFEBE0D2);
      case VirtualWallColor.pastelSky:
        return const Color(0xFFDFE7ED);
    }
  }

  Color get shadowAccent {
    switch (this) {
      case VirtualWallColor.galleryOffWhite:
        return const Color(0xFFE0D8C8);
      case VirtualWallColor.softSage:
        return const Color(0xFFC3D0C1);
      case VirtualWallColor.warmSand:
        return const Color(0xFFD4C3AE);
      case VirtualWallColor.pastelSky:
        return const Color(0xFFC5D4E0);
    }
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case VirtualWallColor.galleryOffWhite:
        return l10n.wallGalleryOffWhite;
      case VirtualWallColor.softSage:
        return l10n.wallSoftSage;
      case VirtualWallColor.warmSand:
        return l10n.wallWarmSand;
      case VirtualWallColor.pastelSky:
        return l10n.wallPastelSky;
    }
  }
}

extension VirtualFrameStyleX on VirtualFrameStyle {
  String label(AppLocalizations l10n) {
    switch (this) {
      case VirtualFrameStyle.none:
        return l10n.frameNone;
      case VirtualFrameStyle.oak:
        return l10n.frameOak;
      case VirtualFrameStyle.white:
        return l10n.frameWhite;
      case VirtualFrameStyle.gold:
        return l10n.frameGold;
    }
  }
}

/// Virtual Wall & Frame Studio interactive widget.
class VirtualWallStudio extends StatefulWidget {
  final ArtworkModel artwork;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  const VirtualWallStudio({
    super.key,
    required this.artwork,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  @override
  State<VirtualWallStudio> createState() => _VirtualWallStudioState();
}

class _VirtualWallStudioState extends State<VirtualWallStudio> {
  VirtualFrameStyle _selectedFrame = VirtualFrameStyle.oak;
  VirtualWallColor _selectedWallColor = VirtualWallColor.galleryOffWhite;
  bool _hasPassePartout = true;

  double? _naturalAspectRatio;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;

  @override
  void initState() {
    super.initState();
    _resolveImageAspectRatio();
  }

  @override
  void didUpdateWidget(covariant VirtualWallStudio oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artwork.imageUrl != widget.artwork.imageUrl) {
      _naturalAspectRatio = null;
      _resolveImageAspectRatio();
    }
  }

  @override
  void dispose() {
    _removeImageStreamListener();
    super.dispose();
  }

  void _removeImageStreamListener() {
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
    }
    _imageStream = null;
    _imageStreamListener = null;
  }

  void _resolveImageAspectRatio() {
    _removeImageStreamListener();
    final url = widget.artwork.imageUrl.trim();
    if (url.isEmpty) return;

    final provider = NetworkImage(url);
    final stream = provider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        final w = info.image.width.toDouble();
        final h = info.image.height.toDouble();
        if (w > 0 && h > 0 && mounted) {
          final ratio = w / h;
          if (_naturalAspectRatio == null ||
              (_naturalAspectRatio! - ratio).abs() > 0.01) {
            setState(() => _naturalAspectRatio = ratio);
          }
        }
      },
      onError: (_, __) {},
    );

    _imageStream = stream;
    _imageStreamListener = listener;
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isNarrow = size.width < 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        final roomWidth = constraints.maxWidth;
        final roomHeight = isNarrow ? 250.0 : 330.0;

        // Prefer real loaded image orientation so horizontal/landscape paintings
        // always get a horizontal frame matching the actual artwork.
        final parsedDim = ArtworkDimensions.parse(widget.artwork.dimensions);
        final effectiveAspectRatio = (_naturalAspectRatio ??
                parsedDim?.aspectRatio ??
                1.0)
            .clamp(0.45, 2.4);

        final isLandscape = effectiveAspectRatio > 1.05;

        // Size artwork cleanly on the wall based on orientation and physical size
        final baseHeight = isLandscape ? roomHeight * 0.34 : roomHeight * 0.42;
        double targetHeight = baseHeight;
        double targetWidth = targetHeight * effectiveAspectRatio;

        if (parsedDim != null && _naturalAspectRatio == null) {
          const minCm = 25.0;
          const maxCm = 140.0;
          final clampedHeightCm = parsedDim.heightCm.clamp(minCm, maxCm);
          final progress =
              ((clampedHeightCm - minCm) / (maxCm - minCm)).clamp(0.0, 1.0);
          final minH = isLandscape ? roomHeight * 0.24 : roomHeight * 0.26;
          final maxH = isLandscape ? roomHeight * 0.40 : roomHeight * 0.46;
          targetHeight = minH + (maxH - minH) * progress;
          targetWidth = targetHeight * effectiveAspectRatio;
        }

        // Keep framed artwork inside the wall space and above the console shelf
        final maxAllowedWidth = roomWidth * (isLandscape ? 0.62 : 0.52);
        final maxAllowedHeight = roomHeight - 86.0;

        if (targetWidth > maxAllowedWidth) {
          final scale = maxAllowedWidth / targetWidth;
          targetWidth = maxAllowedWidth;
          targetHeight = targetHeight * scale;
        }
        if (targetHeight > maxAllowedHeight) {
          final scale = maxAllowedHeight / targetHeight;
          targetHeight = maxAllowedHeight;
          targetWidth = targetWidth * scale;
        }

        // Frame and inner mat (passe-partout) tightly wrapped around artwork
        final showMatting =
            _hasPassePartout && _selectedFrame != VirtualFrameStyle.none;

        final minSide = math.min(targetWidth, targetHeight);
        final frameThickness = _selectedFrame != VirtualFrameStyle.none
            ? (minSide * 0.045).clamp(3.0, 7.5)
            : 0.0;

        final matThickness = showMatting
            ? (minSide * 0.05).clamp(4.0, 8.5)
            : 0.0;

        final totalExtra = frameThickness + matThickness;

        final outerWidth = targetWidth + 2 * totalExtra;
        final outerHeight = targetHeight + 2 * totalExtra;

        final outerLeftPos = (roomWidth - outerWidth) / 2;
        final availableWallHeightAboveShelf = roomHeight - 66.0;
        final artworkTopPos =
            14.0 + (availableWallHeightAboveShelf - targetHeight) * 0.34;
        final clampedArtworkTopPos =
            artworkTopPos.clamp(10.0, roomHeight * 0.38);
        final outerTopPos = clampedArtworkTopPos - totalExtra;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Room Scene Canvas
              Container(
                height: roomHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Wall background with spotlight glow & floor shadow
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        color: _selectedWallColor.color,
                        child: CustomPaint(
                          size: Size(roomWidth, roomHeight),
                          painter: _WallLightPainter(
                            accentColor: _selectedWallColor.shadowAccent,
                          ),
                        ),
                      ),

                      // Room Furniture
                      CustomPaint(
                        size: Size(roomWidth, roomHeight),
                        painter: _RoomFurniturePainter(),
                      ),

                      // Framed Artwork with orientation-matched frame
                      Positioned(
                        left: outerLeftPos,
                        top: outerTopPos,
                        width: outerWidth,
                        height: outerHeight,
                        child: Center(
                          child: _buildFramedArtworkBox(
                            targetWidth: targetWidth,
                            targetHeight: targetHeight,
                            frameThickness: frameThickness,
                            matThickness: matThickness,
                          ),
                        ),
                      ),

                      // Dimension Scale Note Badge
                      if (widget.artwork.dimensions.isNotEmpty)
                        Positioned(
                          top: 10,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.straighten,
                                  size: 13,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.scaledToScaleHint(
                                      widget.artwork.dimensions),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400,
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

              const SizedBox(height: 14),

              // 2. Customization Controls Section
              Container(
                padding: EdgeInsets.all(isNarrow ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.frameStyle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4A3B32),
                          ),
                        ),
                        if (widget.onToggleFavorite != null)
                          IconButton(
                            icon: Icon(
                              widget.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: widget.isFavorite
                                  ? const Color(0xFFD64550)
                                  : const Color(0xFF7B5E4B),
                              size: 20,
                            ),
                            tooltip: widget.isFavorite
                                ? l10n.removeFromFavorites
                                : l10n.addToFavorites,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              widget.onToggleFavorite!();
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: isNarrow ? 6 : 8,
                      runSpacing: isNarrow ? 6 : 8,
                      children: VirtualFrameStyle.values.map((style) {
                        final isSelected = style == _selectedFrame;
                        return ChoiceChip(
                          label: Text(
                            style.label(l10n),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF7B5E4B),
                          backgroundColor: Colors.grey.shade100,
                          labelPadding: EdgeInsets.symmetric(
                            horizontal: isNarrow ? 4 : 6,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isNarrow ? 6 : 8,
                            vertical: isNarrow ? 2 : 4,
                          ),
                          visualDensity: isNarrow
                              ? VisualDensity.compact
                              : VisualDensity.standard,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          labelStyle: TextStyle(
                            fontSize: isNarrow ? 11.5 : 13,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade800,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          avatar: _buildFrameStyleIcon(style),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedFrame = style);
                            }
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    Text(
                      l10n.wallColor,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4A3B32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: isNarrow ? 6 : 10,
                      runSpacing: isNarrow ? 6 : 8,
                      children: VirtualWallColor.values.map((wallColor) {
                        final isSelected = wallColor == _selectedWallColor;
                        return InkWell(
                          onTap: () =>
                              setState(() => _selectedWallColor = wallColor),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isNarrow ? 9 : 12,
                              vertical: isNarrow ? 5 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: wallColor.color,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF7B5E4B)
                                    : Colors.grey.shade300,
                                width: isSelected ? 2.0 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF7B5E4B)
                                            .withValues(alpha: 0.25),
                                        blurRadius: 6,
                                      )
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: isNarrow ? 12 : 14,
                                  height: isNarrow ? 12 : 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: wallColor.shadowAccent,
                                  ),
                                ),
                                SizedBox(width: isNarrow ? 6 : 8),
                                Text(
                                  wallColor.label(l10n),
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: isNarrow ? 11 : 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: Colors.grey.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    if (_selectedFrame != VirtualFrameStyle.none) ...[
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.crop_free,
                                  size: 18,
                                  color: Color(0xFF7B5E4B),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.passePartout,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: isNarrow ? 12.5 : null,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _hasPassePartout,
                            activeTrackColor: const Color(0xFF7B5E4B),
                            onChanged: (val) =>
                                setState(() => _hasPassePartout = val),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFramedArtworkBox({
    required double targetWidth,
    required double targetHeight,
    required double frameThickness,
    required double matThickness,
  }) {
    BoxDecoration frameOuterDecoration;

    switch (_selectedFrame) {
      case VirtualFrameStyle.none:
        frameOuterDecoration = BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        );
        break;

      case VirtualFrameStyle.oak:
        frameOuterDecoration = BoxDecoration(
          color: const Color(0xFF8D623C),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: const Color(0xFF6B482B),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
        );
        break;

      case VirtualFrameStyle.white:
        frameOuterDecoration = BoxDecoration(
          color: const Color(0xFFFCFCFA),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: const Color(0xFFD8D5CE),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 9,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        );
        break;

      case VirtualFrameStyle.gold:
        frameOuterDecoration = BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE2C468),
              Color(0xFFC59B27),
              Color(0xFF9E7A16),
            ],
          ),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: const Color(0xFF7A5D0D),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
        );
        break;
    }

    final showMatting =
        _hasPassePartout && _selectedFrame != VirtualFrameStyle.none;

    return Container(
      decoration: frameOuterDecoration,
      padding: EdgeInsets.all(frameThickness),
      child: Container(
        color: showMatting ? const Color(0xFFF9F8F4) : Colors.transparent,
        padding: EdgeInsets.all(matThickness),
        child: SizedBox(
          width: targetWidth,
          height: targetHeight,
          child: widget.artwork.imageUrl.isNotEmpty
              ? Image.network(
                  widget.artwork.imageUrl,
                  width: targetWidth,
                  height: targetHeight,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: targetWidth,
                    height: targetHeight,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.grey, size: 24),
                    ),
                  ),
                )
              : Container(
                  width: targetWidth,
                  height: targetHeight,
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.image, color: Colors.grey, size: 24),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFrameStyleIcon(VirtualFrameStyle style) {
    switch (style) {
      case VirtualFrameStyle.none:
        return const Icon(Icons.crop_original, size: 16, color: Colors.grey);
      case VirtualFrameStyle.oak:
        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF8B623E),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case VirtualFrameStyle.white:
        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case VirtualFrameStyle.gold:
        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFFC59B27),
            borderRadius: BorderRadius.circular(2),
          ),
        );
    }
  }
}

/// Painter for overhead ambient light reflection on room wall.
class _WallLightPainter extends CustomPainter {
  final Color accentColor;

  _WallLightPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -1.0),
        radius: 1.2,
        colors: [
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), lightPaint);

    final shadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          accentColor.withValues(alpha: 0.20),
        ],
      ).createShader(
          Rect.fromLTWH(0, size.height - 60, size.width, 60));

    canvas.drawRect(
        Rect.fromLTWH(0, size.height - 60, size.width, 60), shadowPaint);
  }

  @override
  bool shouldRepaint(covariant _WallLightPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor;
}

/// Painter for room furniture (Baseboard, Console Table / Wooden Shelf, Legs, and Plant Silhouette).
class _RoomFurniturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final floorHeight = 22.0;
    final tableWidth = size.width * 0.52;
    final tableHeight = 12.0;
    final tableTopY = size.height - floorHeight - 26.0;
    final tableLeft = (size.width - tableWidth) / 2;

    final floorPaint = Paint()..color = const Color(0xFF3B2F2A);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - floorHeight, size.width, floorHeight),
      floorPaint,
    );

    final skirtingLinePaint = Paint()
      ..color = const Color(0xFF5A4A42)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(0, size.height - floorHeight),
      Offset(size.width, size.height - floorHeight),
      skirtingLinePaint,
    );

    final tableShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(tableLeft, tableTopY + 4, tableWidth, tableHeight + 20),
        const Radius.circular(4),
      ),
      tableShadow,
    );

    final legPaint = Paint()..color = const Color(0xFF5D4331);
    final legPath1 = Path()
      ..moveTo(tableLeft + 16, tableTopY + tableHeight)
      ..lineTo(tableLeft + 22, size.height - floorHeight)
      ..lineTo(tableLeft + 28, size.height - floorHeight)
      ..lineTo(tableLeft + 24, tableTopY + tableHeight)
      ..close();
    canvas.drawPath(legPath1, legPaint);

    final legPath2 = Path()
      ..moveTo(tableLeft + tableWidth - 24, tableTopY + tableHeight)
      ..lineTo(tableLeft + tableWidth - 28, size.height - floorHeight)
      ..lineTo(tableLeft + tableWidth - 22, size.height - floorHeight)
      ..lineTo(tableLeft + tableWidth - 16, tableTopY + tableHeight)
      ..close();
    canvas.drawPath(legPath2, legPaint);

    final tableTopPaint = Paint()..color = const Color(0xFF7A5941);
    final tableTopRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tableLeft, tableTopY, tableWidth, tableHeight),
      const Radius.circular(3),
    );
    canvas.drawRRect(tableTopRRect, tableTopPaint);

    final tableHighlight = Paint()
      ..color = const Color(0xFF9E775C)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(tableLeft + 2, tableTopY + 1),
      Offset(tableLeft + tableWidth - 2, tableTopY + 1),
      tableHighlight,
    );

    final plantBaseX = tableLeft + tableWidth - 36;
    final plantBaseY = tableTopY;

    final potPaint = Paint()..color = const Color(0xFFDCD6CE);
    final potPath = Path()
      ..moveTo(plantBaseX - 8, plantBaseY)
      ..lineTo(plantBaseX + 8, plantBaseY)
      ..lineTo(plantBaseX + 6, plantBaseY - 14)
      ..lineTo(plantBaseX - 6, plantBaseY - 14)
      ..close();
    canvas.drawPath(potPath, potPaint);

    final leafPaint = Paint()
      ..color = const Color(0xFF3F5243)
      ..style = PaintingStyle.fill;

    final stemPaint = Paint()
      ..color = const Color(0xFF2C3B2E)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final stem1 = Path()
      ..moveTo(plantBaseX, plantBaseY - 14)
      ..quadraticBezierTo(
          plantBaseX - 10, plantBaseY - 30, plantBaseX - 16, plantBaseY - 42);
    canvas.drawPath(stem1, stemPaint);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(plantBaseX - 18, plantBaseY - 44),
        width: 10,
        height: 18,
      ),
      leafPaint,
    );

    final stem2 = Path()
      ..moveTo(plantBaseX, plantBaseY - 14)
      ..quadraticBezierTo(
          plantBaseX + 4, plantBaseY - 32, plantBaseX + 10, plantBaseY - 48);
    canvas.drawPath(stem2, stemPaint);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(plantBaseX + 12, plantBaseY - 50),
        width: 12,
        height: 20,
      ),
      leafPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(plantBaseX - 6, plantBaseY - 28),
        width: 12,
        height: 14,
      ),
      leafPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}