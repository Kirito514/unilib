-- Create groups table if not exists
CREATE TABLE IF NOT EXISTS groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  book_id UUID REFERENCES books(id) ON DELETE SET NULL,
  members_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  tags TEXT[] DEFAULT '{}',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_groups_book_id ON groups(book_id);
CREATE INDEX IF NOT EXISTS idx_groups_created_at ON groups(created_at DESC);

-- Enable RLS
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read groups
CREATE POLICY "Anyone can view groups"
ON groups FOR SELECT
USING (true);

-- Allow authenticated users to create groups
CREATE POLICY "Authenticated users can create groups"
ON groups FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

-- Allow group creators to update their groups (we'll add creator_id later)
CREATE POLICY "Users can update groups"
ON groups FOR UPDATE
USING (auth.uid() IS NOT NULL);

-- Insert sample data
INSERT INTO groups (name, members_count, is_active, tags) VALUES
('Algorithms & Data Structures', 45, true, ARRAY['CS', 'Algorithms']),
('Calculus II Study Squad', 28, false, ARRAY['Math', 'Calculus']),
('Organic Chemistry Help', 112, true, ARRAY['Chemistry', 'Science']),
('Macroeconomics 101', 15, false, ARRAY['Economics', 'Finance']),
('Modern Physics Discussion', 34, true, ARRAY['Physics', 'Science']),
('Web Development Bootcamp', 89, true, ARRAY['CS', 'Web Dev'])
ON CONFLICT DO NOTHING;

-- Comment for documentation
COMMENT ON TABLE groups IS 'Study groups for collaborative learning';
