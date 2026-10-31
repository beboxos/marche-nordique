-- Guide Marche Nordique : circuits éditables par des comptes autorisés.
-- À exécuter une fois dans l'éditeur SQL du projet Supabase.

create table if not exists public.circuits (
  id          text primary key,
  position    int  not null default 0,
  published   boolean not null default true,
  data        jsonb not null,
  updated_at  timestamptz not null default now(),
  updated_by  uuid references auth.users(id)
);

create table if not exists public.circuit_admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

create or replace function public.mn_is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.circuit_admins where user_id = auth.uid());
$$;

create or replace function public.mn_touch_circuit() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end $$;

drop trigger if exists circuits_touch on public.circuits;
create trigger circuits_touch before insert or update on public.circuits
  for each row execute function public.mn_touch_circuit();

alter table public.circuits enable row level security;
alter table public.circuit_admins enable row level security;

-- Droits d'accès aux tables (les politiques RLS ci-dessous restreignent ensuite les lignes).
grant select on public.circuits to anon, authenticated;
grant insert, update, delete on public.circuits to authenticated;
grant select on public.circuit_admins to authenticated;

-- Lecture : circuits publiés pour tout le monde, tous les circuits pour les admins.
drop policy if exists circuits_read on public.circuits;
create policy circuits_read on public.circuits for select
  using (published or public.mn_is_admin());

drop policy if exists circuits_write on public.circuits;
create policy circuits_write on public.circuits for all
  using (public.mn_is_admin()) with check (public.mn_is_admin());

-- Chacun peut vérifier s'il est admin ; personne ne peut s'y ajouter depuis le site.
drop policy if exists circuit_admins_self on public.circuit_admins;
create policy circuit_admins_self on public.circuit_admins for select using (user_id = auth.uid());

-- Fichiers : scans (jpg) et GPX d'origine, lisibles par tous, écrits par les admins.
insert into storage.buckets (id, name, public) values ('scans', 'scans', true) on conflict do nothing;
insert into storage.buckets (id, name, public) values ('gpx', 'gpx', true) on conflict do nothing;

drop policy if exists mn_files_read on storage.objects;
create policy mn_files_read on storage.objects for select
  using (bucket_id in ('scans', 'gpx'));

drop policy if exists mn_files_write on storage.objects;
create policy mn_files_write on storage.objects for all
  using (bucket_id in ('scans', 'gpx') and public.mn_is_admin())
  with check (bucket_id in ('scans', 'gpx') and public.mn_is_admin());
