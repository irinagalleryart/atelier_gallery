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

        // Calculate artwork target dimensions proportionally based on physical height cm
        final parsedDim = ArtworkDimensions.parse(widget.artwork.dimensions);
        final maxHeight = roomHeight * 0.50;
        final minHeight = roomHeight * 0.22;

        double targetHeight;
        double targetWidth;

        if (parsedDim != null) {
          // Map physical height (25cm to 140cm range) proportionally to pixel height
          const minCm = 25.0;
          const maxCm = 140.0;
          final clampedHeightCm = parsedDim.heightCm.clamp(minCm, maxCm);
          final progress =
              ((clampedHeightCm - minCm) / (maxCm - minCm)).clamp(0.0, 1.0);

          targetHeight = minHeight + (maxHeight - minHeight) * progress;
          targetWidth = targetHeight * parsedDim.aspectRatio;

          // Cap maximum width so it stays neatly framed without overflowing room sides
          final maxAllowedWidth = math.min(roomWidth * 0.62, roomHeight * 0.56);
          if (targetWidth > maxAllowedWidth) {
            final scale = maxAllowedWidth / targetWidth;
            targetWidth = maxAllowedWidth;
            targetHeight = targetHeight * scale;
          }
        } else {
          // Fallback if dimensions cannot be parsed
          targetHeight = roomHeight * 0.38;
          targetWidth = targetHeight * 0.82;
          final maxAllowedWidth = math.min(roomWidth * 0.62, roomHeight * 0.56);
          if (targetWidth > maxAllowedWidth) {
            final scale = maxAllowedWidth / targetWidth;
            targetWidth = maxAllowedWidth;
            targetHeight = targetHeight * scale;
          }
        }

        // Horizontal and vertical centering calculations
        final leftPos = (roomWidth - targetWidth) / 2;
        final availableWallHeightAboveShelf = roomHeight - 64.0;
        final topPos =
            14.0 + (availableWallHeightAboveShelf - targetHeight) * 0.38;
        final clampedTopPos = topPos.clamp(10.0, roomHeight * 0.42);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Room Scene Canvas (Single Stack with direct Positioned child to avoid ParentDataWidget errors)
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

                      // Room Furniture (Console Table / Shelf & Plant Silhouette)
                      CustomPaint(
                        size: Size(roomWidth, roomHeight),
                        painter: _RoomFurniturePainter(),
                      ),

                      // Framed Artwork (Direct Positioned child of Stack)
                      Positioned(
                        left: leftPos,
                        top: clampedTopPos,
                        width: targetWidth,
                        height: targetHeight,
                        child: _buildFramedArtworkBox(targetHeight),
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
                    // Frame Style Header & Selector (Wraps cleanly on narrow screens)
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

                    // Wall Color Header & Selector (Wraps cleanly on narrow screens)
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

                    // Passe-partout / Inner White Mat Border Toggle (Hidden for unframed canvas)
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

  Widget _buildFramedArtworkBox(double targetHeight) {
    double frameBorderWidth = 0;
    BoxDecoration frameOuterDecoration;
    EdgeInsets mattingPadding = EdgeInsets.zero;

    switch (_selectedFrame) {
      case VirtualFrameStyle.none:
        frameBorderWidth = 0;
        frameOuterDecoration = BoxDecoration(
          borderRadius: BorderRadius.circular(1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        );
        mattingPadding = EdgeInsets.zero;
        break;

      case VirtualFrameStyle.oak:
        frameBorderWidth = math.max(8.0, targetHeight * 0.06);
        frameOuterDecoration = BoxDecoration(
          color: const Color(0xFF8D623C),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: const Color(0xFF6B482B),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.32),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 12),
            ),
          ],
        );
        mattingPadding =
            (_hasPassePartout && _selectedFrame != VirtualFrameStyle.none)
                ? EdgeInsets.all(math.max(8.0, targetHeight * 0.07))
                : EdgeInsets.zero;
        break;

      case VirtualFrameStyle.white:
        frameBorderWidth = math.max(8.0, targetHeight * 0.06);
        frameOuterDecoration = BoxDecoration(
          color: const Color(0xFFFDFDFD),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.26),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            ),
          ],
        );
        mattingPadding =
            (_hasPassePartout && _selectedFrame != VirtualFrameStyle.none)
                ? EdgeInsets.all(math.max(8.0, targetHeight * 0.07))
                : EdgeInsets.zero;
        break;

      case VirtualFrameStyle.gold:
        frameBorderWidth = math.max(8.0, targetHeight * 0.06);
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
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 12),
            ),
          ],
        );
        mattingPadding =
            (_hasPassePartout && _selectedFrame != VirtualFrameStyle.none)
                ? EdgeInsets.all(math.max(8.0, targetHeight * 0.07))
                : EdgeInsets.zero;
        break;
    }

    final showMatting =
        _hasPassePartout && _selectedFrame != VirtualFrameStyle.none;

    return Container(
      decoration: frameOuterDecoration,
      padding: EdgeInsets.all(frameBorderWidth),
      child: Container(
        color: showMatting ? const Color(0xFFF9F8F4) : Colors.transparent,
        padding: mattingPadding,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: showMatting
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 4,
                      spreadRadius: -1,
                    ),
                  ]
                : null,
          ),
          child: widget.artwork.imageUrl.isNotEmpty
              ? Image.network(
                  widget.artwork.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.grey, size: 24),
                    ),
                  ),
                )
              : Container(
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
    // Top center light cone
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

    // Subtle floor shadow gradient at bottom
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

    // 1. Skirting Board / Floor Base
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

    // 2. Console Table Shadow on Wall/Floor
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

    // 3. Console Table Legs (Minimalist tapered wooden legs)
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

    // 4. Console Table Surface
    final tableTopPaint = Paint()..color = const Color(0xFF7A5941);
    final tableTopRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tableLeft, tableTopY, tableWidth, tableHeight),
      const Radius.circular(3),
    );
    canvas.drawRRect(tableTopRRect, tableTopPaint);

    // Table top highlight
    final tableHighlight = Paint()
      ..color = const Color(0xFF9E775C)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(tableLeft + 2, tableTopY + 1),
      Offset(tableLeft + tableWidth - 2, tableTopY + 1),
      tableHighlight,
    );

    // 5. Minimalist Potted Ceramic Plant Silhouette on Right Side of Console Table
    final plantBaseX = tableLeft + tableWidth - 36;
    final plantBaseY = tableTopY;

    // Ceramic Pot
    final potPaint = Paint()..color = const Color(0xFFDCD6CE);
    final potPath = Path()
      ..moveTo(plantBaseX - 8, plantBaseY)
      ..lineTo(plantBaseX + 8, plantBaseY)
      ..lineTo(plantBaseX + 6, plantBaseY - 14)
      ..lineTo(plantBaseX - 6, plantBaseY - 14)
      ..close();
    canvas.drawPath(potPath, potPaint);

    // Plant Stems & Leaves
    final leafPaint = Paint()
      ..color = const Color(0xFF3F5243)
      ..style = PaintingStyle.fill;

    final stemPaint = Paint()
      ..color = const Color(0xFF2C3B2E)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    // Stem 1 & Leaves
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

    // Stem 2 & Leaves
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

    // Side Leaf
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
