-- ============================================================
-- LUMAIR — Skema database fitur Laporan Komunitas (Supabase)
-- Cara pakai: buka SQL Editor di dashboard Supabase → paste semua
-- isi file ini → Run. Aman dijalankan ulang (idempotent).
-- ============================================================

-- ── Tabel laporan komunitas ──────────────────────────────────
create table if not exists public.reports (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  penulis     text not null default 'Anonim',          -- nama tampilan saat lapor
  jenis       text not null,                           -- kategori utama untuk data lama
  kategori    text[] not null default '{}',            -- kategori laporan (bisa lebih dari satu)
  kota        text not null,                           -- nama kota/daerah laporan
  lokasi      text,                                    -- alamat atau titik yang dipilih di peta
  deskripsi   text not null,                           -- isi laporan bebas
  lat         double precision,                        -- koordinat titik laporan
  lon         double precision,                        -- koordinat titik laporan
  created_at  timestamptz not null default now()
);

-- Migrasi aman untuk tabel reports yang sudah ada.
alter table public.reports
  add column if not exists kategori text[] not null default '{}',
  add column if not exists lokasi text;

update public.reports
set kategori = array[jenis]
where cardinality(kategori) = 0;

-- Supabase: tampilkan laporan terbaru duluan saat SELECT tanpa ORDER.
create index if not exists reports_created_at_idx
  on public.reports (created_at desc);

-- ── Row Level Security ───────────────────────────────────────
-- Semua orang (yang sudah login demikian sesuai kebijakan):
--   • SELECT : boleh — daftar laporan dibaca publik
--   • INSERT : hanya baris user_id = diri sendiri
--   • DELETE : hanya laporan milik sendiri
--   • UPDATE : tidak diberikan (laporan tidak diedit)
alter table public.reports enable row level security;

drop policy if exists "reports_public_read" on public.reports;
create policy "reports_public_read"
  on public.reports for select
  using (true);

drop policy if exists "reports_user_insert" on public.reports;
create policy "reports_user_insert"
  on public.reports for insert
  with check (auth.uid() = user_id);

drop policy if exists "reports_owner_delete" on public.reports;
create policy "reports_owner_delete"
  on public.reports for delete
  using (auth.uid() = user_id);

-- ── Aktifkan realtime laporan (opsional) ─────────────────────
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
    and not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'reports'
  ) then
  alter publication supabase_realtime add table public.reports;
  end if;
end $$;

-- ============================================================
-- CATATAN AUTH (dilakukan di UI dashboard, bukan SQL):
-- Authentication → Providers → Email → pastikan ENABLED.
-- Supaya signup langsung masuk tanpa cek email:
--   Authentication → Sign In / Providers → Email →
--   matikan toggle "Confirm email".
-- ============================================================
