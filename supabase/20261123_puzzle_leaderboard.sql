-- =============================================================================
-- Migration: Art Puzzle Leaderboard & Server-Side Scoring for Atelier Gallery
-- File: supabase/20261123_puzzle_leaderboard.sql
-- =============================================================================

-- 1. PUZZLE SCORES TABLE
CREATE TABLE IF NOT EXISTS public.puzzle_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nickname TEXT NOT NULL,
    nickname_normalized TEXT NOT NULL,
    artwork_id UUID REFERENCES public.artworks(id) ON DELETE SET NULL,
    grid_size INT NOT NULL CHECK (grid_size IN (3, 4, 5)),
    duration_seconds INT NOT NULL CHECK (duration_seconds >= 1),
    moves_count INT NOT NULL CHECK (moves_count >= 1),
    points_earned INT NOT NULL CHECK (points_earned >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance & query optimization
CREATE INDEX IF NOT EXISTS idx_puzzle_scores_normalized ON public.puzzle_scores(nickname_normalized);
CREATE INDEX IF NOT EXISTS idx_puzzle_scores_grid_size ON public.puzzle_scores(grid_size);
CREATE INDEX IF NOT EXISTS idx_puzzle_scores_points ON public.puzzle_scores(points_earned DESC);
CREATE INDEX IF NOT EXISTS idx_puzzle_scores_created ON public.puzzle_scores(created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.puzzle_scores ENABLE ROW LEVEL SECURITY;

-- Grant privileges to anon and authenticated roles
GRANT SELECT, INSERT ON public.puzzle_scores TO anon, authenticated;
GRANT DELETE ON public.puzzle_scores TO authenticated;

-- RLS Policies
CREATE POLICY "Public Read Access for Puzzle Scores"
ON public.puzzle_scores FOR SELECT
USING (true);

CREATE POLICY "Public Insert Access for Puzzle Scores"
ON public.puzzle_scores FOR INSERT
WITH CHECK (true);

CREATE POLICY "Admin Delete Access for Puzzle Scores"
ON public.puzzle_scores FOR DELETE
TO authenticated
USING (true);


-- 2. SERVER-SIDE SCORING & VALIDATION RPC FUNCTION
CREATE OR REPLACE FUNCTION public.submit_puzzle_score(
    p_nickname TEXT,
    p_artwork_id UUID DEFAULT NULL,
    p_grid_size INT DEFAULT 3,
    p_duration_seconds INT DEFAULT 1,
    p_moves_count INT DEFAULT 1
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_trimmed TEXT;
    v_normalized TEXT;
    v_clean_len INT;
    v_base_points INT;
    v_target_seconds INT;
    v_target_moves INT;
    v_time_bonus INT := 0;
    v_move_bonus INT := 0;
    v_min_points INT;
    v_calculated_points INT;
    v_new_id UUID;
    v_total_points INT;
    v_puzzles_completed INT;
    v_prev_best_points INT;
    v_is_new_level_best BOOLEAN := FALSE;
BEGIN
    -- 1. Trim whitespace and normalize case
    v_trimmed := TRIM(COALESCE(p_nickname, ''));
    v_normalized := LOWER(v_trimmed);
    v_clean_len := CHAR_LENGTH(v_trimmed);

    -- Length validation: 2 to 15 characters
    IF v_clean_len < 2 OR v_clean_len > 15 THEN
        RAISE EXCEPTION 'Nickname must be between 2 and 15 characters long.';
    END IF;

    -- Prohibit web links and URLs
    IF v_normalized ~ '(http://|https://|www\.|\.com|\.org|\.net|\.io)' THEN
        RAISE EXCEPTION 'Web links are not allowed in nicknames.';
    END IF;

    -- Character validation: Latin, Cyrillic, digits, underscores, hyphens, spaces
    IF v_trimmed !~ '^[a-zA-Z0-9_\-\s\u0400-\u04FF]+$' THEN
        RAISE EXCEPTION 'Nickname contains invalid characters.';
    END IF;

    -- Validate grid size
    IF p_grid_size NOT IN (3, 4, 5) THEN
        RAISE EXCEPTION 'Invalid grid size. Allowed values: 3, 4, 5.';
    END IF;

    -- Validate minimum timing and moves
    IF p_duration_seconds < 1 THEN
        p_duration_seconds := 1;
    END IF;

    IF p_moves_count < 1 THEN
        p_moves_count := 1;
    END IF;

    -- Clamp max duration (e.g., 2 hours)
    IF p_duration_seconds > 7200 THEN
        p_duration_seconds := 7200;
    END IF;

    -- 2. Calculate Base Points & Bonuses Deterministically
    IF p_grid_size = 3 THEN
        v_base_points := 300;
        v_min_points := 100;
        v_target_seconds := 120;
        v_target_moves := 30;
    ELSIF p_grid_size = 4 THEN
        v_base_points := 600;
        v_min_points := 200;
        v_target_seconds := 240;
        v_target_moves := 60;
    ELSE -- 5x5
        v_base_points := 1000;
        v_min_points := 350;
        v_target_seconds := 450;
        v_target_moves := 120;
    END IF;

    -- Time bonus: 2 points per saved second under target
    IF p_duration_seconds < v_target_seconds THEN
        v_time_bonus := (v_target_seconds - p_duration_seconds) * 2;
    END IF;

    -- Move bonus: 5 points per saved move under target
    IF p_moves_count < v_target_moves THEN
        v_move_bonus := (v_target_moves - p_moves_count) * 5;
    END IF;

    v_calculated_points := GREATEST(v_min_points, v_base_points + v_time_bonus + v_move_bonus);

    -- Check if this run is a new personal level best
    SELECT MAX(points_earned) INTO v_prev_best_points
    FROM public.puzzle_scores
    WHERE nickname_normalized = v_normalized AND grid_size = p_grid_size;

    IF v_prev_best_points IS NULL OR v_calculated_points > v_prev_best_points THEN
        v_is_new_level_best := TRUE;
    END IF;

    -- 3. Insert Score Record
    INSERT INTO public.puzzle_scores (
        nickname,
        nickname_normalized,
        artwork_id,
        grid_size,
        duration_seconds,
        moves_count,
        points_earned
    ) VALUES (
        v_trimmed,
        v_normalized,
        p_artwork_id,
        p_grid_size,
        p_duration_seconds,
        p_moves_count,
        v_calculated_points
    )
    RETURNING id INTO v_new_id;

    -- 4. Calculate Updated Total Points & Solved Count
    SELECT COALESCE(SUM(points_earned), 0), COUNT(*)
    INTO v_total_points, v_puzzles_completed
    FROM public.puzzle_scores
    WHERE nickname_normalized = v_normalized;

    RETURN jsonb_build_object(
        'id', v_new_id,
        'nickname', v_trimmed,
        'nickname_normalized', v_normalized,
        'grid_size', p_grid_size,
        'duration_seconds', p_duration_seconds,
        'moves_count', p_moves_count,
        'points_earned', v_calculated_points,
        'total_points', v_total_points,
        'puzzles_completed', v_puzzles_completed,
        'is_new_level_best', v_is_new_level_best
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.submit_puzzle_score TO anon, authenticated;


-- 3. LEADERBOARD RETRIEVAL RPC FUNCTIONS

-- 3a. Total Points Leaderboard
CREATE OR REPLACE FUNCTION public.get_puzzle_total_leaderboard(p_limit INT DEFAULT 50)
RETURNS TABLE (
    rank BIGINT,
    nickname TEXT,
    nickname_normalized TEXT,
    total_points BIGINT,
    puzzles_completed BIGINT,
    last_played TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT
        ROW_NUMBER() OVER (ORDER BY SUM(points_earned) DESC, COUNT(*) DESC, MAX(created_at) ASC) AS rank,
        MAX(nickname) AS nickname,
        nickname_normalized,
        SUM(points_earned)::BIGINT AS total_points,
        COUNT(*)::BIGINT AS puzzles_completed,
        MAX(created_at) AS last_played
    FROM public.puzzle_scores
    GROUP BY nickname_normalized
    ORDER BY total_points DESC, puzzles_completed DESC, last_played ASC
    LIMIT GREATEST(1, LEAST(p_limit, 100));
$$;

GRANT EXECUTE ON FUNCTION public.get_puzzle_total_leaderboard TO anon, authenticated;

-- 3b. Best per Level Leaderboard
CREATE OR REPLACE FUNCTION public.get_puzzle_level_leaderboard(p_grid_size INT DEFAULT 3, p_limit INT DEFAULT 50)
RETURNS TABLE (
    rank BIGINT,
    nickname TEXT,
    nickname_normalized TEXT,
    best_points INT,
    best_duration INT,
    best_moves INT,
    puzzles_completed BIGINT,
    last_played TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT
        ROW_NUMBER() OVER (ORDER BY MAX(points_earned) DESC, MIN(duration_seconds) ASC, MIN(moves_count) ASC, MAX(created_at) ASC) AS rank,
        MAX(nickname) AS nickname,
        nickname_normalized,
        MAX(points_earned)::INT AS best_points,
        MIN(duration_seconds)::INT AS best_duration,
        MIN(moves_count)::INT AS best_moves,
        COUNT(*)::BIGINT AS puzzles_completed,
        MAX(created_at) AS last_played
    FROM public.puzzle_scores
    WHERE grid_size = p_grid_size
    GROUP BY nickname_normalized
    ORDER BY best_points DESC, best_duration ASC, best_moves ASC, last_played ASC
    LIMIT GREATEST(1, LEAST(p_limit, 100));
$$;

GRANT EXECUTE ON FUNCTION public.get_puzzle_level_leaderboard TO anon, authenticated;
