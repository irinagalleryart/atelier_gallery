-- =============================================================================
-- Migration: Anonymous Reactions and Moderated Artwork Comments for Atelier Gallery
-- File: supabase/20261122_reactions_and_comments.sql
-- =============================================================================

-- 1. ARTWORK REACTIONS TABLE
CREATE TABLE IF NOT EXISTS public.artwork_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    artwork_id UUID REFERENCES public.artworks(id) ON DELETE CASCADE NOT NULL,
    visitor_id TEXT NOT NULL,
    reaction_type TEXT NOT NULL CHECK (reaction_type IN ('like', 'love', 'magical', 'artistic', 'emotional')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_visitor_artwork_reaction UNIQUE (artwork_id, visitor_id, reaction_type)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_artwork_reactions_artwork_id ON public.artwork_reactions(artwork_id);
CREATE INDEX IF NOT EXISTS idx_artwork_reactions_visitor_id ON public.artwork_reactions(visitor_id);

-- Enable RLS for artwork_reactions
ALTER TABLE public.artwork_reactions ENABLE ROW LEVEL SECURITY;

-- Grant table privileges to anon and authenticated roles
GRANT SELECT, INSERT, DELETE ON public.artwork_reactions TO anon, authenticated;

-- RLS Policies for artwork_reactions
CREATE POLICY "Public Read Access for Artwork Reactions"
ON public.artwork_reactions FOR SELECT
USING (true);

CREATE POLICY "Public Insert Access for Artwork Reactions"
ON public.artwork_reactions FOR INSERT
WITH CHECK (true);

CREATE POLICY "Public Delete Access for Artwork Reactions"
ON public.artwork_reactions FOR DELETE
USING (true);


-- 2. ARTWORK COMMENTS TABLE
CREATE TABLE IF NOT EXISTS public.artwork_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    artwork_id UUID REFERENCES public.artworks(id) ON DELETE CASCADE NOT NULL,
    visitor_id TEXT,
    author_name TEXT NOT NULL,
    comment_text TEXT NOT NULL,
    is_approved BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_artwork_comments_artwork_id ON public.artwork_comments(artwork_id);
CREATE INDEX IF NOT EXISTS idx_artwork_comments_is_approved ON public.artwork_comments(is_approved);
CREATE INDEX IF NOT EXISTS idx_artwork_comments_created_at ON public.artwork_comments(created_at DESC);

-- Enable RLS for artwork_comments
ALTER TABLE public.artwork_comments ENABLE ROW LEVEL SECURITY;

-- Grant table privileges to anon and authenticated roles
GRANT SELECT, INSERT, UPDATE, DELETE ON public.artwork_comments TO anon, authenticated;

-- RLS Policies for artwork_comments
CREATE POLICY "Public Read Approved Artwork Comments"
ON public.artwork_comments FOR SELECT
USING (is_approved = true OR auth.role() = 'authenticated');

CREATE POLICY "Public Insert Artwork Comments"
ON public.artwork_comments FOR INSERT
WITH CHECK (is_approved = false);

CREATE POLICY "Admin Update Artwork Comments"
ON public.artwork_comments FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Admin Delete Artwork Comments"
ON public.artwork_comments FOR DELETE
TO authenticated
USING (true);

-- Grant table privileges to anon and authenticated roles
GRANT SELECT, INSERT, DELETE ON public.artwork_reactions TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.artwork_comments TO anon, authenticated;