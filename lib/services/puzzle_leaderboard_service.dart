import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Leaderboard entry for cumulative total points across all grid sizes.
class PuzzleTotalEntry {
  final int rank;
  final String nickname;
  final String nicknameNormalized;
  final int totalPoints;
  final int puzzlesCompleted;
  final DateTime? lastPlayed;

  const PuzzleTotalEntry({
    required this.rank,
    required this.nickname,
    required this.nicknameNormalized,
    required this.totalPoints,
    required this.puzzlesCompleted,
    this.lastPlayed,
  });

  factory PuzzleTotalEntry.fromJson(Map<String, dynamic> json, int defaultRank) {
    return PuzzleTotalEntry(
      rank: json['rank'] != null ? (json['rank'] as num).toInt() : defaultRank,
      nickname: json['nickname'] as String? ?? 'Anonymous',
      nicknameNormalized: json['nickname_normalized'] as String? ?? '',
      totalPoints: json['total_points'] != null ? (json['total_points'] as num).toInt() : 0,
      puzzlesCompleted: json['puzzles_completed'] != null ? (json['puzzles_completed'] as num).toInt() : 0,
      lastPlayed: json['last_played'] != null
          ? DateTime.tryParse(json['last_played'].toString())
          : null,
    );
  }
}

/// Leaderboard entry for best score per individual grid level (3x3, 4x4, 5x5).
class PuzzleLevelEntry {
  final int rank;
  final String nickname;
  final String nicknameNormalized;
  final int bestPoints;
  final int bestDuration;
  final int bestMoves;
  final int puzzlesCompleted;
  final DateTime? lastPlayed;

  const PuzzleLevelEntry({
    required this.rank,
    required this.nickname,
    required this.nicknameNormalized,
    required this.bestPoints,
    required this.bestDuration,
    required this.bestMoves,
    required this.puzzlesCompleted,
    this.lastPlayed,
  });

  factory PuzzleLevelEntry.fromJson(Map<String, dynamic> json, int defaultRank) {
    return PuzzleLevelEntry(
      rank: json['rank'] != null ? (json['rank'] as num).toInt() : defaultRank,
      nickname: json['nickname'] as String? ?? 'Anonymous',
      nicknameNormalized: json['nickname_normalized'] as String? ?? '',
      bestPoints: json['best_points'] != null ? (json['best_points'] as num).toInt() : 0,
      bestDuration: json['best_duration'] != null ? (json['best_duration'] as num).toInt() : 0,
      bestMoves: json['best_moves'] != null ? (json['best_moves'] as num).toInt() : 0,
      puzzlesCompleted: json['puzzles_completed'] != null ? (json['puzzles_completed'] as num).toInt() : 0,
      lastPlayed: json['last_played'] != null
          ? DateTime.tryParse(json['last_played'].toString())
          : null,
    );
  }
}

/// Raw score entry for Admin moderation & inspection.
class PuzzleAdminScoreEntry {
  final String id;
  final String nickname;
  final String nicknameNormalized;
  final int gridSize;
  final int durationSeconds;
  final int movesCount;
  final int pointsEarned;
  final DateTime createdAt;

  const PuzzleAdminScoreEntry({
    required this.id,
    required this.nickname,
    required this.nicknameNormalized,
    required this.gridSize,
    required this.durationSeconds,
    required this.movesCount,
    required this.pointsEarned,
    required this.createdAt,
  });

