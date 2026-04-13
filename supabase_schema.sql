-- ============================================================
-- TOURNOIPRO — SCHÉMA SUPABASE COMPLET
-- Colle ce code dans : Supabase > SQL Editor > New Query
-- ============================================================

-- Extensions
create extension if not exists "uuid-ossp";

-- ============================================================
-- TABLE : SALLES (comptes gérants)
-- ============================================================
create table if not exists salles (
  id          uuid primary key default uuid_generate_v4(),
  nom         text not null,
  ville       text not null,
  email       text not null unique,
  pw_hash     text not null,
  tel         text default '',
  plan        text not null default 'starter' check (plan in ('starter','pro')),
  status      text not null default 'active' check (status in ('active','blocked','pending')),
  created_at  timestamptz default now()
);

-- ============================================================
-- TABLE : JOUEURS (comptes joueurs)
-- ============================================================
create table if not exists joueurs (
  id          uuid primary key default uuid_generate_v4(),
  pseudo      text not null unique,
  email       text not null unique,
  pw_hash     text not null,
  tel         text default '',
  wins        integer default 0,
  losses      integer default 0,
  titres      integer default 0,
  created_at  timestamptz default now()
);

-- ============================================================
-- TABLE : TOURNAMENTS
-- ============================================================
create table if not exists tournaments (
  id          uuid primary key default uuid_generate_v4(),
  salle_id    uuid references salles(id) on delete cascade,
  code        text not null unique,
  name        text not null,
  game        text not null,
  format      text not null default 'elimination' check (format in ('elimination','groupes')),
  max_players integer not null default 8,
  date        text default '',
  time        text default '',
  fee         integer default 0,
  prize       integer default 0,
  description text default '',
  status      text not null default 'open' check (status in ('open','running','done')),
  winner_id   text default null,
  created_at  timestamptz default now()
);

-- ============================================================
-- TABLE : PLAYERS (joueurs inscrits à un tournoi)
-- ============================================================
create table if not exists players (
  id            uuid primary key default uuid_generate_v4(),
  tournament_id uuid references tournaments(id) on delete cascade,
  name          text not null,
  phone         text default '',
  wins          integer default 0,
  losses        integer default 0,
  points        integer default 0,
  created_at    timestamptz default now()
);

-- ============================================================
-- TABLE : MATCHES
-- ============================================================
create table if not exists matches (
  id            uuid primary key default uuid_generate_v4(),
  tournament_id uuid references tournaments(id) on delete cascade,
  match_num     integer not null,
  round         integer not null default 1,
  group_id      integer default null,
  player1_id    uuid references players(id) on delete set null,
  player2_id    uuid references players(id) on delete set null,
  score1        integer default null,
  score2        integer default null,
  winner_id     uuid references players(id) on delete set null,
  next_match_num integer default null,
  created_at    timestamptz default now()
);

-- ============================================================
-- TABLE : GROUPS (poules)
-- ============================================================
create table if not exists groups (
  id            uuid primary key default uuid_generate_v4(),
  tournament_id uuid references tournaments(id) on delete cascade,
  group_index   integer not null,
  name          text not null
);

-- ============================================================
-- TABLE : GROUP_PLAYERS (stats joueur dans une poule)
-- ============================================================
create table if not exists group_players (
  id          uuid primary key default uuid_generate_v4(),
  group_id    uuid references groups(id) on delete cascade,
  player_id   uuid references players(id) on delete cascade,
  w           integer default 0,
  d           integer default 0,
  l           integer default 0,
  pts         integer default 0,
  gf          integer default 0,
  ga          integer default 0
);

-- ============================================================
-- TABLE : ACTIVITY (journal d'activité admin)
-- ============================================================
create table if not exists activity (
  id          uuid primary key default uuid_generate_v4(),
  type        text not null,
  message     text not null,
  icon        text default '⚡',
  created_at  timestamptz default now()
);

-- ============================================================
-- TABLE : SETTINGS (paramètres globaux)
-- ============================================================
create table if not exists settings (
  key         text primary key,
  value       text not null
);

-- Valeurs par défaut
insert into settings (key, value) values
  ('price_starter', '5000'),
  ('price_pro', '12000'),
  ('registrations_open', 'true'),
  ('maintenance_mode', 'false')
on conflict (key) do nothing;

-- ============================================================
-- DONNÉES DE DÉMO
-- ============================================================

-- Salle démo (mot de passe = "gerant123" en clair pour le hash simulé)
insert into salles (id, nom, ville, email, pw_hash, tel, plan, status)
values (
  'a0000000-0000-0000-0000-000000000001',
  'GameZone Abidjan',
  'Abidjan',
  'gerant@salletest.com',
  'gerant123',
  '+225 07 00 00 00',
  'pro',
  'active'
) on conflict (email) do nothing;

-- Joueur démo
insert into joueurs (id, pseudo, email, pw_hash, wins, losses, titres)
values (
  'b0000000-0000-0000-0000-000000000001',
  'ProGamer225',
  'joueur@test.com',
  'joueur123',
  4, 2, 1
) on conflict (email) do nothing;

-- ============================================================
-- ROW LEVEL SECURITY (activer après avoir tout testé)
-- ============================================================
-- alter table salles enable row level security;
-- alter table tournaments enable row level security;
-- alter table players enable row level security;
-- alter table matches enable row level security;

-- ============================================================
-- INDEX pour les performances
-- ============================================================
create index if not exists idx_tournaments_salle on tournaments(salle_id);
create index if not exists idx_players_tournament on players(tournament_id);
create index if not exists idx_matches_tournament on matches(tournament_id);
create index if not exists idx_activity_created on activity(created_at desc);

-- ============================================================
-- VÉRIFICATION FINALE
-- ============================================================
-- Lance cette requête pour vérifier que tout est bien créé :
-- select table_name from information_schema.tables
-- where table_schema = 'public'
-- order by table_name;
