-- ============================================
-- UniLib2 Complete Database Setup
-- Run this in Supabase SQL Editor
-- ============================================

-- Note: Using gen_random_uuid() which is built-in to modern PostgreSQL
-- No extension needed

-- ============================================
-- 1. PROFILES TABLE (extends auth.users)
-- ============================================
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    university TEXT,
    avatar_url TEXT,
    xp INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,
    streak_days INTEGER DEFAULT 0,
    role TEXT DEFAULT 'user',
    organization_id UUID,
    total_pages_read INTEGER DEFAULT 0,
    total_books_completed INTEGER DEFAULT 0,
    total_daily_goals_completed INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies for profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Profiles are viewable by everyone"
    ON profiles FOR SELECT
    USING (true);

CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- ============================================
-- 2. BOOKS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS books (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    isbn TEXT UNIQUE,
    category TEXT NOT NULL,
    description TEXT,
    cover_url TEXT,
    cover_color TEXT DEFAULT 'bg-blue-500',
    pdf_url TEXT,
    rating DECIMAL(2,1) DEFAULT 0,
    total_pages INTEGER DEFAULT 0,
    book_type TEXT DEFAULT 'online',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add check constraint for valid book types
ALTER TABLE books ADD CONSTRAINT book_type_check 
    CHECK (book_type IN ('online', 'offline', 'both'));

-- RLS Policies for books
ALTER TABLE books ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Books are viewable by everyone"
    ON books FOR SELECT
    USING (true);

-- ============================================
-- 3. READING SCHEDULE TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS reading_schedule (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    book_id UUID REFERENCES books(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    daily_goal_pages INTEGER,
    daily_goal_minutes INTEGER,
    reminder_time TIME,
    reminder_frequency TEXT DEFAULT 'daily',
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_reading_schedule_user ON reading_schedule(user_id);
CREATE INDEX IF NOT EXISTS idx_reading_schedule_status ON reading_schedule(status);

-- RLS Policies
ALTER TABLE reading_schedule ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own schedules"
    ON reading_schedule FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create own schedules"
    ON reading_schedule FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own schedules"
    ON reading_schedule FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own schedules"
    ON reading_schedule FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- 4. DAILY PROGRESS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS daily_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    schedule_id UUID REFERENCES reading_schedule(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    pages_read INTEGER DEFAULT 0,
    minutes_read INTEGER DEFAULT 0,
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(schedule_id, date)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_daily_progress_schedule ON daily_progress(schedule_id);
CREATE INDEX IF NOT EXISTS idx_daily_progress_date ON daily_progress(date);

-- RLS Policies
ALTER TABLE daily_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own progress"
    ON daily_progress FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM reading_schedule
            WHERE reading_schedule.id = daily_progress.schedule_id
            AND reading_schedule.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create own progress"
    ON daily_progress FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM reading_schedule
            WHERE reading_schedule.id = daily_progress.schedule_id
            AND reading_schedule.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own progress"
    ON daily_progress FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM reading_schedule
            WHERE reading_schedule.id = daily_progress.schedule_id
            AND reading_schedule.user_id = auth.uid()
        )
    );

-- ============================================
-- 5. ORGANIZATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Organizations are viewable by everyone"
    ON organizations FOR SELECT
    USING (true);

-- ============================================
-- 6. PHYSICAL BOOK COPIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS physical_book_copies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    barcode TEXT UNIQUE NOT NULL,
    copy_number INTEGER NOT NULL,
    status TEXT DEFAULT 'available',
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    location TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_book_copy UNIQUE(book_id, copy_number),
    CONSTRAINT status_check CHECK (status IN ('available', 'borrowed', 'lost', 'damaged'))
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_physical_copies_book_id ON physical_book_copies(book_id);
CREATE INDEX IF NOT EXISTS idx_physical_copies_barcode ON physical_book_copies(barcode);
CREATE INDEX IF NOT EXISTS idx_physical_copies_status ON physical_book_copies(status);
CREATE INDEX IF NOT EXISTS idx_physical_copies_org ON physical_book_copies(organization_id);

-- RLS Policies
ALTER TABLE physical_book_copies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Physical copies are viewable by everyone"
    ON physical_book_copies FOR SELECT
    USING (true);

CREATE POLICY "Librarians can insert physical copies"
    ON physical_book_copies FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role IN ('librarian', 'head_librarian', 'org_admin', 'system_admin', 'super_admin')
        )
    );