  factory PuzzleAdminScoreEntry.fromJson(Map<String, dynamic> json) {
    return PuzzleAdminScoreEntry(
      id: json['id']?.toString() ?? '',
      nickname: json['nickname'] as String? ?? 'Anonymous',
      nicknameNormalized: json['nickname_normalized'] as String? ?? '',
      gridSize: json['grid_size'] != null ? (json['grid_size'] as num).toInt() : 3,
      durationSeconds: json['duration_seconds'] != null ? (json['duration_seconds'] as num).toInt() : 0,
      movesCount: json['moves_count'] != null ? (json['moves_count'] as num).toInt() : 0,
      pointsEarned: json['points_earned'] != null ? (json['points_earned'] as num).toInt() : 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Result payload returned after submitting a puzzle score.
class PuzzleSubmissionResult {
  final String id;
  final String nickname;
  final String nicknameNormalized;
  final int gridSize;
  final int durationSeconds;
  final int movesCount;
  final int pointsEarned;
  final int totalPoints;
  final int puzzlesCompleted;
  final bool isNewLevelBest;
  final bool isOffline;

  const PuzzleSubmissionResult({
    required this.id,
    required this.nickname,
    required this.nicknameNormalized,
    required this.gridSize,
    required this.durationSeconds,
    required this.movesCount,
    required this.pointsEarned,
    required this.totalPoints,
    required this.puzzlesCompleted,
    required this.isNewLevelBest,
    this.isOffline = false,
  });

  factory PuzzleSubmissionResult.fromJson(Map<String, dynamic> json) {
    return PuzzleSubmissionResult(
      id: json['id']?.toString() ?? '',
      nickname: json['nickname'] as String? ?? '',
      nicknameNormalized: json['nickname_normalized'] as String? ?? '',
      gridSize: json['grid_size'] != null ? (json['grid_size'] as num).toInt() : 3,
      durationSeconds: json['duration_seconds'] != null ? (json['duration_seconds'] as num).toInt() : 0,
      movesCount: json['moves_count'] != null ? (json['moves_count'] as num).toInt() : 0,
      pointsEarned: json['points_earned'] != null ? (json['points_earned'] as num).toInt() : 0,
      totalPoints: json['total_points'] != null ? (json['total_points'] as num).toInt() : 0,
      puzzlesCompleted: json['puzzles_completed'] != null ? (json['puzzles_completed'] as num).toInt() : 0,
      isNewLevelBest: json['is_new_level_best'] as bool? ?? false,
      isOffline: false,
    );
  }
}

/// Service managing Art Puzzle nickname storage, score submission, and leaderboard fetching.
class PuzzleLeaderboardService {
  static const String _nicknameKey = 'art_puzzle_player_nickname';

  /// Trims and converts nickname to lowercase for consistent grouping.
  static String normalizeNickname(String nickname) {
    return nickname.trim().toLowerCase();
  }

  /// Validates nickname rules (length 2-15, allowed chars, no URLs).
  /// Returns null if valid, or a descriptive error code string if invalid.
  static String? validateNickname(String nickname) {
    final trimmed = nickname.trim();
    final len = trimmed.length;
    if (len < 2 || len > 15) {
      return 'length_error';
    }

    final normalized = trimmed.toLowerCase();
    if (normalized.contains('http://') ||
        normalized.contains('https://') ||
        normalized.contains('www.') ||
        normalized.contains('.com') ||
        normalized.contains('.org') ||
        normalized.contains('.net')) {
      return 'url_error';
    }

    // Allow Latin, Cyrillic, numbers, spaces, _ and -
    final validCharRegExp = RegExp(r'^[a-zA-Z0-9_\-\s\u0400-\u04FF]+$');
    if (!validCharRegExp.hasMatch(trimmed)) {
      return 'char_error';
    }

    return null;
  }

  /// Retrieves the persisted nickname from local storage.
  static Future<String?> getSavedNickname() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nickname = prefs.getString(_nicknameKey);
      if (nickname != null && nickname.trim().isNotEmpty) {
        return nickname.trim();
      }
    } catch (e) {
      debugPrint('Error reading saved nickname: $e');
    }
    return null;
  }

  /// Persists a valid nickname to local storage.
  static Future<bool> saveNickname(String nickname) async {
    try {
      final trimmed = nickname.trim();
      if (validateNickname(trimmed) == null) {
        final prefs = await SharedPreferences.getInstance();
        return await prefs.setString(_nicknameKey, trimmed);
      }
    } catch (e) {
      debugPrint('Error saving nickname: $e');
    }
    return false;
  }

  /// Calculates points deterministically based on grid size, duration, and moves count.
  static int calculatePoints({
    required int gridSize,
    required int durationSeconds,
    required int movesCount,
  }) {
    int basePoints;
    int minPoints;
    int targetSeconds;
    int targetMoves;

    if (gridSize == 3) {
      basePoints = 300;
      minPoints = 100;
      targetSeconds = 120;
      targetMoves = 30;
    } else if (gridSize == 4) {
      basePoints = 600;
      minPoints = 200;
      targetSeconds = 240;
      targetMoves = 60;
    } else {
      basePoints = 1000;
      minPoints = 350;
      targetSeconds = 450;
      targetMoves = 120;
    }

    int timeBonus = 0;
    if (durationSeconds < targetSeconds) {
      timeBonus = (targetSeconds - durationSeconds) * 2;
    }

    int moveBonus = 0;
    if (movesCount < targetMoves) {
      moveBonus = (targetMoves - movesCount) * 5;
    }

    final total = basePoints + timeBonus + moveBonus;
    return total < minPoints ? minPoints : total;
  }

  /// Submits a completed puzzle score to Supabase using the server-side RPC function.
  /// Falls back gracefully to local storage if Supabase is offline or unavailable.
  static Future<PuzzleSubmissionResult> submitScore({
    required String nickname,
    String? artworkId,
    required int gridSize,
    required int durationSeconds,
    required int movesCount,
  }) async {
    final trimmedNickname = nickname.trim();
    final normalized = normalizeNickname(trimmedNickname);
    final calculatedPoints = calculatePoints(
      gridSize: gridSize,
      durationSeconds: durationSeconds,
      movesCount: movesCount,
    );

    // Save locally to SharedPreferences as backup
    await saveNickname(trimmedNickname);
    final prefs = await SharedPreferences.getInstance();

    final localTotalKey = 'puzzle_local_total_points_$normalized';
    final localSolvedKey = 'puzzle_local_solved_count_$normalized';
    final localLevelBestKey = 'puzzle_local_best_points_${normalized}_$gridSize';

    final prevTotal = prefs.getInt(localTotalKey) ?? 0;
    final prevSolved = prefs.getInt(localSolvedKey) ?? 0;
    final prevBest = prefs.getInt(localLevelBestKey) ?? 0;

    final newTotal = prevTotal + calculatedPoints;
    final newSolved = prevSolved + 1;
    final isNewBest = calculatedPoints > prevBest;

    await prefs.setInt(localTotalKey, newTotal);
    await prefs.setInt(localSolvedKey, newSolved);
    if (isNewBest) {
      await prefs.setInt(localLevelBestKey, calculatedPoints);
    }

    // Attempt Supabase RPC submission
    if (SupabaseService.isInitialized) {
      try {
        final Map<String, dynamic> params = {
          'p_nickname': trimmedNickname,
          'p_artwork_id': (artworkId != null && artworkId.isNotEmpty) ? artworkId : null,
          'p_grid_size': gridSize,
          'p_duration_seconds': durationSeconds,
          'p_moves_count': movesCount,
        };

        final response = await SupabaseService.client
            .rpc('submit_puzzle_score', params: params);

        if (response != null && response is Map<String, dynamic>) {
          return PuzzleSubmissionResult.fromJson(response);
        }
      } catch (e) {
        debugPrint('PuzzleLeaderboardService: RPC submit failed ($e). Using local fallback.');
      }
    }

    // Local fallback result if Supabase RPC call is unavailable or fails
    return PuzzleSubmissionResult(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      nickname: trimmedNickname,
      nicknameNormalized: normalized,
      gridSize: gridSize,
      durationSeconds: durationSeconds,
      movesCount: movesCount,
      pointsEarned: calculatedPoints,
      totalPoints: newTotal,
      puzzlesCompleted: newSolved,
      isNewLevelBest: isNewBest,
      isOffline: true,
    );
  }

  /// Fetches the Total Points Leaderboard.
  static Future<List<PuzzleTotalEntry>> fetchTotalLeaderboard({int limit = 50}) async {
    if (SupabaseService.isInitialized) {
      try {
        final List response = await SupabaseService.client.rpc(
          'get_puzzle_total_leaderboard',
          params: {'p_limit': limit},
        );

        int rank = 1;
        return response
            .map((item) => PuzzleTotalEntry.fromJson(
                  Map<String, dynamic>.from(item as Map),
                  rank++,
                ))
            .toList();
      } catch (e) {
        debugPrint('PuzzleLeaderboardService: RPC total leaderboard failed ($e). Trying table fallback.');
        try {
          // Direct table query fallback
          final List response = await SupabaseService.client
              .from('puzzle_scores')
              .select('nickname, nickname_normalized, points_earned, created_at')
              .order('created_at', ascending: false)
              .limit(500);

          final Map<String, _AggregateUser> aggregated = {};
          for (final row in response) {
            final nick = row['nickname'] as String? ?? 'Anonymous';
            final norm = row['nickname_normalized'] as String? ?? normalizeNickname(nick);
            final pts = (row['points_earned'] as num? ?? 0).toInt();
            final date = row['created_at'] != null
                ? DateTime.tryParse(row['created_at'].toString())
                : null;

            if (!aggregated.containsKey(norm)) {
              aggregated[norm] = _AggregateUser(nick, norm);
            }
            final user = aggregated[norm]!;
            user.totalPoints += pts;
            user.puzzlesCompleted += 1;
            if (date != null && (user.lastPlayed == null || date.isAfter(user.lastPlayed!))) {
              user.lastPlayed = date;
            }
          }

          final list = aggregated.values.toList();
          list.sort((a, b) {
            final cmp = b.totalPoints.compareTo(a.totalPoints);
            if (cmp != 0) return cmp;
            return b.puzzlesCompleted.compareTo(a.puzzlesCompleted);
          });

          int rank = 1;
          return list
              .take(limit)
              .map((u) => PuzzleTotalEntry(
                    rank: rank++,
                    nickname: u.nickname,
                    nicknameNormalized: u.nicknameNormalized,
                    totalPoints: u.totalPoints,
                    puzzlesCompleted: u.puzzlesCompleted,
                    lastPlayed: u.lastPlayed,
                  ))
              .toList();
        } catch (e2) {
          debugPrint('PuzzleLeaderboardService: Table fallback failed ($e2).');
        }
      }
    }

    return _getLocalTotalLeaderboard();
  }

  /// Fetches the Best per Level Leaderboard.
  static Future<List<PuzzleLevelEntry>> fetchLevelLeaderboard({
    required int gridSize,
    int limit = 50,
  }) async {
    if (SupabaseService.isInitialized) {
      try {
        final List response = await SupabaseService.client.rpc(
          'get_puzzle_level_leaderboard',
          params: {
            'p_grid_size': gridSize,
            'p_limit': limit,
          },
        );

        int rank = 1;
        return response
            .map((item) => PuzzleLevelEntry.fromJson(
                  Map<String, dynamic>.from(item as Map),
                  rank++,
                ))
            .toList();
      } catch (e) {
        debugPrint('PuzzleLeaderboardService: RPC level leaderboard failed ($e). Trying table fallback.');
        try {
          final List response = await SupabaseService.client
              .from('puzzle_scores')
              .select('nickname, nickname_normalized, grid_size, duration_seconds, moves_count, points_earned, created_at')
              .eq('grid_size', gridSize)
              .order('points_earned', ascending: false)
              .limit(500);

          final Map<String, _AggregateLevelUser> aggregated = {};
          for (final row in response) {
            final nick = row['nickname'] as String? ?? 'Anonymous';
            final norm = row['nickname_normalized'] as String? ?? normalizeNickname(nick);
            final pts = (row['points_earned'] as num? ?? 0).toInt();
            final dur = (row['duration_seconds'] as num? ?? 0).toInt();
            final moves = (row['moves_count'] as num? ?? 0).toInt();
            final date = row['created_at'] != null
                ? DateTime.tryParse(row['created_at'].toString())
                : null;

            if (!aggregated.containsKey(norm)) {
              aggregated[norm] = _AggregateLevelUser(nick, norm);
            }
            final user = aggregated[norm]!;
            user.puzzlesCompleted += 1;
            if (pts > user.bestPoints) {
              user.bestPoints = pts;
              user.bestDuration = dur;
              user.bestMoves = moves;
            }
            if (date != null && (user.lastPlayed == null || date.isAfter(user.lastPlayed!))) {
              user.lastPlayed = date;
            }
          }

          final list = aggregated.values.toList();
          list.sort((a, b) {
            final cmp = b.bestPoints.compareTo(a.bestPoints);
            if (cmp != 0) return cmp;
            final durCmp = a.bestDuration.compareTo(b.bestDuration);
            if (durCmp != 0) return durCmp;
            return a.bestMoves.compareTo(b.bestMoves);
          });

          int rank = 1;
          return list
              .take(limit)
              .map((u) => PuzzleLevelEntry(
                    rank: rank++,
                    nickname: u.nickname,
                    nicknameNormalized: u.nicknameNormalized,
                    bestPoints: u.bestPoints,
                    bestDuration: u.bestDuration,
                    bestMoves: u.bestMoves,
                    puzzlesCompleted: u.puzzlesCompleted,
                    lastPlayed: u.lastPlayed,
                  ))
              .toList();
        } catch (e2) {
          debugPrint('PuzzleLeaderboardService: Table level fallback failed ($e2).');
        }
      }
    }

    return _getLocalLevelLeaderboard(gridSize);
  }

  /// Sets up a Supabase Realtime channel to listen for updates on the puzzle_scores table.
  static RealtimeChannel? subscribeToUpdates(VoidCallback onUpdate) {
    if (!SupabaseService.isInitialized) return null;
    try {
      final channelName = 'puzzle_scores_realtime_${DateTime.now().millisecondsSinceEpoch}';
      final channel = SupabaseService.client.channel(channelName);
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'puzzle_scores',
        callback: (payload) {
          onUpdate();
        },
      );
      channel.subscribe();
      return channel;
    } catch (e) {
      debugPrint('Realtime subscription error: $e');
      return null;
    }
  }

