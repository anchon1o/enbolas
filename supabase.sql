-- En bólas! · táboas no proxecto Supabase "xogos" (prefixo eb_)

-- 1) Resultados: un rexistro por persoa e pista (gárdase o mellor tempo)
create table if not exists eb_results (
  id bigint generated always as identity primary key,
  track_key text not null,            -- 'daily|2026-10-08|normal' ou 'map|ABC123|normal'
  kind text not null check (kind in ('daily','map')),
  day date,                           -- só nas do reto do día
  len text not null check (len in ('curta','normal','longa')),
  player_id uuid not null,
  name text not null default '',
  ball jsonb,
  time real not null check (time between 5 and 900),
  updated_at timestamptz not null default now(),
  unique (track_key, player_id)
);
create index if not exists eb_results_daily_idx on eb_results (kind, day, len);
create index if not exists eb_results_track_idx on eb_results (track_key, time);
alter table eb_results enable row level security;
drop policy if exists "eb_results ler" on eb_results;
create policy "eb_results ler" on eb_results for select to anon, authenticated using (true);
-- Non hai política de escritura directa: só se escribe a través da función eb_submit.

-- 2) Pistas debuxadas e compartidas
create table if not exists eb_tracks (
  id text primary key check (id ~ '^[A-Z0-9]{5,8}$'),
  pts jsonb not null check (jsonb_typeof(pts) = 'array' and jsonb_array_length(pts) between 10 and 800),
  len smallint not null check (len between 0 and 2),
  author_id uuid,
  author_name text not null default '' check (char_length(author_name) <= 14),
  plays int not null default 0,
  created_at timestamptz not null default now()
);
alter table eb_tracks enable row level security;
drop policy if exists "eb_tracks ler" on eb_tracks;
create policy "eb_tracks ler" on eb_tracks for select to anon, authenticated using (true);
drop policy if exists "eb_tracks crear" on eb_tracks;
create policy "eb_tracks crear" on eb_tracks for insert to anon, authenticated
  with check (plays = 0 and pg_column_size(pts) < 30000);

-- 3) Función para enviar un tempo (garda só se mellora)
create or replace function eb_submit(
  p_track text, p_kind text, p_day date, p_len text,
  p_player uuid, p_name text, p_ball jsonb, p_time real
) returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_time is null or p_time < 5 or p_time > 900 then return; end if;
  if p_kind not in ('daily','map') then return; end if;
  if p_kind = 'daily' and (p_day is null or abs(p_day - current_date) > 1) then return; end if;
  if p_ball is not null and pg_column_size(p_ball) > 4000 then p_ball := null; end if;
  insert into eb_results (track_key, kind, day, len, player_id, name, ball, time)
  values (p_track, p_kind, p_day, p_len, p_player, left(coalesce(p_name,''),14), p_ball, p_time)
  on conflict (track_key, player_id) do update
    set time = least(eb_results.time, excluded.time),
        name = excluded.name, ball = excluded.ball, updated_at = now();
  if p_kind = 'map' then
    update eb_tracks set plays = plays + 1 where id = split_part(p_track, '|', 2);
  end if;
end $$;
revoke all on function eb_submit(text,text,date,text,uuid,text,jsonb,real) from public;
grant execute on function eb_submit(text,text,date,text,uuid,text,jsonb,real) to anon, authenticated;