CREATE POLICY "Librarians can update physical copies"
    ON physical_book_copies FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role IN ('librarian', 'head_librarian', 'org_admin', 'system_admin', 'super_admin')
        )
    );

CREATE POLICY "Librarians can delete physical copies"
    ON physical_book_copies FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role IN ('librarian', 'head_librarian', 'org_admin', 'system_admin', 'super_admin')
        )
    );

-- ============================================
-- 7. BOOK CHECKOUTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS book_checkouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    physical_copy_id UUID NOT NULL REFERENCES physical_book_copies(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    librarian_id UUID NOT NULL REFERENCES profiles(id),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    checked_out_at TIMESTAMPTZ DEFAULT NOW(),
    due_date DATE NOT NULL,
    returned_at TIMESTAMPTZ,
    status TEXT DEFAULT 'active',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT status_check CHECK (status IN ('active', 'returned', 'overdue'))
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_checkouts_copy ON book_checkouts(physical_copy_id);
CREATE INDEX IF NOT EXISTS idx_checkouts_user ON book_checkouts(user_id);
CREATE INDEX IF NOT EXISTS idx_checkouts_status ON book_checkouts(status);
CREATE INDEX IF NOT EXISTS idx_checkouts_due_date ON book_checkouts(due_date);
CREATE INDEX IF NOT EXISTS idx_checkouts_org ON book_checkouts(organization_id);

-- RLS Policies
ALTER TABLE book_checkouts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own checkouts"
    ON book_checkouts FOR SELECT
    USING (
        user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role IN ('librarian', 'head_librarian', 'org_admin', 'system_admin', 'super_admin')
        )
    );

CREATE POLICY "Librarians can create checkouts"
    ON book_checkouts FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role IN ('librarian', 'head_librarian', 'org_admin', 'system_admin', 'super_admin')
        )
    );

CREATE POLICY "Librarians can update checkouts"
    ON book_checkouts FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role IN ('librarian', 'head_librarian', 'org_admin', 'system_admin', 'super_admin')
        )
    );

-- ============================================
-- 8. STUDY GROUPS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS study_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    book TEXT NOT NULL,
    creator_id UUID REFERENCES profiles(id),
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    member_count INTEGER DEFAULT 1,
    tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE study_groups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Study groups are viewable by everyone"
    ON study_groups FOR SELECT
    USING (true);

CREATE POLICY "Authenticated users can create groups"
    ON study_groups FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Group creators can update their groups"
    ON study_groups FOR UPDATE
    USING (auth.uid() = creator_id);

-- ============================================
-- 9. GROUP MEMBERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS group_members (
    group_id UUID REFERENCES study_groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (group_id, user_id)
);

ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Group members are viewable by everyone"
    ON group_members FOR SELECT
    USING (true);

CREATE POLICY "Users can join groups"
    ON group_members FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can leave groups"
    ON group_members FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- 10. USER PROGRESS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS user_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    book_id UUID REFERENCES books(id) ON DELETE CASCADE,
    current_page INTEGER DEFAULT 1,
    total_pages INTEGER,
    progress_percentage INTEGER DEFAULT 0,
    xp_earned INTEGER DEFAULT 0,
    last_read_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, book_id)
);

ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own progress"
    ON user_progress FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own progress"
    ON user_progress FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own progress"
    ON user_progress FOR UPDATE
    USING (auth.uid() = user_id);

