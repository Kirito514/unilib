-- SIMPLE RLS fix - only allow users to see their own profile
-- Remove all complex policies that cause recursion

-- 1. Disable RLS temporarily
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- 2. Drop ALL policies
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'profiles') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON profiles';
    END LOOP;
END $$;

-- 3. Create ONLY simple policies (no subqueries!)

-- Allow INSERT for new users
CREATE POLICY "allow_insert_own_profile"
    ON profiles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- Allow SELECT for own profile ONLY
CREATE POLICY "allow_select_own_profile"
    ON profiles FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

-- Allow UPDATE for own profile ONLY
CREATE POLICY "allow_update_own_profile"
    ON profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 4. Re-enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 5. Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;
GRANT SELECT ON public.profiles TO anon;
