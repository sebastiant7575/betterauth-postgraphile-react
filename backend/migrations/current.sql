-- Notes table
CREATE TABLE IF NOT EXISTS app_public.notes (
  id SERIAL PRIMARY KEY,
  user_id TEXT NOT NULL DEFAULT current_setting('jwt.claims.user_id', true),
  title TEXT NOT NULL DEFAULT '',
  body TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Smart comments for PostGraphile
COMMENT ON COLUMN app_public.notes.user_id IS E'@omit create,update';

-- Updated_at trigger
CREATE OR REPLACE FUNCTION app_public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS notes_updated_at ON app_public.notes;
CREATE TRIGGER notes_updated_at
  BEFORE UPDATE ON app_public.notes
  FOR EACH ROW
  EXECUTE FUNCTION app_public.set_updated_at();

-- Enable RLS
ALTER TABLE app_public.notes ENABLE ROW LEVEL SECURITY;

-- RLS policies
DROP POLICY IF EXISTS select_own ON app_public.notes;
CREATE POLICY select_own ON app_public.notes
  FOR SELECT USING (user_id = current_setting('jwt.claims.user_id', true));

DROP POLICY IF EXISTS insert_own ON app_public.notes;
CREATE POLICY insert_own ON app_public.notes
  FOR INSERT WITH CHECK (user_id = current_setting('jwt.claims.user_id', true));

DROP POLICY IF EXISTS update_own ON app_public.notes;
CREATE POLICY update_own ON app_public.notes
  FOR UPDATE USING (user_id = current_setting('jwt.claims.user_id', true));

DROP POLICY IF EXISTS delete_own ON app_public.notes;
CREATE POLICY delete_own ON app_public.notes
  FOR DELETE USING (user_id = current_setting('jwt.claims.user_id', true));

-- Grants
GRANT SELECT, INSERT, UPDATE, DELETE ON app_public.notes TO app_authenticated;
GRANT USAGE, SELECT ON SEQUENCE app_public.notes_id_seq TO app_authenticated;
