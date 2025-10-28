-- seed.sql
-- Insert sample company data
insert into public.companies (id, name) values
  ('00000000-0000-0000-0000-000000000001', 'Acme Recruiting');

-- Create profiles for both users
insert into public.profiles (user_id, full_name, default_company_id)
values
  ('e548a0cf-580c-410e-aa6c-063161daeb31', 'Alice Owner', '00000000-0000-0000-0000-000000000001'),
  ('702216b4-6216-415b-97ff-b50cc465898b', 'Bob Recruiter', '00000000-0000-0000-0000-000000000001');

-- Company memberships (owner + recruiter)
insert into public.company_members (company_id, user_id, role)
values
  ('00000000-0000-0000-0000-000000000001', 'e548a0cf-580c-410e-aa6c-063161daeb31', 'owner'),
  ('00000000-0000-0000-0000-000000000001', '702216b4-6216-415b-97ff-b50cc465898b', 'recruiter');

-- Add a sample job
insert into public.jobs (company_id, title, description, location, created_by)
values
  ('00000000-0000-0000-0000-000000000001',
   'Senior MERN Developer',
   'Responsible for building scalable web apps using MERN stack',
   'Remote',
   'e548a0cf-580c-410e-aa6c-063161daeb31');

-- Add 2 sample candidates
insert into public.candidates (company_id, full_name, email, phone, years_experience, skills)
values
  ('00000000-0000-0000-0000-000000000001', 'Jane Doe', 'jane@example.com', '5551234567', 5.0, array['React','Node.js','MongoDB']),
  ('00000000-0000-0000-0000-000000000001', 'John Smith', 'john@example.com', '5559876543', 3.5, array['Express','PostgreSQL','TypeScript']);

-- Add AI match scores for candidates
insert into public.job_candidate_matches (company_id, job_id, candidate_id, score)
select
  '00000000-0000-0000-0000-000000000001',
  (select id from public.jobs limit 1),
  c.id,
  case when c.full_name = 'Jane Doe' then 95.5 else 87.3 end
from public.candidates c;

-- Add AI summaries
insert into public.ai_summaries (company_id, job_id, candidate_id, summary)
select
  '00000000-0000-0000-0000-000000000001',
  (select id from public.jobs limit 1),
  c.id,
  case
    when c.full_name = 'Jane Doe' then 'Jane has strong experience in MERN and leadership skills.'
    else 'John has solid backend expertise and is eager to grow in frontend work.'
  end
from public.candidates c;
