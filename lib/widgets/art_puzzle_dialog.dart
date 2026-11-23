import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/gallery_data_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/atelier_models.dart';
import '../services/puzzle_leaderboard_service.dart';
import '../services/supabase_service.dart';

enum PuzzleDialogTab { game, leaderboard }

/// Art Puzzle ("Ликовна сложувалка") mini-game dialog for Atelier Gallery.
/// Features web-safe tile slices, nickname competition & real-time Supabase leaderboard.
class ArtPuzzleDialog extends StatefulWidget {
  final ArtworkModel initialArtwork;
  final List<ArtworkModel> artworks;
  final GalleryDataController? dataController;

  const ArtPuzzleDialog({
    super.key,
    required this.initialArtwork,
    required this.artworks,
    this.dataController,
  });

  /// Helper to open the Art Puzzle dialog cleanly from anywhere in the app.
  static Future<void> show(
    BuildContext context, {
    required ArtworkModel initialArtwork,
    required List<ArtworkModel> artworks,
    GalleryDataController? dataController,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ArtPuzzleDialog(
        initialArtwork: initialArtwork,
        artworks: artworks.isNotEmpty ? artworks : [initialArtwork],
        dataController: dataController,
      ),
    );
  }

  @override
  State<ArtPuzzleDialog> createState() => _ArtPuzzleDialogState();
}

class _ArtPuzzleDialogState extends State<ArtPuzzleDialog> {
  late ArtworkModel _selectedArtwork;
  int _gridSize = 3; // 3x3, 4x4, 5x5
  late List<int> _board; // board positions containing original tile indices
  int? _selectedIndex;
  int _moves = 0;
  int _secondsElapsed = 0;
  Timer? _timer;
  bool _isSolved = false;
  bool _isPreviewing = false;
  int? _bestTimeSeconds;
  int? _bestMoves;
  bool _isNewRecord = false;

  // Nickname & Leaderboard state
  PuzzleDialogTab _currentTab = PuzzleDialogTab.game;
  String? _nickname;
  bool _isSubmittingScore = false;
  PuzzleSubmissionResult? _lastSubmissionResult;

