-- =============================================================================
-- Migration Script: Admin Panel Storage & RLS Security Policies
-- Timestamp: 2025-02-25 14:30:00
-- Purpose: Configure Supabase Storage bucket 'artworks' and verify Row Level
--          Security (RLS) policies for authenticated admin CRUD operations on
--          artworks, artist_profile, and guestbook moderation tables.
-- =============================================================================

-- 1. Create or ensure public 'artworks' storage bucket exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('artworks', 'artworks', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. Storage Object RLS Policies for 'artworks' bucket
DROP POLICY IF EXISTS "Public Read Access for Artworks Storage" ON storage.objects;
CREATE POLICY "Public Read Access for Artworks Storage"
ON storage.objects FOR SELECT
USING (bucket_id = 'artworks');

DROP POLICY IF EXISTS "Admin Upload Access for Artworks Storage" ON storage.objects;
CREATE POLICY "Admin Upload Access for Artworks Storage"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'artworks');

DROP POLICY IF EXISTS "Admin Update Access for Artworks Storage" ON storage.objects;
CREATE POLICY "Admin Update Access for Artworks Storage"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'artworks');

DROP POLICY IF EXISTS "Admin Delete Access for Artworks Storage" ON storage.objects;
CREATE POLICY "Admin Delete Access for Artworks Storage"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'artworks');

-- 3. Verify Table RLS Settings
ALTER TABLE public.artworks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.artist_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guestbook ENABLE ROW LEVEL SECURITY;

-- 3.1 Artworks Policies
DROP POLICY IF EXISTS "Public read access for artworks" ON public.artworks;
CREATE POLICY "Public read access for artworks"
    ON public.artworks FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Authenticated full access for artworks" ON public.artworks;
CREATE POLICY "Authenticated full access for artworks"
    ON public.artworks FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- 3.2 Artist Profile Policies
DROP POLICY IF EXISTS "Public read access for artist profile" ON public.artist_profile;
CREATE POLICY "Public read access for artist profile"
    ON public.artist_profile FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Authenticated full access for artist profile" ON public.artist_profile;
CREATE POLICY "Authenticated full access for artist profile"
    ON public.artist_profile FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- 3.3 Guestbook Policies
