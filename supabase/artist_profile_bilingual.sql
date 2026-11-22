-- =============================================================================
-- Migration: Bilingual Artist Profile Fields for Atelier Gallery
-- File: supabase/artist_profile_bilingual.sql
-- =============================================================================

-- 1. Add bilingual columns to artist_profile if they do not exist
ALTER TABLE public.artist_profile
    ADD COLUMN IF NOT EXISTS artist_name_mk TEXT,
    ADD COLUMN IF NOT EXISTS artist_name_en TEXT,
    ADD COLUMN IF NOT EXISTS bio_mk TEXT,
    ADD COLUMN IF NOT EXISTS bio_en TEXT,
    ADD COLUMN IF NOT EXISTS art_school_mk TEXT,
    ADD COLUMN IF NOT EXISTS art_school_en TEXT,
    ADD COLUMN IF NOT EXISTS favorite_techniques_mk TEXT,
    ADD COLUMN IF NOT EXISTS favorite_techniques_en TEXT;

-- 2. Safe backfill from existing single-language columns
UPDATE public.artist_profile
SET
    artist_name_mk = COALESCE(artist_name_mk, artist_name, 'Atelier Artist'),
    artist_name_en = COALESCE(artist_name_en, artist_name, 'Atelier Artist'),
    bio_mk = COALESCE(bio_mk, bio, 'Contemporary painter exploring texture, light, and atmosphere.'),
    bio_en = COALESCE(bio_en, bio, 'Contemporary painter exploring texture, light, and atmosphere.'),
    art_school_mk = COALESCE(art_school_mk, art_school, 'Faculty of Fine Arts'),
    art_school_en = COALESCE(art_school_en, art_school, 'Faculty of Fine Arts'),
    favorite_techniques_mk = COALESCE(favorite_techniques_mk, favorite_techniques, 'Oil on Canvas, Acrylic, Mixed Media'),
    favorite_techniques_en = COALESCE(favorite_techniques_en, favorite_techniques, 'Oil on Canvas, Acrylic, Mixed Media')
WHERE id = 1;

-- 3. Ensure RLS is enabled and policies are in place
ALTER TABLE public.artist_profile ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON TABLE public.artist_profile TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.artist_profile TO authenticated;

DROP POLICY IF EXISTS "Public read access for artist profile" ON public.artist_profile;
CREATE POLICY "Public read access for artist profile"
ON public.artist_profile FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Authenticated full access for artist profile" ON public.artist_profile;
CREATE POLICY "Authenticated full access for artist profile"
ON public.artist_profile FOR ALL
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');