  /// Fetches raw score entries for Admin inspection & deletion.
  static Future<List<PuzzleAdminScoreEntry>> fetchAdminScoreEntries({
    String? searchQuery,
    int limit = 100,
  }) async {
    if (!SupabaseService.isInitialized) return [];

    try {
      var query = SupabaseService.client
          .from('puzzle_scores')
          .select('id, nickname, nickname_normalized, grid_size, duration_seconds, moves_count, points_earned, created_at');

      final trimmedSearch = searchQuery?.trim();
      if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
        query = query.ilike('nickname', '%$trimmedSearch%');
      }

      final List response = await query.order('created_at', ascending: false).limit(limit);

      return response
          .map((item) => PuzzleAdminScoreEntry.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      debugPrint('PuzzleLeaderboardService: fetchAdminScoreEntries failed ($e)');
      rethrow;
    }
  }

  /// Deletes a single score entry by ID.
  static Future<void> deleteScoreEntry(String id) async {
    if (!SupabaseService.isInitialized) return;
    await SupabaseService.client.from('puzzle_scores').delete().eq('id', id);
  }

  /// Deletes all puzzle score entries for a specific nickname.
  static Future<void> deleteAllScoresForNickname(String nicknameNormalized) async {
    if (!SupabaseService.isInitialized) return;
    await SupabaseService.client
        .from('puzzle_scores')
        .delete()
        .eq('nickname_normalized', nicknameNormalized.trim().toLowerCase());
  }

