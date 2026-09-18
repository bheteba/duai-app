-- دوائي مصر 🇪🇬 / Supabase production starter schema
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text not null default '',
  country text not null default 'EG',
  governorate text not null default '',
  city text not null default '',
  area text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.medicines (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  country text not null default 'EG',
  name text not null,
  active_ingredient text not null default '',
  strength text not null default '',
  dosage_form text not null default '',
  quantity text not null default '',
  expiry_date date not null,
  governorate text not null default '',
  city text not null default '',
  area text not null default '',
  requires_prescription boolean not null default false,
  verification_status text not null default 'pending' check (verification_status in ('pending','approved','rejected')),
  offer_type text not null default 'exchange' check (offer_type in ('exchange','free')),
  requested_medicine text,
  image_url text,
  status text not null default 'active' check (status in ('active','reserved','completed','removed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.exchange_requests (
  id uuid primary key default gen_random_uuid(),
  medicine_id uuid not null references public.medicines(id) on delete cascade,
  requester_id uuid not null references auth.users(id) on delete cascade,
  offered_medicine_id uuid references public.medicines(id) on delete set null,
  message text not null default '',
  status text not null default 'pending' check (status in ('pending','accepted','rejected','cancelled','completed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  medicine_id uuid references public.medicines(id) on delete set null,
  reason text not null,
  details text not null default '',
  status text not null default 'open' check (status in ('open','reviewing','resolved','dismissed')),
  created_at timestamptz not null default now()
);

create index if not exists medicines_search_idx on public.medicines (lower(name));
create index if not exists medicines_area_idx on public.medicines (governorate, city, area);
create index if not exists medicines_status_idx on public.medicines (status, verification_status, expiry_date);
create index if not exists requests_requester_idx on public.exchange_requests (requester_id, status);

alter table public.profiles enable row level security;
alter table public.medicines enable row level security;
alter table public.exchange_requests enable row level security;
alter table public.reports enable row level security;

-- Profiles
 drop policy if exists profiles_select_own on public.profiles;
 create policy profiles_select_own on public.profiles for select to authenticated using (auth.uid() = id);
 drop policy if exists profiles_insert_own on public.profiles;
 create policy profiles_insert_own on public.profiles for insert to authenticated with check (auth.uid() = id);
 drop policy if exists profiles_update_own on public.profiles;
 create policy profiles_update_own on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- Medicines: approved active listings are discoverable; owners can always see their own.
 drop policy if exists medicines_select_visible on public.medicines;
 create policy medicines_select_visible on public.medicines for select to authenticated
 using ((status = 'active' and verification_status = 'approved' and expiry_date >= current_date) or owner_id = auth.uid());
 drop policy if exists medicines_insert_own on public.medicines;
 create policy medicines_insert_own on public.medicines for insert to authenticated with check (owner_id = auth.uid() and country = 'EG');
 drop policy if exists medicines_update_own on public.medicines;
 create policy medicines_update_own on public.medicines for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());
 drop policy if exists medicines_delete_own on public.medicines;
 create policy medicines_delete_own on public.medicines for delete to authenticated using (owner_id = auth.uid());

-- Requests: requester can create/read their own; owner can read/update requests for their medicines.
 drop policy if exists requests_select on public.exchange_requests;
 create policy requests_select on public.exchange_requests for select to authenticated
 using (requester_id = auth.uid() or exists (select 1 from public.medicines m where m.id = medicine_id and m.owner_id = auth.uid()));
 drop policy if exists requests_insert on public.exchange_requests;
 create policy requests_insert on public.exchange_requests for insert to authenticated with check (requester_id = auth.uid());
 drop policy if exists requests_update on public.exchange_requests;
 create policy requests_update on public.exchange_requests for update to authenticated
 using (requester_id = auth.uid() or exists (select 1 from public.medicines m where m.id = medicine_id and m.owner_id = auth.uid()))
 with check (requester_id = auth.uid() or exists (select 1 from public.medicines m where m.id = medicine_id and m.owner_id = auth.uid()));

-- Reports: users can create/read their own reports.
 drop policy if exists reports_insert on public.reports;
 create policy reports_insert on public.reports for insert to authenticated with check (reporter_id = auth.uid());
 drop policy if exists reports_select on public.reports;
 create policy reports_select on public.reports for select to authenticated using (reporter_id = auth.uid());

-- Keep profile creation consistent with auth metadata.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, phone, country, governorate, city, area)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'phone', ''),
    'EG',
    coalesce(new.raw_user_meta_data->>'governorate', ''),
    coalesce(new.raw_user_meta_data->>'city', ''),
    coalesce(new.raw_user_meta_data->>'area', '')
  )
  on conflict (id) do update set
    full_name = excluded.full_name,
    phone = excluded.phone,
    governorate = excluded.governorate,
    city = excluded.city,
    area = excluded.area,
    updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Optional helper: normalize Egyptian mobile numbers to +20XXXXXXXXXX.
create or replace function public.normalize_egypt_phone(raw text)
returns text language plpgsql immutable as $$
declare p text := regexp_replace(coalesce(raw,''), '[^0-9+]', '', 'g');
begin
  if p like '+20%' then return p;
  elsif p like '20%' then return '+' || p;
  elsif p like '01%' then return '+20' || substring(p from 2);
  else return p;
  end if;
end; $$;
