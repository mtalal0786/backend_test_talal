# 🧩 Backend Engineer Test — Muhammad Talal

This repository contains my completed **Backend Engineer Test** for **AzkyTech**.  
It demonstrates a **multi-tenant recruitment backend** built using **Supabase**, with strong **Row Level Security (RLS)** ensuring data isolation between companies.

---

## 🧠 Overview

This backend system enables multiple companies (tenants) to securely manage:
- Job postings  
- Candidates and their resumes  
- AI-based job–candidate matching  

Each company’s data is **completely isolated** using **RLS** (Row Level Security) — ensuring that users from one company cannot see or modify data belonging to another.

---

## 🏗️ Tech Stack

- **Supabase** (PostgreSQL + Auth + Storage)
- **Row Level Security (RLS)**
- **SQL policies and functions**
- **JWT-based user authentication**
- **cURL commands** for verification

---

## 🧱 Database Schema

The schema includes the following key entities:

| Table | Purpose |
|--------|----------|
| `companies` | Represents a company (tenant). |
| `profiles` | Mirrors `auth.users` for user profiles. |
| `company_members` | Associates users with companies and roles (`owner`, `admin`, `recruiter`). |
| `jobs` | Stores job postings per company. |
| `candidates` | Candidate profiles belonging to a company. |
| `candidate_files` | Stores CV and document metadata. |
| `job_candidate_matches` | AI-generated match scores between jobs and candidates. |
| `ai_summaries` | AI-generated text summaries for matches. |

---

## 🔒 Row Level Security (RLS) Policies

All tables are protected with RLS.  
Policies ensure that:
- Users can **only view, insert, update, or delete** rows where their `company_id` belongs to them.
- Only `owner` and `admin` roles can perform **DELETE** actions.

The `company_ids_for_user(uid)` function dynamically returns all company IDs a user belongs to.

Example policy:

```sql
create policy "jobs_select_member_company"
on public.jobs
for select
using (
  company_id in (select public.company_ids_for_user(auth.uid()))
);
