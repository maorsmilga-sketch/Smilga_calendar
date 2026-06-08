-- ============================================================
-- לוח שנה משפחתי - Supabase SQL Schema
-- הדבק את כל הקוד הזה ב-SQL Editor של Supabase והרץ אותו
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- USERS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  color TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO public.users (id, name, color) VALUES
  ('maor', 'מאור', '#2563EB'),
  ('ravit', 'רוית', '#DB2777')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- FAMILY MEMBERS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.family_members (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  birthday DATE,
  relationship TEXT,
  color TEXT DEFAULT '#6366F1',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO public.family_members (name, relationship, color) VALUES
  ('מאור', 'בעל', '#2563EB'),
  ('רוית', 'אישה', '#DB2777')
ON CONFLICT DO NOTHING;

-- ============================================================
-- CATEGORIES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  icon TEXT,
  color TEXT
);

INSERT INTO public.categories (id, name, icon, color) VALUES
  ('family',   'משפחה',    '👨‍👩‍👧‍👦', '#10B981'),
  ('work',     'עבודה',    '💼',       '#F59E0B'),
  ('medical',  'רפואה',    '🏥',       '#EF4444'),
  ('vacation', 'חופשה',    '✈️',       '#3B82F6'),
  ('birthday', 'יום הולדת','🎂',       '#EC4899')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- EVENTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.events (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  title TEXT NOT NULL,
  date DATE NOT NULL,
  start_time TIME,
  end_time TIME,
  category TEXT REFERENCES public.categories(id) DEFAULT 'family',
  location TEXT,
  notes TEXT,
  recurrence TEXT DEFAULT 'none'
    CHECK (recurrence IN ('none','daily','weekly','monthly','yearly')),
  assigned_to TEXT REFERENCES public.users(id),
  created_by TEXT REFERENCES public.users(id),
  family_member_id UUID REFERENCES public.family_members(id),
  color TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE public.events         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories     ENABLE ROW LEVEL SECURITY;

-- Allow anonymous access (family app, no auth server)
CREATE POLICY "anon_all_events"   ON public.events         FOR ALL  TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_read_users"   ON public.users          FOR SELECT TO anon USING (true);
CREATE POLICY "anon_all_members"  ON public.family_members FOR ALL  TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_read_cats"    ON public.categories     FOR SELECT TO anon USING (true);

-- ============================================================
-- AUTO-UPDATE updated_at TRIGGER
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS update_events_updated_at ON public.events;
CREATE TRIGGER update_events_updated_at
  BEFORE UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- SHOPPING ITEMS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.shopping_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT DEFAULT 'other',
  quantity TEXT,
  checked BOOLEAN DEFAULT false,
  added_by TEXT REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.shopping_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_all_shopping" ON public.shopping_items FOR ALL TO anon USING (true) WITH CHECK (true);

-- ============================================================
-- TASKS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.tasks (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  title TEXT NOT NULL,
  done BOOLEAN DEFAULT false,
  assigned_to TEXT REFERENCES public.users(id),
  created_by TEXT REFERENCES public.users(id),
  done_by TEXT REFERENCES public.users(id),
  done_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_all_tasks" ON public.tasks FOR ALL TO anon USING (true) WITH CHECK (true);

-- ============================================================
-- SAMPLE DATA (אופציונלי - מחק אם אינך צריך)
-- ============================================================
-- INSERT INTO public.events (title, date, start_time, end_time, category, assigned_to, created_by, recurrence) VALUES
--   ('ישיבת צוות', CURRENT_DATE + 2, '10:00', '11:00', 'work',    'maor',  'maor',  'weekly'),
--   ('ארוחת שישי משפחתית', CURRENT_DATE + 4, '19:00', '22:00', 'family', 'ravit', 'ravit', 'weekly'),
--   ('יום הולדת מאור', '1990-03-15', NULL, NULL, 'birthday', 'maor', 'ravit', 'yearly');
