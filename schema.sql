-- Run this whole file once in Supabase: SQL Editor > New query > Run
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  job_title text not null default '',
  role text not null default 'employee' check (role in ('manager','employee')),
  created_at timestamptz default now()
);
create table public.goals (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null references public.profiles(id) on delete cascade,
  text text not null, pct int not null default 0 check (pct between 0 and 100),
  created_at timestamptz default now()
);
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null references public.profiles(id) on delete cascade,
  author_id uuid not null default auth.uid() references public.profiles(id),
  title text not null, body text not null, rating int check (rating between 1 and 5),
  created_at timestamptz default now()
);
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null references public.profiles(id) on delete cascade, -- the thread owner
  author_id uuid not null default auth.uid() references public.profiles(id),
  text text not null, created_at timestamptz default now()
);
create table public.notes (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null references public.profiles(id) on delete cascade,
  author_id uuid not null default auth.uid() references public.profiles(id),
  text text not null, created_at timestamptz default now()
);

create or replace function public.is_manager() returns boolean
language sql security definer set search_path = public stable as
$$ select exists (select 1 from profiles where id = auth.uid() and role = 'manager') $$;

-- The FIRST person to sign up becomes the manager; everyone else is an employee.
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, full_name, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''),
          case when exists (select 1 from profiles) then 'employee' else 'manager' end);
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

alter table profiles enable row level security;
alter table goals    enable row level security;
alter table reports  enable row level security;
alter table messages enable row level security;
alter table notes    enable row level security;

-- profiles: you see yourself and managers' names; managers see/edit everyone
create policy "read profiles" on profiles for select to authenticated
  using (id = auth.uid() or role = 'manager' or is_manager());
create policy "managers edit profiles" on profiles for update to authenticated
  using (is_manager()) with check (is_manager());

-- goals: employees read their own; only managers write
create policy "read goals" on goals for select to authenticated using (employee_id = auth.uid() or is_manager());
create policy "manage goals" on goals for all to authenticated using (is_manager()) with check (is_manager());

-- reports & messages: employees use their own; managers use everyone's
create policy "read reports" on reports for select to authenticated using (employee_id = auth.uid() or is_manager());
create policy "add reports" on reports for insert to authenticated
  with check ((employee_id = auth.uid() or is_manager()) and author_id = auth.uid());
create policy "read messages" on messages for select to authenticated using (employee_id = auth.uid() or is_manager());
create policy "add messages" on messages for insert to authenticated
  with check ((employee_id = auth.uid() or is_manager()) and author_id = auth.uid());

-- private manager notes
create policy "notes managers only" on notes for all to authenticated using (is_manager()) with check (is_manager());

-- live updates
alter publication supabase_realtime add table reports, messages, goals;
