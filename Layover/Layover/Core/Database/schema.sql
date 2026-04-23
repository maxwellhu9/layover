-- ==============================================
-- Layover — Supabase Database Setup
-- Run this in Supabase SQL Editor
-- ==============================================

-- 1. Profiles (auto-created on sign-up via trigger)
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    full_name text,
    email text,
    created_at timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "Users can read own profile"
    on public.profiles for select
    using (auth.uid() = id);

create policy "Users can update own profile"
    on public.profiles for update
    using (auth.uid() = id);

-- Auto-create a profile row when a new user signs up
create or replace function public.handle_new_user()
returns trigger as $$
begin
    insert into public.profiles (id, email, full_name)
    values (
        new.id,
        new.email,
        coalesce(new.raw_user_meta_data ->> 'full_name', '')
    );
    return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();


-- 2. Favorites (saved places)
create table if not exists public.favorites (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    place_id text not null,            -- Google Places API ID
    name text not null,
    address text,
    rating float8,
    latitude float8 not null,
    longitude float8 not null,
    category text,                     -- e.g. "restaurant", "tourist_attraction"
    created_at timestamptz default now(),

    unique(user_id, place_id)          -- prevent duplicate saves
);

alter table public.favorites enable row level security;

create policy "Users can read own favorites"
    on public.favorites for select
    using (auth.uid() = user_id);

create policy "Users can insert own favorites"
    on public.favorites for insert
    with check (auth.uid() = user_id);

create policy "Users can delete own favorites"
    on public.favorites for delete
    using (auth.uid() = user_id);


-- 3. Recent searches (optional — track what users searched for)
create table if not exists public.recent_searches (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    category text not null,
    latitude float8 not null,
    longitude float8 not null,
    radius_meters int,
    results_count int,
    created_at timestamptz default now()
);

alter table public.recent_searches enable row level security;

create policy "Users can read own searches"
    on public.recent_searches for select
    using (auth.uid() = user_id);

create policy "Users can insert own searches"
    on public.recent_searches for insert
    with check (auth.uid() = user_id);


-- 4. Reviews (user-generated tips/reviews for places)
create table if not exists public.reviews (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    place_id text not null,
    rating int not null check (rating >= 1 and rating <= 5),
    text text not null default '',
    user_name text,
    created_at timestamptz default now(),

    unique(user_id, place_id)  -- one review per user per place
);

alter table public.reviews enable row level security;

create policy "Anyone can read reviews"
    on public.reviews for select
    using (true);

create policy "Authenticated users can insert reviews"
    on public.reviews for insert
    with check (auth.uid() = user_id);

create policy "Users can update own reviews"
    on public.reviews for update
    using (auth.uid() = user_id);

create policy "Users can delete own reviews"
    on public.reviews for delete
    using (auth.uid() = user_id);


-- 5. Itineraries (saved layover plans)
create table if not exists public.itineraries (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    name text not null default 'My Layover',
    departure_time timestamptz not null,
    created_at timestamptz default now()
);

alter table public.itineraries enable row level security;

create policy "Users can read own itineraries"
    on public.itineraries for select using (auth.uid() = user_id);
create policy "Users can insert own itineraries"
    on public.itineraries for insert with check (auth.uid() = user_id);
create policy "Users can update own itineraries"
    on public.itineraries for update using (auth.uid() = user_id);
create policy "Users can delete own itineraries"
    on public.itineraries for delete using (auth.uid() = user_id);

-- 6. Itinerary items (places within an itinerary)
create table if not exists public.itinerary_items (
    id uuid primary key default gen_random_uuid(),
    itinerary_id uuid not null references public.itineraries(id) on delete cascade,
    place_id text not null,
    name text not null,
    address text,
    latitude float8 not null,
    longitude float8 not null,
    duration_seconds int not null default 1800,  -- time to spend there
    travel_seconds int not null default 0,       -- travel time from previous
    sort_order int not null default 0
);

alter table public.itinerary_items enable row level security;

create policy "Users can read own itinerary items"
    on public.itinerary_items for select
    using (exists (select 1 from public.itineraries where id = itinerary_id and user_id = auth.uid()));
create policy "Users can insert own itinerary items"
    on public.itinerary_items for insert
    with check (exists (select 1 from public.itineraries where id = itinerary_id and user_id = auth.uid()));
create policy "Users can update own itinerary items"
    on public.itinerary_items for update
    using (exists (select 1 from public.itineraries where id = itinerary_id and user_id = auth.uid()));
create policy "Users can delete own itinerary items"
    on public.itinerary_items for delete
    using (exists (select 1 from public.itineraries where id = itinerary_id and user_id = auth.uid()));