-- ============================================
-- 11. CITATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS citations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    book_title TEXT NOT NULL,
    author TEXT NOT NULL,
    year INTEGER,
    publisher TEXT,
    format TEXT NOT NULL,
    citation_text TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE citations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own citations"
    ON citations FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create citations"
    ON citations FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 12. FUNCTIONS & TRIGGERS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reading_schedule_updated_at
    BEFORE UPDATE ON reading_schedule
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_physical_copies_updated_at
    BEFORE UPDATE ON physical_book_copies
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to update group member count
CREATE OR REPLACE FUNCTION update_group_member_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE study_groups
        SET member_count = member_count + 1
        WHERE id = NEW.group_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE study_groups
        SET member_count = member_count - 1
        WHERE id = OLD.group_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_group_count
    AFTER INSERT OR DELETE ON group_members
    FOR EACH ROW
    EXECUTE FUNCTION update_group_member_count();

-- Trigger to update copy status when checked out
CREATE OR REPLACE FUNCTION update_copy_status_on_checkout()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'active' AND NEW.returned_at IS NULL THEN
        UPDATE physical_book_copies
        SET status = 'borrowed'
        WHERE id = NEW.physical_copy_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER checkout_update_copy_status
    AFTER INSERT ON book_checkouts
    FOR EACH ROW
    EXECUTE FUNCTION update_copy_status_on_checkout();

-- Trigger to update copy status when returned
CREATE OR REPLACE FUNCTION update_copy_status_on_return()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.returned_at IS NOT NULL AND OLD.returned_at IS NULL THEN
        UPDATE physical_book_copies
        SET status = 'available'
        WHERE id = NEW.physical_copy_id;
        
        NEW.status = 'returned';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER return_update_copy_status
    BEFORE UPDATE ON book_checkouts
    FOR EACH ROW
    EXECUTE FUNCTION update_copy_status_on_return();

-- ============================================
-- 13. SAMPLE DATA (Optional Books)
-- ============================================
INSERT INTO books (title, author, category, description, cover_color, rating, total_pages, book_type) VALUES
('Introduction to Algorithms', 'Thomas H. Cormen', 'Computer Science', 'A comprehensive textbook on computer algorithms', 'bg-red-500', 4.9, 1312, 'both'),
('Clean Code', 'Robert C. Martin', 'Software Engineering', 'A handbook of agile software craftsmanship', 'bg-blue-500', 4.8, 464, 'both'),
('The Pragmatic Programmer', 'Andrew Hunt', 'Career', 'Your journey to mastery', 'bg-emerald-500', 4.9, 352, 'online'),
('Design Patterns', 'Erich Gamma', 'Architecture', 'Elements of reusable object-oriented software', 'bg-purple-500', 4.7, 416, 'online'),
('Structure and Interpretation', 'Harold Abelson', 'Computer Science', 'Computer programs structure and interpretation', 'bg-indigo-500', 4.9, 657, 'online'),
('Code Complete', 'Steve McConnell', 'Software Engineering', 'A practical handbook of software construction', 'bg-orange-500', 4.8, 960, 'both'),
('Refactoring', 'Martin Fowler', 'Software Engineering', 'Improving the design of existing code', 'bg-pink-500', 4.7, 448, 'online'),
('Head First Design Patterns', 'Eric Freeman', 'Architecture', 'A brain-friendly guide', 'bg-teal-500', 4.8, 694, 'online')
ON CONFLICT (isbn) DO NOTHING;

-- ============================================
-- 14. AUTH TRIGGER (Auto-create profile for new users)
-- ============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name, role)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    'user'
  );
  RETURN new;
EXCEPTION
  WHEN unique_violation THEN
    RETURN new;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- 15. CREATE PROFILES FOR EXISTING USERS
-- ============================================
INSERT INTO public.profiles (id, email, name, role)
SELECT 
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'name', au.raw_user_meta_data->>'full_name', split_part(au.email, '@', 1)),
    'user'
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- DONE! Database setup complete.
-- ============================================

