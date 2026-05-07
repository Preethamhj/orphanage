class DatabaseSchema {
  static const sql = '''
create table if not exists public.admin_users (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null unique,
  contact_number text,
  created_at timestamptz not null default now()
);

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  role text not null default 'staff' check (role in ('admin','staff','donor','adopter')),
  approval_status text not null default 'pending' check (approval_status in ('pending','approved','rejected')),
  full_name text,
  created_at timestamptz not null default now()
);

alter table public.users
  add column if not exists approval_status text not null default 'pending'
  check (approval_status in ('pending','approved','rejected'));

create table if not exists public.login_logs (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  email text not null,
  role text not null,
  login_time timestamptz not null default now()
);

create table if not exists public.children (
  child_id bigint generated always as identity primary key,
  name text not null,
  age integer not null check (age >= 0),
  gender text not null,
  education text not null,
  health_status text not null,
  admission_date date not null,
  guardian_details text,
  dob date,
  class integer,
  section text,
  school_name text,
  joining_date date,
  joining_reason text,
  brought_by text,
  medical_notes text,
  child_background text,
  academic_status text check (academic_status in ('Best Student','Average Student','Weak Student')),
  attendance_percentage numeric(5,2) check (attendance_percentage >= 0 and attendance_percentage <= 100),
  last_exam_marks numeric(5,2) check (last_exam_marks >= 0 and last_exam_marks <= 100)
);

alter table public.children add column if not exists dob date;
alter table public.children add column if not exists class integer;
alter table public.children add column if not exists section text;
alter table public.children add column if not exists school_name text;
alter table public.children add column if not exists joining_date date;
alter table public.children add column if not exists joining_reason text;
alter table public.children add column if not exists brought_by text;
alter table public.children add column if not exists medical_notes text;
alter table public.children add column if not exists child_background text;
alter table public.children add column if not exists academic_status text check (academic_status in ('Best Student','Average Student','Weak Student'));
alter table public.children add column if not exists attendance_percentage numeric(5,2) check (attendance_percentage >= 0 and attendance_percentage <= 100);
alter table public.children add column if not exists last_exam_marks numeric(5,2) check (last_exam_marks >= 0 and last_exam_marks <= 100);

create table if not exists public.child_skills (
  id uuid primary key default gen_random_uuid(),
  child_id bigint not null references public.children(child_id) on delete cascade,
  skill_name text not null,
  skill_level text not null,
  description text,
  created_at timestamptz not null default now()
);

create index if not exists idx_child_skills_child_id on public.child_skills(child_id);
create index if not exists idx_child_skills_skill_name on public.child_skills(skill_name);

create table if not exists public.academic_records (
  id uuid primary key default gen_random_uuid(),
  child_id bigint not null references public.children(child_id) on delete cascade,
  class integer not null,
  year integer not null,
  marks numeric(5,2) not null check (marks >= 0 and marks <= 100),
  attendance numeric(5,2) not null check (attendance >= 0 and attendance <= 100),
  performance_level text not null check (performance_level in ('Excellent','Good','Average','Poor')),
  created_at timestamptz not null default now()
);

create table if not exists public.staff (
  staff_id bigint generated always as identity primary key,
  name text not null,
  role text not null,
  contact_number text not null,
  email text not null unique,
  joining_date date not null,
  department text not null
);

create table if not exists public.donors (
  donor_id bigint generated always as identity primary key,
  user_id uuid unique references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null unique,
  contact_number text,
  occupation text,
  monthly_salary numeric(12,2),
  created_at timestamptz not null default now()
);

alter table public.donors add column if not exists occupation text;
alter table public.donors add column if not exists monthly_salary numeric(12,2);

create table if not exists public.adopters (
  adopter_id bigint generated always as identity primary key,
  user_id uuid unique references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null unique,
  contact_number text,
  created_at timestamptz not null default now()
);

create table if not exists public.donations (
  donation_id bigint generated always as identity primary key,
  donor_name text not null,
  donation_type text not null check (donation_type in ('cash','clothes','food','others')),
  donation_amount numeric(12,2) not null default 0,
  payment_method text not null,
  donation_date date not null,
  remarks text
);

create table if not exists public.donars (
  donation_id bigint generated always as identity primary key,
  donor_name text not null,
  donation_type text not null check (donation_type in ('cash','clothes','food','others')),
  donation_amount numeric(12,2) not null default 0,
  payment_method text not null,
  donation_date date not null,
  remarks text,
  updated_at timestamptz default now()
);

create table if not exists public.adoptions (
  adoption_id bigint generated always as identity primary key,
  child_id bigint not null references public.children(child_id) on delete restrict,
  adopter_name text not null,
  contact_information text not null,
  application_date date not null,
  approval_status text not null check (approval_status in ('pending','approved','rejected')),
  completion_date date
);

create index if not exists idx_children_name on public.children(name);
create index if not exists idx_children_class on public.children(class);
create index if not exists idx_academic_records_child on public.academic_records(child_id);
create index if not exists idx_academic_records_class_year on public.academic_records(class, year);
create index if not exists idx_staff_name on public.staff(name);
create index if not exists idx_donors_email on public.donors(email);
create index if not exists idx_adopters_email on public.adopters(email);
create index if not exists idx_donations_date on public.donations(donation_date);
create index if not exists idx_adoptions_child on public.adoptions(child_id);
create index if not exists idx_login_logs_time on public.login_logs(login_time);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as \$\$
begin
  begin
    -- Core app user profile + role
    insert into public.users (id, email, role, approval_status, full_name)
    values (
      new.id,
      new.email,
      case
        when coalesce(new.raw_user_meta_data->>'role', 'staff') in ('staff','donor','adopter')
        then coalesce(new.raw_user_meta_data->>'role', 'staff')
        else 'staff'
      end,
      case
        when coalesce(new.raw_user_meta_data->>'role', 'staff') = 'admin' then 'approved'
        else 'pending'
      end,
      coalesce(new.raw_user_meta_data->>'full_name', '')
    )
    on conflict (id) do nothing;
  exception when others then
    null;
  end;

  begin
    -- Role fan-out into module tables
    if lower(coalesce(new.raw_user_meta_data->>'role', 'staff')) = 'staff' then
      insert into public.staff (name, role, contact_number, email, joining_date, department)
      values (
        coalesce(nullif(new.raw_user_meta_data->>'full_name', ''), split_part(new.email, '@', 1)),
        'Staff',
        coalesce(nullif(new.raw_user_meta_data->>'contact_number', ''), 'NA'),
        new.email,
        current_date,
        'General'
      )
      on conflict (email) do nothing;
    elsif lower(coalesce(new.raw_user_meta_data->>'role', 'staff')) = 'donor' then
      insert into public.donors (user_id, full_name, email, contact_number)
      values (
        new.id,
        coalesce(nullif(new.raw_user_meta_data->>'full_name', ''), split_part(new.email, '@', 1)),
        new.email,
        nullif(new.raw_user_meta_data->>'contact_number', '')
      )
      on conflict (user_id) do nothing;
    elsif lower(coalesce(new.raw_user_meta_data->>'role', 'staff')) = 'adopter' then
      insert into public.adopters (user_id, full_name, email, contact_number)
      values (
        new.id,
        coalesce(nullif(new.raw_user_meta_data->>'full_name', ''), split_part(new.email, '@', 1)),
        new.email,
        nullif(new.raw_user_meta_data->>'contact_number', '')
      )
      on conflict (user_id) do nothing;
    elsif lower(coalesce(new.raw_user_meta_data->>'role', 'staff')) = 'admin' then
      insert into public.admin_users (id, full_name, email, contact_number)
      values (
        new.id,
        coalesce(nullif(new.raw_user_meta_data->>'full_name', ''), 'Admin'),
        new.email,
        nullif(new.raw_user_meta_data->>'contact_number', '')
      )
      on conflict (id) do nothing;
    end if;
  exception when others then
    null;
  end;

  return new;
end;
\$\$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.children enable row level security;
alter table public.child_skills enable row level security;
alter table public.academic_records enable row level security;
alter table public.staff enable row level security;
alter table public.donations enable row level security;
alter table public.donars enable row level security;
alter table public.adoptions enable row level security;
alter table public.users enable row level security;
alter table public.login_logs enable row level security;
alter table public.donors enable row level security;
alter table public.adopters enable row level security;
alter table public.admin_users enable row level security;

drop policy if exists children_auth_all on public.children;
create policy children_auth_all on public.children
for all to authenticated
using (true)
with check (true);

drop policy if exists child_skills_auth_all on public.child_skills;
create policy child_skills_auth_all on public.child_skills
for all to authenticated
using (true)
with check (true);

drop policy if exists academic_records_auth_all on public.academic_records;
create policy academic_records_auth_all on public.academic_records
for all to authenticated
using (true)
with check (true);

drop policy if exists staff_auth_all on public.staff;
create policy staff_auth_all on public.staff
for all to authenticated
using (true)
with check (true);

drop policy if exists donors_auth_all on public.donors;
create policy donors_auth_all on public.donors
for all to authenticated
using (true)
with check (true);

drop policy if exists adopters_auth_all on public.adopters;
create policy adopters_auth_all on public.adopters
for all to authenticated
using (true)
with check (true);

drop policy if exists admin_users_auth_all on public.admin_users;
create policy admin_users_auth_all on public.admin_users
for all to authenticated
using (true)
with check (true);

drop policy if exists donations_auth_all on public.donations;
create policy donations_auth_all on public.donations
for all to authenticated
using (true)
with check (true);

drop policy if exists donars_auth_all on public.donars;
create policy donars_auth_all on public.donars
for all to authenticated
using (true)
with check (true);

drop policy if exists adoptions_auth_all on public.adoptions;
create policy adoptions_auth_all on public.adoptions
for all to authenticated
using (true)
with check (true);

drop policy if exists users_auth_select on public.users;
create policy users_auth_select on public.users
for select to authenticated
using (true);

drop policy if exists users_auth_insert_self on public.users;
create policy users_auth_insert_self on public.users
for insert to authenticated
with check (
  auth.uid() = id
  and role in ('staff','donor','adopter')
);

drop policy if exists users_auth_update_self on public.users;
create policy users_auth_update_self on public.users
for update to authenticated
using (auth.uid() = id)
with check (auth.uid() = id and role in ('staff','donor','adopter'));

drop policy if exists users_admin_update_all on public.users;
create policy users_admin_update_all on public.users
for update to authenticated
using (
  exists (
    select 1 from public.users u
    where u.id = auth.uid() and u.role = 'admin'
  )
)
with check (
  exists (
    select 1 from public.users u
    where u.id = auth.uid() and u.role = 'admin'
  )
);

drop policy if exists login_logs_auth_insert on public.login_logs;
create policy login_logs_auth_insert on public.login_logs
for insert to authenticated
with check (auth.uid() = user_id);

drop policy if exists login_logs_auth_select on public.login_logs;
create policy login_logs_auth_select on public.login_logs
for select to authenticated
using (true);
''';
}
