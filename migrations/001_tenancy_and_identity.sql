-- 001_tenancy_and_identity.sql

-- Enable UUIDs
create extension if not exists "uuid-ossp";

-- Companies (tenants)
create table if not exists public.companies (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  created_at timestamptz not null default now()
);

-- Profiles (shadow of auth.users)
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  default_company_id uuid references public.companies(id),
  created_at timestamptz not null default now()
);

-- Company memberships
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'member_role') THEN
    CREATE TYPE public.member_role AS ENUM ('owner','admin','recruiter');
  END IF;
END$$;

create table if not exists public.company_members (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.member_role not null default 'recruiter',
  created_at timestamptz not null default now(),
  unique (company_id, user_id)
);

-- Helper function: current user's company_ids
create or replace function public.company_ids_for_user(uid uuid)
returns setof uuid
language sql stable security definer
set search_path = public
as $$
  select cm.company_id
  from public.company_members cm
  where cm.user_id = uid
$$;

-- RLS ON
alter table public.companies enable row level security;
alter table public.profiles enable row level security;
alter table public.company_members enable row level security;

-- Policies
-- profiles: users can see only their own profile
create policy "profiles_select_own"
on public.profiles
for select
using (user_id = auth.uid());

create policy "profiles_update_own"
on public.profiles
for update
using (user_id = auth.uid());

-- company_members: user can see memberships in their companies
create policy "company_members_select_same_company"
on public.company_members
for select
using (
  company_id in (select public.company_ids_for_user(auth.uid()))
);

-- companies: members can select their companies
create policy "companies_select_member"
on public.companies
for select
using (
  id in (select public.company_ids_for_user(auth.uid()))
);