  /// Helper to return local leaderboard if offline.
  static Future<List<PuzzleTotalEntry>> _getLocalTotalLeaderboard() async {
    final nick = await getSavedNickname();
    if (nick == null || nick.isEmpty) return [];

    final norm = normalizeNickname(nick);
    final prefs = await SharedPreferences.getInstance();
    final totalPts = prefs.getInt('puzzle_local_total_points_$norm') ?? 0;
    final solved = prefs.getInt('puzzle_local_solved_count_$norm') ?? 0;

    if (totalPts == 0 && solved == 0) return [];

    return [
      PuzzleTotalEntry(
        rank: 1,
        nickname: nick,
        nicknameNormalized: norm,
        totalPoints: totalPts,
        puzzlesCompleted: solved,
        lastPlayed: DateTime.now(),
      )
    ];
  }

  /// Helper to return local level leaderboard if offline.
  static Future<List<PuzzleLevelEntry>> _getLocalLevelLeaderboard(int gridSize) async {
    final nick = await getSavedNickname();
    if (nick == null || nick.isEmpty) return [];

    final norm = normalizeNickname(nick);
    final prefs = await SharedPreferences.getInstance();
    final bestPts = prefs.getInt('puzzle_local_best_points_${norm}_$gridSize') ?? 0;
    final solved = prefs.getInt('puzzle_local_solved_count_$norm') ?? 0;

    if (bestPts == 0) return [];

    return [
      PuzzleLevelEntry(
        rank: 1,
        nickname: nick,
        nicknameNormalized: norm,
        bestPoints: bestPts,
        bestDuration: 0,
        bestMoves: 0,
        puzzlesCompleted: solved,
        lastPlayed: DateTime.now(),
      )
    ];
  }
}

class _AggregateUser {
  final String nickname;
  final String nicknameNormalized;
  int totalPoints = 0;
  int puzzlesCompleted = 0;
  DateTime? lastPlayed;

  _AggregateUser(this.nickname, this.nicknameNormalized);
}

class _AggregateLevelUser {
  final String nickname;
  final String nicknameNormalized;
  int bestPoints = 0;
  int bestDuration = 0;
  int bestMoves = 0;
  int puzzlesCompleted = 0;
  DateTime? lastPlayed;

  _AggregateLevelUser(this.nickname, this.nicknameNormalized);
}
