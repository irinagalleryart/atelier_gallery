-- =============================================================================
-- Supabase Schema & Security Setup for Atelier Gallery
-- File: supabase/schema.sql
-- Description: Idempotent and repeatable SQL setup script for artworks,
--              guestbook, and artist_profile tables with Row Level Security (RLS).
-- =============================================================================

/*
--------------------------------------------------------------------------------
STORAGE BUCKET & POLICY INSTRUCTIONS
--------------------------------------------------------------------------------
To host artwork images, create a public storage bucket named 'artworks' in Supabase.

1. Via Supabase Dashboard:
   - Navigate to Storage -> Buckets -> "New Bucket".
   - Name: `artworks`
   - Toggle "Public bucket" to ON.
   - Click "Save".

2. Storage Row Level Security (RLS) Policies for `storage.objects`:
   Run the following SQL snippet in the Supabase SQL Editor to configure bucket permissions:

   -- Enable public read access to the 'artworks' bucket
   CREATE POLICY "Public Read Access for Artworks Storage"
   ON storage.objects FOR SELECT
   USING (bucket_id = 'artworks');

   -- Allow authenticated users (admins) to upload images to 'artworks' bucket
   CREATE POLICY "Admin Upload Access for Artworks Storage"
   ON storage.objects FOR INSERT
   TO authenticated
   WITH CHECK (bucket_id = 'artworks');

   -- Allow authenticated users (admins) to update images in 'artworks' bucket
   CREATE POLICY "Admin Update Access for Artworks Storage"
   ON storage.objects FOR UPDATE
   TO authenticated
   USING (bucket_id = 'artworks');

   -- Allow authenticated users (admins) to delete images from 'artworks' bucket
   CREATE POLICY "Admin Delete Access for Artworks Storage"
   ON storage.objects FOR DELETE
   TO authenticated
   USING (bucket_id = 'artworks');
--------------------------------------------------------------------------------
*/

-- Enable pgcrypto extension for UUID generation if needed
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- -----------------------------------------------------------------------------
-- 1. ARTWORKS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.artworks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    technique TEXT,
    created_year INT,
    image_url TEXT,
    is_featured BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_artworks_is_featured ON public.artworks(is_featured);
CREATE INDEX IF NOT EXISTS idx_artworks_created_at ON public.artworks(created_at DESC);

-- -----------------------------------------------------------------------------
-- 2. GUESTBOOK TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.guestbook (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_name TEXT NOT NULL,
    message TEXT NOT NULL,
    artwork_id UUID REFERENCES public.artworks(id) ON DELETE SET NULL,
    is_approved BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_guestbook_artwork_id ON public.guestbook(artwork_id);
CREATE INDEX IF NOT EXISTS idx_guestbook_is_approved ON public.guestbook(is_approved);
CREATE INDEX IF NOT EXISTS idx_guestbook_created_at ON public.guestbook(created_at DESC);

-- -----------------------------------------------------------------------------
-- 3. ARTIST PROFILE TABLE (Single-Row Enforcement)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.artist_profile (
    id INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    artist_name TEXT NOT NULL,
    bio TEXT,
    art_school TEXT,
    favorite_techniques TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Safe initial seed row for artist_profile
INSERT INTO public.artist_profile (id, artist_name, bio, art_school, favorite_techniques, updated_at)
VALUES (
    1,
    'Atelier Artist',
    'Welcome to the official gallery profile of Atelier Gallery.',
    'Faculty of Fine Arts',
    'Oil on Canvas, Acrylic, Mixed Media',
    NOW()
)
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 4. ROW LEVEL SECURITY (RLS) & POLICIES
-- -----------------------------------------------------------------------------

-- Enable RLS on all tables
ALTER TABLE public.artworks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guestbook ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.artist_profile ENABLE ROW LEVEL SECURITY;

-- 4.1 Policies for `artworks`
DROP POLICY IF EXISTS "Public read access for artworks" ON public.artworks;
CREATE POLICY "Public read access for artworks"
    ON public.artworks
    FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Authenticated full access for artworks" ON public.artworks;
CREATE POLICY "Authenticated full access for artworks"
    ON public.artworks
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- 4.2 Policies for `guestbook`
DROP POLICY IF EXISTS "Public read access for approved guestbook entries" ON public.guestbook;
CREATE POLICY "Public read access for approved guestbook entries"
    ON public.guestbook
    FOR SELECT
    USING (is_approved = true);

DROP POLICY IF EXISTS "Public insert access for guestbook with pending approval" ON public.guestbook;
CREATE POLICY "Public insert access for guestbook with pending approval"
    ON public.guestbook
    FOR INSERT
    WITH CHECK (is_approved = false);

DROP POLICY IF EXISTS "Authenticated full access for guestbook" ON public.guestbook;
CREATE POLICY "Authenticated full access for guestbook"
    ON public.guestbook
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- 4.3 Policies for `artist_profile`
DROP POLICY IF EXISTS "Public read access for artist profile" ON public.artist_profile;
CREATE POLICY "Public read access for artist profile"
    ON public.artist_profile
    FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Authenticated full access for artist profile" ON public.artist_profile;
CREATE POLICY "Authenticated full access for artist profile"
    ON public.artist_profile
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);