DROP POLICY IF EXISTS "Public read access for approved guestbook entries" ON public.guestbook;
CREATE POLICY "Public read access for approved guestbook entries"
    ON public.guestbook FOR SELECT
    USING (is_approved = true OR auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Public insert access for guestbook with pending approval" ON public.guestbook;
CREATE POLICY "Public insert access for guestbook with pending approval"
    ON public.guestbook FOR INSERT
    WITH CHECK (is_approved = false);

DROP POLICY IF EXISTS "Authenticated full access for guestbook" ON public.guestbook;
CREATE POLICY "Authenticated full access for guestbook"
    ON public.guestbook FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- 1. Enable Row Level Security on all gallery tables
alter table if exists public.artworks enable row level security;
alter table if exists public.artist_profile enable row level security;
alter table if exists public.guestbook enable row level security;

-- 2. Grant base table privileges to anon and authenticated roles
grant usage on schema public to anon, authenticated;

grant select on table public.artworks to anon;
grant select, insert, update, delete on table public.artworks to authenticated;

grant select on table public.artist_profile to anon;
grant select, insert, update, delete on table public.artist_profile to authenticated;

grant select, insert on table public.guestbook to anon;
grant select, insert, update, delete on table public.guestbook to authenticated;

-- Grant sequence privileges in case any table uses SERIAL / BIGSERIAL ids
grant usage, select on all sequences in schema public to anon, authenticated;

-- 3. Artworks RLS policies (public read, authenticated full CRUD)
drop policy if exists "Public can view artworks" on public.artworks;
create policy "Public can view artworks"
  on public.artworks
  for select
  to anon, authenticated
  using (true);

drop policy if exists "Authenticated can manage artworks" on public.artworks;
create policy "Authenticated can manage artworks"
  on public.artworks
  for all
  to authenticated
  using (true)
  with check (true);

-- 4. Artist profile RLS policies (public read, authenticated full CRUD)
drop policy if exists "Public can view artist profile" on public.artist_profile;
create policy "Public can view artist profile"
  on public.artist_profile
  for select
  to anon, authenticated
  using (true);

drop policy if exists "Authenticated can manage artist profile" on public.artist_profile;
create policy "Authenticated can manage artist profile"
  on public.artist_profile
  for all
  to authenticated
  using (true)
  with check (true);

-- 5. Guestbook RLS policies (public can view approved & submit unapproved; authenticated manages all)
drop policy if exists "Public can view approved guestbook entries" on public.guestbook;
create policy "Public can view approved guestbook entries"
  on public.guestbook
  for select
  to anon
  using (is_approved = true);

drop policy if exists "Public can submit guestbook entries" on public.guestbook;
create policy "Public can submit guestbook entries"
  on public.guestbook
  for insert
  to anon
  with check (is_approved = false);

drop policy if exists "Authenticated can manage guestbook entries" on public.guestbook;
create policy "Authenticated can manage guestbook entries"
  on public.guestbook
  for all
  to authenticated
  using (true)
  with check (true);
  
  drop policy if exists "Public can read artworks storage" on storage.objects;
create policy "Public can read artworks storage"
  on storage.objects
  for select
  to anon, authenticated
  using (bucket_id = 'artworks');

drop policy if exists "Authenticated can upload artworks storage" on storage.objects;
create policy "Authenticated can upload artworks storage"
  on storage.objects
  for insert
  to authenticated
  with check (bucket_id = 'artworks');

drop policy if exists "Authenticated can update artworks storage" on storage.objects;
create policy "Authenticated can update artworks storage"
  on storage.objects
  for update
  to authenticated
  using (bucket_id = 'artworks')
  with check (bucket_id = 'artworks');

drop policy if exists "Authenticated can delete artworks storage" on storage.objects;
create policy "Authenticated can delete artworks storage"
  on storage.objects
  for delete
  to authenticated
  using (bucket_id = 'artworks');
  
  alter table public.artworks
  add column if not exists dimensions text default '70 x 90 cm';

-- Reload PostgREST schema cache so Supabase immediately sees the new column
notify pgrst, 'reload schema';

alter table public.artworks
  add column if not exists title_mk text,
  add column if not exists title_en text,
  add column if not exists description_mk text,
  add column if not exists description_en text;

-- Backfill existing rows so nothing looks empty right after adding columns
update public.artworks
set
  title_mk = coalesce(title_mk, title),
  title_en = coalesce(title_en, title),
  description_mk = coalesce(description_mk, description),
  description_en = coalesce(description_en, description);

notify pgrst, 'reload schema';

-- 1. Enforce sensible length limits and block spam URLs at database level
do $$
declare
  v_name_col text;
begin
  select column_name
    into v_name_col
    from information_schema.columns
   where table_schema = 'public'
     and table_name = 'guestbook'
     and column_name in ('visitor_name', 'author_name', 'name', 'guest_name', 'sender_name')
   limit 1;

  alter table public.guestbook
    drop constraint if exists guestbook_name_length_check,
    drop constraint if exists guestbook_message_length_check,
    drop constraint if exists guestbook_no_links_check;

  if v_name_col is not null then
    execute format(
      'alter table public.guestbook add constraint guestbook_name_length_check check (char_length(trim(%I)) between 2 and 50)',
      v_name_col
    );
  end if;

  alter table public.guestbook
    add constraint guestbook_message_length_check
      check (char_length(trim(message)) between 5 and 500),
    add constraint guestbook_no_links_check
      check (message !~* '(https?://|www\.)');
end $$;

-- 2. Database-level rate limiter (max 1 submission per 20s and max 25 pending messages total)
create or replace function public.check_guestbook_rate_limit()
returns trigger
language plpgsql
security definer
as $$
declare
  recent_count integer;
  pending_count integer;
begin
  -- Block rapid burst submissions across the table
  select count(*)
    into recent_count
    from public.guestbook
   where created_at > now() - interval '20 seconds';

  if recent_count >= 1 then
    raise exception 'Too many submissions. Please wait a moment before sending another message.';
  end if;

  -- Cap total unapproved queue so admin panel can never be flooded
  select count(*)
    into pending_count
    from public.guestbook
   where is_approved = false;

  if pending_count >= 25 then
    raise exception 'Guestbook moderation queue is temporarily full.';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_guestbook_rate_limit on public.guestbook;
create trigger trg_guestbook_rate_limit
  before insert on public.guestbook
  for each row
  execute function public.check_guestbook_rate_limit();
  
  alter table public.guestbook
  add column if not exists is_approved boolean not null default false;

grant select, insert, update, delete on table public.guestbook to authenticated;
grant select, insert on table public.guestbook to anon;

drop policy if exists "Public can view approved guestbook entries" on public.guestbook;
create policy "Public can view approved guestbook entries"
  on public.guestbook
  for select
  to anon
  using (is_approved = true);

drop policy if exists "Authenticated can manage guestbook entries" on public.guestbook;
create policy "Authenticated can manage guestbook entries"
  on public.guestbook
  for all
  to authenticated
  using (true)
  with check (true);

notify pgrst, 'reload schema';

grant select, insert, update, delete on table public.guestbook to authenticated;

drop policy if exists "Authenticated can delete guestbook entries" on public.guestbook;
create policy "Authenticated can delete guestbook entries"
  on public.guestbook
  for delete
  to authenticated
  using (true);

-- Enable realtime updates on guestbook table if not already enabled
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'guestbook'
  ) then
    alter publication supabase_realtime add table public.guestbook;
  end if;
end $$;

notify pgrst, 'reload schema';