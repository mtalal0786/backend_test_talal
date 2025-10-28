-- Jobs
create table if not exists public.jobs (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references public.companies(id) on delete cascade,
  title text not null,
  description text,
  location text,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

-- Candidates (parsed entities)
create table if not exists public.candidates (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references public.companies(id) on delete cascade,
  full_name text not null,
  email text,
  phone text,
  years_experience numeric(4,1),
  skills text[],
  created_at timestamptz not null default now()
);

-- Candidate CV files (Storage object keys)
create table if not exists public.candidate_files (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references public.companies(id) on delete cascade,
  candidate_id uuid not null references public.candidates(id) on delete cascade,
  storage_key text not null,        -- e.g. cvs/{company}/{candidate}/{uuid}.pdf
  original_filename text,
  mime_type text,
  size_bytes bigint,
  created_at timestamptz not null default now()
);

-- AI matching scores per (job, candidate)
create table if not exists public.job_candidate_matches (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  candidate_id uuid not null references public.candidates(id) on delete cascade,
  score numeric(5,2) not null,   -- 0..100
  created_at timestamptz not null default now(),
  unique (job_id, candidate_id)
);

-- AI summaries per (job, candidate)
create table if not exists public.ai_summaries (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  candidate_id uuid not null references public.candidates(id) on delete cascade,
  summary text not null,
  created_at timestamptz not null default now(),
  unique (job_id, candidate_id)
);

-- Enable RLS
alter table public.jobs enable row level security;
alter table public.candidates enable row level security;
alter table public.candidate_files enable row level security;
alter table public.job_candidate_matches enable row level security;
alter table public.ai_summaries enable row level security;

-- RLS: SELECT (members only within their companies)
create policy "jobs_select_member_company"
on public.jobs for select
using (company_id in (select public.company_ids_for_user(auth.uid())));

create policy "candidates_select_member_company"
on public.candidates for select
using (company_id in (select public.company_ids_for_user(auth.uid())));

create policy "candidate_files_select_member_company"
on public.candidate_files for select
using (company_id in (select public.company_ids_for_user(auth.uid())));

create policy "matches_select_member_company"
on public.job_candidate_matches for select
using (company_id in (select public.company_ids_for_user(auth.uid())));

create policy "summaries_select_member_company"
on public.ai_summaries for select
using (company_id in (select public.company_ids_for_user(auth.uid())));

-- RLS: INSERT (must insert rows for a company the user belongs to)
create policy "jobs_insert_member_company"
on public.jobs for insert
with check (company_id in (select public.company_ids_for_user(auth.uid())));

create policy "candidates_insert_member_company"
on public.candidates for insert
with check (company_id in (select public.company_ids_for_user(auth.uid())));

create policy "candidate_files_insert_member_company"
on public.candidate_files for insert
with check (company_id in (select public.company_ids_for_user(auth.uid())));

create policy "matches_insert_member_company"
on public.job_candidate_matches for insert
with check (company_id in (select public.company_ids_for_user(auth.uid())));

create policy "summaries_insert_member_company"
on public.ai_summaries for insert
with check (company_id in (select public.company_ids_for_user(auth.uid())));

-- RLS: UPDATE (still restricted to company membership)
create policy "jobs_update_member_company"
on public.jobs for update
using (company_id in (select public.company_ids_for_user(auth.uid())))
with check (company_id in (select public.company_ids_for_user(auth.uid())));

create policy "candidates_update_member_company"
on public.candidates for update
using (company_id in (select public.company_ids_for_user(auth.uid())))
with check (company_id in (select public.company_ids_for_user(auth.uid())));

-- RLS: DELETE (admin/owner only)
create policy "jobs_delete_admin_only"
on public.jobs for delete
using (
  company_id in (select public.company_ids_for_user(auth.uid()))
  and exists (
    select 1 from public.company_members m
    where m.company_id = jobs.company_id
      and m.user_id = auth.uid()
      and m.role in ('owner','admin')
  )
);