  int _leaderboardMode = 0; // 0: Total Points, 1: By Level
  int _leaderboardGridSize = 3; // 3, 4, 5
  bool _isLoadingLeaderboard = false;
  List<PuzzleTotalEntry> _totalLeaderboard = [];
  List<PuzzleLevelEntry> _levelLeaderboard = [];
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _selectedArtwork = widget.initialArtwork;
    _initBoardAndShuffle();
    _loadNickname();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _unsubscribeRealtime();
    super.dispose();
  }

  Future<void> _loadNickname() async {
    final name = await PuzzleLeaderboardService.getSavedNickname();
    if (mounted) {
      setState(() {
        _nickname = name;
      });
    }
  }

  void _initBoardAndShuffle() {
    _timer?.cancel();
    _timer = null;
    _moves = 0;
    _secondsElapsed = 0;
    _isSolved = false;
    _isNewRecord = false;
    _selectedIndex = null;
    _isPreviewing = false;
    _lastSubmissionResult = null;

    final totalTiles = _gridSize * _gridSize;
    _board = List.generate(totalTiles, (index) => index);

    // Perform random valid swaps from solved state
    final random = Random();
    final swapCount = 35 + (_gridSize * 10) + random.nextInt(20);
    for (int i = 0; i < swapCount; i++) {
      final a = random.nextInt(totalTiles);
      int b = random.nextInt(totalTiles);
      while (b == a) {
        b = random.nextInt(totalTiles);
      }
      final temp = _board[a];
      _board[a] = _board[b];
      _board[b] = temp;
    }

    // Ensure not solved initially
    if (_checkIsBoardSolved()) {
      final temp = _board[0];
      _board[0] = _board[1];
      _board[1] = temp;
    }

    _loadBestScore();
    _startTimer();
  }

  bool _checkIsBoardSolved() {
    for (int i = 0; i < _board.length; i++) {
      if (_board[i] != i) return false;
    }
    return true;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (!_isSolved && _currentTab == PuzzleDialogTab.game) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  Future<void> _loadBestScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeKey = 'art_puzzle_best_time_${_selectedArtwork.id}_$_gridSize';
      final movesKey = 'art_puzzle_best_moves_${_selectedArtwork.id}_$_gridSize';
      setState(() {
        _bestTimeSeconds = prefs.getInt(timeKey);
        _bestMoves = prefs.getInt(movesKey);
      });
    } catch (_) {}
  }

  Future<void> _saveBestScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeKey = 'art_puzzle_best_time_${_selectedArtwork.id}_$_gridSize';
      final movesKey = 'art_puzzle_best_moves_${_selectedArtwork.id}_$_gridSize';

      bool isRecord = false;
      if (_bestTimeSeconds == null || _secondsElapsed < _bestTimeSeconds!) {
        isRecord = true;
      } else if (_secondsElapsed == _bestTimeSeconds! &&
          (_bestMoves == null || _moves < _bestMoves!)) {
        isRecord = true;
      }

      if (isRecord) {
        await prefs.setInt(timeKey, _secondsElapsed);
        await prefs.setInt(movesKey, _moves);
        if (mounted) {
          setState(() {
            _bestTimeSeconds = _secondsElapsed;
            _bestMoves = _moves;
            _isNewRecord = true;
          });
        }
      }
    } catch (_) {}
  }

  void _onTileTap(int gridIndex) {
    if (_isSolved || _isPreviewing) return;

    if (_selectedIndex == null) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedIndex = gridIndex;
      });
    } else if (_selectedIndex == gridIndex) {
      // Deselect if tapping same tile again
      setState(() {
        _selectedIndex = null;
      });
    } else {
      // Swap tiles
      HapticFeedback.lightImpact();
      setState(() {
        final firstIndex = _selectedIndex!;
        final temp = _board[firstIndex];
        _board[firstIndex] = _board[gridIndex];
        _board[gridIndex] = temp;
        _moves++;
        _selectedIndex = null;

        if (_checkIsBoardSolved()) {
          _isSolved = true;
          _timer?.cancel();
          _timer = null;
          HapticFeedback.mediumImpact();
          _saveBestScore();
          _handlePuzzleCompleted();
        }
      });
    }
  }

  Future<void> _handlePuzzleCompleted() async {
    String? currentNick = _nickname;
    if (currentNick == null || currentNick.trim().isEmpty) {
      currentNick = await _showNicknameInputDialog(isMandatoryForScore: true);
    }

    final playerNick = (currentNick != null && currentNick.trim().isNotEmpty)
        ? currentNick.trim()
        : 'ArtExplorer';

    if (mounted) {
      setState(() {
        _nickname = playerNick;
        _isSubmittingScore = true;
      });
    }

    final result = await PuzzleLeaderboardService.submitScore(
      nickname: playerNick,
      artworkId: _selectedArtwork.id,
      gridSize: _gridSize,
      durationSeconds: _secondsElapsed,
      movesCount: _moves,
    );

    if (mounted) {
      setState(() {
        _lastSubmissionResult = result;
        _isSubmittingScore = false;
      });
    }
  }

  Future<String?> _showNicknameInputDialog({bool isMandatoryForScore = false}) async {
    final controller = TextEditingController(text: _nickname ?? '');
    String? errorMessage;

    return showDialog<String>(
      context: context,
      barrierDismissible: !isMandatoryForScore,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final l10n = AppLocalizations.of(context)!;
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? theme.colorScheme.surface : const Color(0xFFFAF9F6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(
                    Icons.account_circle_outlined,
                    color: isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _nickname == null || _nickname!.isEmpty
                        ? l10n.enterNickname
                        : l10n.changeNickname,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : null,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B5E4B).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: Color(0xFF7B5E4B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.nicknameNotice,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF5A4333)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      maxLength: 15,
                      decoration: InputDecoration(
                        labelText: l10n.nickname,
                        hintText: l10n.nicknameHint,
                        errorText: errorMessage,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (_) {
                        if (errorMessage != null) {
                          setDialogState(() {
                            errorMessage = null;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                if (!isMandatoryForScore)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: Text(l10n.cancel),
                  ),
                ElevatedButton(
                  onPressed: () async {
                    final input = controller.text.trim();
                    final errCode = PuzzleLeaderboardService.validateNickname(input);
                    if (errCode != null) {
                      setDialogState(() {
                        if (errCode == 'length_error') {
                          errorMessage = l10n.nicknameLengthError;
                        } else {
                          errorMessage = l10n.nicknameCharError;
                        }
                      });
                      return;
                    }
                    await PuzzleLeaderboardService.saveNickname(input);
                    if (context.mounted) {
                      Navigator.of(context).pop(input);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B5E4B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(l10n.saveNickname),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _switchTab(PuzzleDialogTab tab) {
    if (_currentTab == tab) return;
    setState(() {
      _currentTab = tab;
    });
    if (tab == PuzzleDialogTab.leaderboard) {
      _loadLeaderboardData();
      _subscribeRealtime();
    } else {
      _unsubscribeRealtime();
    }
  }

  void _subscribeRealtime() {
    _unsubscribeRealtime();
    _realtimeChannel = PuzzleLeaderboardService.subscribeToUpdates(() {
      if (mounted && _currentTab == PuzzleDialogTab.leaderboard) {
        _loadLeaderboardData();
      }
    });
  }

  void _unsubscribeRealtime() {
    if (_realtimeChannel != null && SupabaseService.isInitialized) {
      try {
        SupabaseService.client.removeChannel(_realtimeChannel!);
      } catch (_) {}
      _realtimeChannel = null;
    }
  }

  Future<void> _loadLeaderboardData() async {
    setState(() {
      _isLoadingLeaderboard = true;
    });

    if (_leaderboardMode == 0) {
      final data = await PuzzleLeaderboardService.fetchTotalLeaderboard();
      if (mounted) {
        setState(() {
          _totalLeaderboard = data;
          _isLoadingLeaderboard = false;
        });
      }
    } else {
      final data = await PuzzleLeaderboardService.fetchLevelLeaderboard(
        gridSize: _leaderboardGridSize,
      );
      if (mounted) {
        setState(() {
          _levelLeaderboard = data;
          _isLoadingLeaderboard = false;
        });
      }
    }
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localeCode = Localizations.localeOf(context).languageCode;
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 600;

    final maxBoardWidth = isCompact ? min(size.width - 48, 380.0) : 420.0;
    final boardSize = max(240.0, maxBoardWidth);
    final tileWidth = boardSize / _gridSize;
    final tileHeight = boardSize / _gridSize;

    return Dialog(
      backgroundColor: isDark ? theme.colorScheme.surface : const Color(0xFFFAF9F6),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 24,
        vertical: isCompact ? 24 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isCompact ? size.width * 0.95 : 820,
        constraints: BoxConstraints(maxHeight: size.height * 0.92),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Navigation & Action Header
            _buildHeader(context, l10n, localeCode, isCompact),

            const Divider(height: 20),

            // Dialog Body: Game View or Leaderboard View
            Expanded(
              child: _currentTab == PuzzleDialogTab.leaderboard
                  ? _buildLeaderboardView(l10n, isCompact)
                  : SingleChildScrollView(
                      child: isCompact
                          ? Column(
                              children: [
                                _buildArtworkInfoBar(l10n, localeCode),
                                const SizedBox(height: 12),
                                _buildControlsRow(l10n),
                                const SizedBox(height: 14),
                                _buildPuzzleBoardArea(
                                  boardSize: boardSize,
                                  tileWidth: tileWidth,
                                  tileHeight: tileHeight,
                                  l10n: l10n,
                                  localeCode: localeCode,
                                ),
                                const SizedBox(height: 14),
                                _buildFooterControls(l10n, isCompact),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left column: Puzzle Board
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    children: [
                                      _buildControlsRow(l10n),
                                      const SizedBox(height: 14),
                                      _buildPuzzleBoardArea(
                                        boardSize: boardSize,
                                        tileWidth: tileWidth,
                                        tileHeight: tileHeight,
                                        l10n: l10n,
                                        localeCode: localeCode,
                                      ),
                                      const SizedBox(height: 14),
                                      _buildFooterControls(l10n, isCompact),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),

                                // Right column: Artwork Info & Preview Reference
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildArtworkInfoCard(l10n, localeCode),
                                      const SizedBox(height: 16),
                                      _buildBestScoreCard(l10n),
                                      const SizedBox(height: 16),
                                      _buildReferencePreviewCard(l10n),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    String localeCode,
    bool isCompact,
  ) {
    final width = MediaQuery.of(context).size.width;
    final isMedium = width < 900;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isCompact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.primaryContainer : const Color(0xFF7B5E4B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.extension_outlined,
                  color: isDark ? theme.colorScheme.onPrimaryContainer : const Color(0xFF7B5E4B),
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.artPuzzle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _buildTabSwitcher(l10n, isCompact, isMedium),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                tooltip: l10n.close,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildNicknameChip(l10n, isCompact, isMedium),
              ),
              if (widget.artworks.length > 1 && _currentTab == PuzzleDialogTab.game) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildArtworkDropdown(l10n, localeCode, isCompact, isMedium),
                ),
              ],
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        // Left: Dialog Icon, Title & View Mode Switcher
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.primaryContainer : const Color(0xFF7B5E4B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.extension_outlined,
                  color: isDark ? theme.colorScheme.onPrimaryContainer : const Color(0xFF7B5E4B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.artPuzzle,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                      ),
                    ),
                    if (!isCompact && !isMedium)
                      Text(
                        l10n.artPuzzleSubtitle,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Tab Switcher (Puzzle vs Leaderboard)
              _buildTabSwitcher(l10n, isCompact, isMedium),
            ],
          ),
        ),

        const SizedBox(width: 6),

        // Right Header Actions: Nickname Chip, Artwork Dropdown & Close Button
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNicknameChip(l10n, isCompact, isMedium),

            if (widget.artworks.length > 1 && _currentTab == PuzzleDialogTab.game) ...[
              const SizedBox(width: 6),
              _buildArtworkDropdown(l10n, localeCode, isCompact, isMedium),
            ],

            const SizedBox(width: 2),

            IconButton(
              icon: const Icon(Icons.close, size: 20),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              tooltip: l10n.close,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabSwitcher(
    AppLocalizations l10n,
    bool isCompact,
    bool isMedium,
  ) {
    final showGameLabel = !isCompact && (!isMedium || _currentTab == PuzzleDialogTab.game);
    final showLeaderboardLabel = !isCompact && (!isMedium || _currentTab == PuzzleDialogTab.leaderboard);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : const Color(0xFFF5F3EF),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _switchTab(PuzzleDialogTab.game),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : (isMedium ? 8 : 12),
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: _currentTab == PuzzleDialogTab.game
                    ? (isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                boxShadow: _currentTab == PuzzleDialogTab.game
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 3,
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.extension_outlined,
                    size: 14,
                    color: _currentTab == PuzzleDialogTab.game
                        ? (isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B))
                        : (isDark ? Colors.white60 : Colors.grey.shade600),
                  ),
                  if (showGameLabel) ...[
                    const SizedBox(width: 4),
                    Text(
                      l10n.artPuzzle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: _currentTab == PuzzleDialogTab.game
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _currentTab == PuzzleDialogTab.game
                            ? (isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B))
                            : (isDark ? Colors.white70 : Colors.grey.shade700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => _switchTab(PuzzleDialogTab.leaderboard),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : (isMedium ? 8 : 12),
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: _currentTab == PuzzleDialogTab.leaderboard
                    ? (isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                boxShadow: _currentTab == PuzzleDialogTab.leaderboard
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 3,
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 14,
                    color: _currentTab == PuzzleDialogTab.leaderboard
                        ? const Color(0xFFD4AF37)
                        : Colors.grey.shade600,
                  ),
                  if (showLeaderboardLabel) ...[
                    const SizedBox(width: 4),
                    Text(
                      l10n.leaderboardTitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: _currentTab == PuzzleDialogTab.leaderboard
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _currentTab == PuzzleDialogTab.leaderboard
                            ? const Color(0xFF7B5E4B)
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNicknameChip(
    AppLocalizations l10n,
    bool isCompact,
    bool isMedium,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () async {
        final newNick = await _showNicknameInputDialog();
        if (newNick != null && newNick.isNotEmpty) {
          setState(() {
            _nickname = newNick;
          });
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surfaceContainerHigh : const Color(0xFF7B5E4B).withValues(alpha: 0.08),
          border: Border.all(
            color: isDark ? theme.colorScheme.outlineVariant : const Color(0xFF7B5E4B).withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 14,
              color: isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                (_nickname != null && _nickname!.isNotEmpty)
                    ? _nickname!
                    : l10n.nickname,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.edit, size: 11, color: isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B)),
          ],
        ),
      ),
    );
  }

  Widget _buildArtworkDropdown(
    AppLocalizations l10n,
    String localeCode,
    bool isCompact,
    bool isMedium,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopupMenuButton<ArtworkModel>(
      tooltip: l10n.chooseArtwork,
      initialValue: _selectedArtwork,
      onSelected: (artwork) {
        setState(() {
          _selectedArtwork = artwork;
          _initBoardAndShuffle();
        });
      },
      itemBuilder: (context) => widget.artworks.map((art) {
        final isCurrent = art.id == _selectedArtwork.id;
        return PopupMenuItem<ArtworkModel>(
          value: art,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  art.imageUrl,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 32,
                    height: 32,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  art.localizedTitle(localeCode),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent
                        ? (isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B))
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
          border: Border.all(
            color: isDark ? theme.colorScheme.outlineVariant : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_outlined,
              size: 14,
              color: isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _selectedArtwork.localizedTitle(localeCode),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 16, color: isDark ? Colors.white60 : Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsRow(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 430;

        if (isNarrow) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? theme.colorScheme.outlineVariant : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surfaceContainer : const Color(0xFFF5F3EF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildGridOptionButton(
                          gridSize: 3,
                          label: l10n.easy3x3,
                        ),
                        _buildGridOptionButton(
                          gridSize: 4,
                          label: l10n.medium4x4,
                        ),
                        _buildGridOptionButton(
                          gridSize: 5,
                          label: l10n.hard5x5,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Icon(
                            Icons.touch_app_outlined,
                            size: 14,
                            color: isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B),
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              '${l10n.movesLabel}: ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          Text(
                            '$_moves',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1F1F1F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B),
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              _formatTime(_secondsElapsed),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                fontFeatures: const [FontFeature.tabularFigures()],
                                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1F1F1F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? theme.colorScheme.outlineVariant : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Difficulty / Grid Size Switcher
              Container(
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surfaceContainer : const Color(0xFFF5F3EF),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(2),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildGridOptionButton(
                        gridSize: 3,
                        label: l10n.easy3x3,
                      ),
                      _buildGridOptionButton(
                        gridSize: 4,
                        label: l10n.medium4x4,
                      ),
                      _buildGridOptionButton(
                        gridSize: 5,
                        label: l10n.hard5x5,
                      ),
                    ],
                  ),
                ),
              ),

              // Moves & Timer display
              Row(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        size: 15,
                        color: isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${l10n.movesLabel}: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '$_moves',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1F1F1F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 15,
                        color: isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(_secondsElapsed),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1F1F1F),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridOptionButton({
    required int gridSize,
    required String label,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _gridSize == gridSize;

    return InkWell(
      onTap: () {
        if (_gridSize != gridSize) {
          setState(() {
            _gridSize = gridSize;
            _initBoardAndShuffle();
          });
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 3,
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? (isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B))
                : (isDark ? Colors.white70 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Widget _buildPuzzleBoardArea({
    required double boardSize,
    required double tileWidth,
    required double tileHeight,
    required AppLocalizations l10n,
    required String localeCode,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Container(
        width: boardSize,
        height: boardSize,
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surfaceContainerHigh : const Color(0xFFEFECE6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isSolved
                ? const Color(0xFFD4AF37)
                : (isDark ? theme.colorScheme.outlineVariant : Colors.black.withValues(alpha: 0.12)),
            width: _isSolved ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // Grid of Tiles
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _gridSize,
                ),
                itemCount: _board.length,
                itemBuilder: (context, gridIndex) {
                  return _buildTile(
                    gridIndex: gridIndex,
                    tileWidth: tileWidth,
                    tileHeight: tileHeight,
                  );
                },
              ),

              // Full Image Peek Overlay
              if (_isPreviewing)
                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: 0.95,
                    child: Stack(
                      children: [
                        Image.network(
                          _selectedArtwork.imageUrl,
                          fit: BoxFit.cover,
                          width: boardSize,
                          height: boardSize,
                        ),
                        Container(
                          color: Colors.black.withValues(alpha: 0.25),
                          padding: const EdgeInsets.all(12),
                          alignment: Alignment.topCenter,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              l10n.previewLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Celebratory Solved Banner Overlay with Points & Leaderboard Action
              if (_isSolved)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: isDark ? theme.colorScheme.surfaceContainerHigh : const Color(0xFFFAF9F6),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.emoji_events_rounded,
                                  color: Color(0xFFD4AF37),
                                  size: 44,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.puzzleCompleted,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.puzzleCompletedDesc(
                                    _moves,
                                    _formatTime(_secondsElapsed),
                                  ),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Points & Submission Result Card
                                if (_isSubmittingScore)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF7B5E4B),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.submittingScore,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF7B5E4B),
                                        ),
                                      ),
                                    ],
                                  )
                                else if (_lastSubmissionResult != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4AF37)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFFD4AF37)),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          l10n.ptsEarned(_lastSubmissionResult!.pointsEarned),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF7B5E4B),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          l10n.totalPointsLabel(_lastSubmissionResult!.totalPoints),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_lastSubmissionResult!.isOffline) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.savedOffline,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ],

                                if (_isNewRecord ||
                                    (_lastSubmissionResult?.isNewLevelBest ?? false)) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4AF37)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFFD4AF37)),
                                    ),
                                    child: Text(
                                      l10n.newBestScore,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7B5E4B),
                                      ),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _initBoardAndShuffle,
                                      icon: const Icon(Icons.replay, size: 16),
                                      label: Text(l10n.playAgain),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF7B5E4B),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _switchTab(PuzzleDialogTab.leaderboard),
                                      icon: const Icon(Icons.emoji_events_outlined, size: 16),
                                      label: Text(l10n.viewLeaderboard),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFD4AF37),
                                        foregroundColor: const Color(0xFF3E2812),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                      ),
                                    ),
                                    if (widget.artworks.length > 1)
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          final currIndex = widget.artworks
                                              .indexWhere((a) =>
                                                  a.id == _selectedArtwork.id);
                                          final nextIndex = (currIndex + 1) %
                                              widget.artworks.length;
                                          setState(() {
                                            _selectedArtwork =
                                                widget.artworks[nextIndex];
                                            _initBoardAndShuffle();
                                          });
                                        },
                                        icon: const Icon(
                                            Icons.skip_next_outlined,
                                            size: 16),
                                        label: Text(l10n.selectAnotherArtwork),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF1F1F1F),
                                          side: BorderSide(
                                              color: Colors.grey.shade400),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile({
    required int gridIndex,
    required double tileWidth,
    required double tileHeight,
  }) {
    final tileId = _board[gridIndex];
    final origRow = tileId ~/ _gridSize;
    final origCol = tileId % _gridSize;
    final isSelected = (_selectedIndex == gridIndex);

    return GestureDetector(
      onTap: () => _onTileTap(gridIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD4AF37)
                : (_isSolved
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.6)),
            width: isSelected ? 3.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: tileWidth,
            height: tileHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: -origCol * tileWidth,
                  top: -origRow * tileHeight,
                  width: _gridSize * tileWidth,
                  height: _gridSize * tileHeight,
                  child: Image.network(
                    _selectedArtwork.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFEFECE6),
                      child: const Center(
                        child: Icon(
                          Icons.palette_outlined,
                          color: Color(0xFF7B5E4B),
                        ),
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: const Color(0xFFF5F3EF),
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF7B5E4B),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD4AF37),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
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

  Widget _buildFooterControls(AppLocalizations l10n, bool isCompact) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Peek / Preview Toggle Button
        Expanded(
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPreviewing = true),
            onTapUp: (_) => setState(() => _isPreviewing = false),
            onTapCancel: () => setState(() => _isPreviewing = false),
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() => _isPreviewing = !_isPreviewing);
              },
              icon: Icon(
                _isPreviewing ? Icons.visibility_off : Icons.visibility_outlined,
                size: 15,
              ),
              label: Text(
                l10n.peekLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCompact ? 11 : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 6 : 12,
                  vertical: isCompact ? 8 : 10,
                ),
                backgroundColor: _isPreviewing
                    ? (isDark
                        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                        : const Color(0xFF7B5E4B).withValues(alpha: 0.12))
                    : (isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white),
                foregroundColor: _isPreviewing
                    ? (isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B))
                    : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1F1F1F)),
                side: BorderSide(
                  color: _isPreviewing
                      ? (isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B))
                      : (isDark ? theme.colorScheme.outlineVariant : Colors.grey.shade400),
                  width: isDark ? 1.2 : 1.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),

        SizedBox(width: isCompact ? 8 : 12),

        // Shuffle / Restart Button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _initBoardAndShuffle,
            icon: const Icon(Icons.shuffle, size: 15),
            label: Text(
              l10n.shuffleLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isCompact ? 11 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 6 : 12,
                vertical: isCompact ? 8 : 10,
              ),
              backgroundColor: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
              foregroundColor: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1F1F1F),
              side: BorderSide(
                color: isDark ? theme.colorScheme.outlineVariant : Colors.grey.shade400,
                width: isDark ? 1.2 : 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArtworkInfoBar(AppLocalizations l10n, String localeCode) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? theme.colorScheme.outlineVariant : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              _selectedArtwork.imageUrl,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedArtwork.localizedTitle(localeCode),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                  ),
                ),
                Text(
                  '${_selectedArtwork.technique} • ${_selectedArtwork.createdYear}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (_bestTimeSeconds != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surfaceContainer : const Color(0xFFF5F3EF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.bestScore(
                  _bestMoves ?? 0,
                  _formatTime(_bestTimeSeconds!),
                ),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArtworkInfoCard(AppLocalizations l10n, String localeCode) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? theme.colorScheme.outlineVariant : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedArtwork.localizedTitle(localeCode),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_selectedArtwork.technique} • ${_selectedArtwork.createdYear}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
          if (_selectedArtwork.dimensions.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '${l10n.dimensions}: ${_selectedArtwork.dimensions}',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBestScoreCard(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainer : const Color(0xFFF5F3EF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? theme.colorScheme.outlineVariant : const Color(0xFF7B5E4B).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.military_tech_outlined,
            color: Color(0xFFD4AF37),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _bestTimeSeconds != null
                      ? l10n.bestScore(
                          _bestMoves ?? 0,
                          _formatTime(_bestTimeSeconds!),
                        )
                      : l10n.noBestScore,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferencePreviewCard(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.image_outlined,
              size: 14,
              color: isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B),
            ),
            const SizedBox(width: 6),
            Text(
              l10n.previewLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F1F1F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? theme.colorScheme.outlineVariant : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.network(
              _selectedArtwork.imageUrl,
              height: 170,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // LEADERBOARD VIEW COMPONENTS
  // ===========================================================================

  Widget _buildLeaderboardView(AppLocalizations l10n, bool isCompact) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Mode Switcher Header
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? theme.colorScheme.outlineVariant : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? theme.colorScheme.surfaceContainer : const Color(0xFFF5F3EF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                if (_leaderboardMode != 0) {
                                  setState(() {
                                    _leaderboardMode = 0;
                                  });
                                  _loadLeaderboardData();
                                }
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _leaderboardMode == 0
                                      ? (isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: _leaderboardMode == 0
                                      ? [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.06),
                                            blurRadius: 4,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  l10n.tabTotalPoints,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _leaderboardMode == 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _leaderboardMode == 0
                                        ? (isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B))
                                        : (isDark ? Colors.white70 : Colors.grey.shade700),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                if (_leaderboardMode != 1) {
                                  setState(() {
                                    _leaderboardMode = 1;
                                  });
                                  _loadLeaderboardData();
                                }
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _leaderboardMode == 1
                                      ? (isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: _leaderboardMode == 1
                                      ? [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.06),
                                            blurRadius: 4,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  l10n.tabByLevel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _leaderboardMode == 1
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _leaderboardMode == 1
                                        ? (isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B))
                                        : (isDark ? Colors.white70 : Colors.grey.shade700),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      size: 20,
                      color: isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B),
                    ),
                    tooltip: l10n.refresh,
                    onPressed: _loadLeaderboardData,
                  ),
                ],
              ),

              if (_leaderboardMode == 1) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLevelSubTab(3, l10n.level3x3),
                    const SizedBox(width: 6),
                    _buildLevelSubTab(4, l10n.level4x4),
                    const SizedBox(width: 6),
                    _buildLevelSubTab(5, l10n.level5x5),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Leaderboard Content List
        Expanded(
          child: _isLoadingLeaderboard
              ? Center(
                  child: CircularProgressIndicator(
                    color: isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B),
                  ),
                )
              : _leaderboardMode == 0
                  ? _buildTotalLeaderboardList(l10n, isCompact)
                  : _buildLevelLeaderboardList(l10n, isCompact),
        ),
      ],
    );
  }

  Widget _buildLevelSubTab(int size, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _leaderboardGridSize == size;

    return InkWell(
      onTap: () {
        if (_leaderboardGridSize != size) {
          setState(() {
            _leaderboardGridSize = size;
          });
          _loadLeaderboardData();
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? theme.colorScheme.primary : const Color(0xFF7B5E4B))
              : (isDark ? theme.colorScheme.surfaceContainer : const Color(0xFFF5F3EF)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalLeaderboardList(AppLocalizations l10n, bool isCompact) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_totalLeaderboard.isEmpty) {
      return _buildEmptyLeaderboardState(l10n);
    }

    final userNorm =
        PuzzleLeaderboardService.normalizeNickname(_nickname ?? '');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? theme.colorScheme.outlineVariant : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: _totalLeaderboard.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = _totalLeaderboard[index];
          final isMe =
              userNorm.isNotEmpty && entry.nicknameNormalized == userNorm;

          return Container(
            decoration: BoxDecoration(
              color: isMe
                  ? (isDark
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : const Color(0xFF7B5E4B).withValues(alpha: 0.08))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                _buildRankBadge(entry.rank),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              entry.nickname,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    isMe ? FontWeight.bold : FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? theme.colorScheme.primary : const Color(0xFF7B5E4B),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'YOU',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        l10n.puzzlesCompletedCount(entry.puzzlesCompleted),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.totalPoints} pts',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLevelLeaderboardList(AppLocalizations l10n, bool isCompact) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_levelLeaderboard.isEmpty) {
      return _buildEmptyLeaderboardState(l10n);
    }

    final userNorm =
        PuzzleLeaderboardService.normalizeNickname(_nickname ?? '');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? theme.colorScheme.outlineVariant : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: _levelLeaderboard.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = _levelLeaderboard[index];
          final isMe =
              userNorm.isNotEmpty && entry.nicknameNormalized == userNorm;

          return Container(
            decoration: BoxDecoration(
              color: isMe
                  ? (isDark
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : const Color(0xFF7B5E4B).withValues(alpha: 0.08))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                _buildRankBadge(entry.rank),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              entry.nickname,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    isMe ? FontWeight.bold : FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? theme.colorScheme.primary : const Color(0xFF7B5E4B),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'YOU',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          if (entry.bestDuration > 0)
                            Text(
                              '${_formatTime(entry.bestDuration)} • ',
                              style: TextStyle(
                                  fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                            ),
                          if (entry.bestMoves > 0)
                            Text(
                              '${entry.bestMoves} ${l10n.movesLabel.toLowerCase()}',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.bestPoints} pts',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7B5E4B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color bg;
    Color fg = Colors.white;
    IconData? icon;

    if (rank == 1) {
      bg = const Color(0xFFD4AF37); // Gold
      icon = Icons.emoji_events;
    } else if (rank == 2) {
      bg = const Color(0xFFC0C0C0); // Silver
      icon = Icons.workspace_premium;
    } else if (rank == 3) {
      bg = const Color(0xFFCD7F32); // Bronze
      icon = Icons.military_tech;
    } else {
      bg = Colors.grey.shade200;
      fg = Colors.grey.shade700;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, size: 18, color: fg)
          : Text(
              '$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
    );
  }

  Widget _buildEmptyLeaderboardState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.military_tech_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noLeaderboardEntries,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
