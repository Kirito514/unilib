-- Add role column to profiles table
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'USER' 
CHECK (role IN ('USER', 'LIBRARIAN', 'MODERATOR', 'SUPER_ADMIN'));

-- Create index for faster role queries
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- Create admin activity log table
CREATE TABLE IF NOT EXISTS admin_activity_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  target_type TEXT,
  target_id UUID,
  details JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create index for activity log queries
CREATE INDEX IF NOT EXISTS idx_admin_activity_admin_id ON admin_activity_log(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_activity_created_at ON admin_activity_log(created_at DESC);

-- RLS Policies for admin_activity_log
ALTER TABLE admin_activity_log ENABLE ROW LEVEL SECURITY;

-- Only admins can view activity logs
CREATE POLICY "Admins can view activity logs"
ON admin_activity_log FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('LIBRARIAN', 'MODERATOR', 'SUPER_ADMIN')
  )
);

-- Only admins can insert activity logs
CREATE POLICY "Admins can insert activity logs"
ON admin_activity_log FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('LIBRARIAN', 'MODERATOR', 'SUPER_ADMIN')
  )
);

-- Update RLS policies for books table to allow librarians to manage
CREATE POLICY "Librarians can manage books"
ON books FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('LIBRARIAN', 'SUPER_ADMIN')
  )
);

-- Update RLS policies for profiles table
CREATE POLICY "Super admins can update any profile"
ON profiles FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = auth.uid()
    AND p.role = 'SUPER_ADMIN'
  )
);

-- Comment for documentation
COMMENT ON COLUMN profiles.role IS 'User role: USER, LIBRARIAN, MODERATOR, or SUPER_ADMIN';
COMMENT ON TABLE admin_activity_log IS 'Logs all admin actions for audit trail';
