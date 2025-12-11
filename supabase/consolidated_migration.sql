-- ============================================
-- UniLib2 Consolidated Migration Script
-- ============================================
-- Bu script barcha asosiy migratsiyalarni o'z ichiga oladi
-- Supabase SQL Editor da ishlatish uchun
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. ORGANIZATIONS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('school', 'college', 'university', 'public_library', 'private_library')),
    logo_url TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    address TEXT,
    city TEXT,
    region TEXT,
    settings JSONB DEFAULT '{}',
    subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'basic', 'premium', 'enterprise')),
    subscription_status TEXT DEFAULT 'active' CHECK (subscription_status IN ('active', 'suspended', 'cancelled')),
    max_students INTEGER DEFAULT 200,
    max_books INTEGER,
    max_librarians INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_organizations_slug ON organizations(slug);

-- Insert default organization
INSERT INTO organizations (name, slug, type, subscription_tier, subscription_status, max_students, max_books)
VALUES (
    'UniLib Platform',
    'unilib-platform',
    'public_library',
    'enterprise',
    'active',
    999999,
    999999
)
ON CONFLICT (slug) DO NOTHING;

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 2. PROFILES TABLE (Update existing)
-- ============================================

-- Add new columns if they don't exist
DO $$ 
BEGIN
    -- organization_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='organization_id') THEN
        ALTER TABLE profiles ADD COLUMN organization_id UUID REFERENCES organizations(id);
    END IF;
    
    -- role
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='role') THEN
        ALTER TABLE profiles ADD COLUMN role TEXT DEFAULT 'student' 
            CHECK (role IN ('super_admin', 'system_admin', 'org_admin', 'head_librarian', 'librarian', 'teacher', 'parent', 'student'));
    END IF;
    
    -- is_active
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='is_active') THEN
        ALTER TABLE profiles ADD COLUMN is_active BOOLEAN DEFAULT true;
    END IF;
    
    -- student_id (13 digit)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='student_id') THEN
        ALTER TABLE profiles ADD COLUMN student_id TEXT;
    END IF;
    
    -- HEMIS columns
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='phone') THEN
        ALTER TABLE profiles ADD COLUMN phone TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='faculty') THEN
        ALTER TABLE profiles ADD COLUMN faculty TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='group_name') THEN
        ALTER TABLE profiles ADD COLUMN group_name TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='course') THEN
        ALTER TABLE profiles ADD COLUMN course INTEGER;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='education_form') THEN
        ALTER TABLE profiles ADD COLUMN education_form TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='specialty') THEN
        ALTER TABLE profiles ADD COLUMN specialty TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='gpa') THEN
        ALTER TABLE profiles ADD COLUMN gpa DECIMAL(3,2);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='last_synced_at') THEN
        ALTER TABLE profiles ADD COLUMN last_synced_at TIMESTAMPTZ;
    END IF;
    
    -- bio
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='bio') THEN
        ALTER TABLE profiles ADD COLUMN bio TEXT;
    END IF;
    
    -- Gamification columns
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='total_pages_read') THEN
        ALTER TABLE profiles ADD COLUMN total_pages_read INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='total_books_completed') THEN
        ALTER TABLE profiles ADD COLUMN total_books_completed INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='last_streak_update') THEN
        ALTER TABLE profiles ADD COLUMN last_streak_update DATE;
    END IF;
END $$;

-- Migrate existing users to default organization
UPDATE profiles 
SET organization_id = (SELECT id FROM organizations WHERE slug = 'unilib-platform')
WHERE organization_id IS NULL;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_profiles_organization_id ON profiles(organization_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_student_id ON profiles(student_id);

-- ============================================
-- 3. BOOKS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS books (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    isbn TEXT UNIQUE,
    category TEXT NOT NULL,
    description TEXT,
    cover_url TEXT,
    cover_color TEXT DEFAULT 'bg-blue-500',
    file_url TEXT,
    pdf_url TEXT,
    rating DECIMAL(2,1) DEFAULT 0,
    total_pages INTEGER DEFAULT 0,
    is_online BOOLEAN DEFAULT true,
    organization_id UUID REFERENCES organizations(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_books_category ON books(category);
CREATE INDEX IF NOT EXISTS idx_books_organization_id ON books(organization_id);

ALTER TABLE books ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 4. OFFLINE LIBRARY BOOKS
-- ============================================

CREATE TABLE IF NOT EXISTS offline_library_books (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    book_id UUID REFERENCES books(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    quantity INTEGER DEFAULT 1,
    available_quantity INTEGER DEFAULT 1,
    location TEXT,
    shelf_number TEXT,
    barcode TEXT UNIQUE,
    condition TEXT CHECK (condition IN ('excellent', 'good', 'fair', 'poor')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(book_id, organization_id)
);

CREATE INDEX IF NOT EXISTS idx_offline_books_book_id ON offline_library_books(book_id);
CREATE INDEX IF NOT EXISTS idx_offline_books_org_id ON offline_library_books(organization_id);

ALTER TABLE offline_library_books ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 5. BOOK REVIEWS
-- ============================================

CREATE TABLE IF NOT EXISTS book_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    book_id UUID REFERENCES books(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(book_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_book_reviews_book_id ON book_reviews(book_id);
CREATE INDEX IF NOT EXISTS idx_book_reviews_user_id ON book_reviews(user_id);

ALTER TABLE book_reviews ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 6. GAMIFICATION TABLES
-- ============================================

-- Achievements
CREATE TABLE IF NOT EXISTS achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    icon TEXT DEFAULT '🏆',
    xp_reward INTEGER DEFAULT 0,
    tier TEXT DEFAULT 'bronze' CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum')),
    requirement_type TEXT NOT NULL CHECK (requirement_type IN ('streak', 'books_completed', 'pages_read', 'daily_goals')),
    requirement_value INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Achievements
CREATE TABLE IF NOT EXISTS user_achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    achievement_id UUID REFERENCES achievements(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMPTZ DEFAULT NOW(),
    seen BOOLEAN DEFAULT false,
    UNIQUE(user_id, achievement_id)
);

CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_achievement_id ON user_achievements(achievement_id);

ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 7. READING SCHEDULE
-- ============================================

CREATE TABLE IF NOT EXISTS reading_schedule (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    book_id UUID REFERENCES books(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    daily_goal_pages INTEGER,
    daily_goal_minutes INTEGER,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS daily_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    schedule_id UUID REFERENCES reading_schedule(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    pages_read INTEGER DEFAULT 0,
    minutes_read INTEGER DEFAULT 0,
    completed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, schedule_id, date)
);

CREATE INDEX IF NOT EXISTS idx_reading_schedule_user_id ON reading_schedule(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_progress_user_id ON daily_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_progress_date ON daily_progress(date);

ALTER TABLE reading_schedule ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_progress ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 8. NOTIFICATIONS
-- ============================================

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'info' CHECK (type IN ('info', 'success', 'warning', 'achievement')),
    is_read BOOLEAN DEFAULT false,
    link TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 9. ADMIN LOGS
-- ============================================

CREATE TABLE IF NOT EXISTS admin_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID REFERENCES profiles(id),
    action TEXT NOT NULL,
    target_type TEXT,
    target_id UUID,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_logs_admin_id ON admin_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_logs_created_at ON admin_logs(created_at DESC);

ALTER TABLE admin_logs ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 10. ROW LEVEL SECURITY POLICIES
-- ============================================

-- Organizations
DROP POLICY IF EXISTS "Organizations are viewable by everyone" ON organizations;
CREATE POLICY "Organizations are viewable by everyone"
    ON organizations FOR SELECT
    USING (true);

-- Profiles
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile"
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Books
DROP POLICY IF EXISTS "Books are viewable by everyone" ON books;
CREATE POLICY "Books are viewable by everyone"
    ON books FOR SELECT
    USING (true);

-- Book Reviews
DROP POLICY IF EXISTS "Reviews are viewable by everyone" ON book_reviews;
CREATE POLICY "Reviews are viewable by everyone"
    ON book_reviews FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Users can create reviews" ON book_reviews;
CREATE POLICY "Users can create reviews"
    ON book_reviews FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own reviews" ON book_reviews;
CREATE POLICY "Users can update own reviews"
    ON book_reviews FOR UPDATE
    USING (auth.uid() = user_id);

-- Offline Library Books
DROP POLICY IF EXISTS "Offline books are viewable by everyone" ON offline_library_books;
CREATE POLICY "Offline books are viewable by everyone"
    ON offline_library_books FOR SELECT
    USING (true);

-- Achievements
DROP POLICY IF EXISTS "Achievements are viewable by everyone" ON achievements;
CREATE POLICY "Achievements are viewable by everyone"
    ON achievements FOR SELECT
    USING (true);

-- User Achievements
DROP POLICY IF EXISTS "Users can view own achievements" ON user_achievements;
CREATE POLICY "Users can view own achievements"
    ON user_achievements FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own achievements" ON user_achievements;
CREATE POLICY "Users can insert own achievements"
    ON user_achievements FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Reading Schedule
DROP POLICY IF EXISTS "Users can view own schedule" ON reading_schedule;
CREATE POLICY "Users can view own schedule"
    ON reading_schedule FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create own schedule" ON reading_schedule;
CREATE POLICY "Users can create own schedule"
    ON reading_schedule FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own schedule" ON reading_schedule;
CREATE POLICY "Users can update own schedule"
    ON reading_schedule FOR UPDATE
    USING (auth.uid() = user_id);

-- Daily Progress
DROP POLICY IF EXISTS "Users can view own progress" ON daily_progress;
CREATE POLICY "Users can view own progress"
    ON daily_progress FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own progress" ON daily_progress;
CREATE POLICY "Users can insert own progress"
    ON daily_progress FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own progress" ON daily_progress;
CREATE POLICY "Users can update own progress"
    ON daily_progress FOR UPDATE
    USING (auth.uid() = user_id);

-- Notifications
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
CREATE POLICY "Users can view own notifications"
    ON notifications FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
CREATE POLICY "Users can update own notifications"
    ON notifications FOR UPDATE
    USING (auth.uid() = user_id);

-- Admin Logs
DROP POLICY IF EXISTS "Admins can view logs" ON admin_logs;
CREATE POLICY "Admins can view logs"
    ON admin_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role IN ('super_admin', 'system_admin', 'org_admin')
        )
    );

-- ============================================
-- 11. FUNCTIONS
-- ============================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_books_updated_at ON books;
CREATE TRIGGER update_books_updated_at
    BEFORE UPDATE ON books
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_reading_schedule_updated_at ON reading_schedule;
CREATE TRIGGER update_reading_schedule_updated_at
    BEFORE UPDATE ON reading_schedule
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Leaderboard functions
CREATE OR REPLACE FUNCTION get_leaderboard()
RETURNS TABLE (
    id UUID,
    name TEXT,
    avatar_url TEXT,
    xp INTEGER,
    level INTEGER,
    total_books_completed INTEGER,
    rank BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.name,
        p.avatar_url,
        p.xp,
        p.level,
        p.total_books_completed,
        ROW_NUMBER() OVER (ORDER BY p.xp DESC) as rank
    FROM profiles p
    WHERE p.is_active = true
    ORDER BY p.xp DESC
    LIMIT 100;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_streak_leaderboard()
RETURNS TABLE (
    id UUID,
    name TEXT,
    avatar_url TEXT,
    streak_days INTEGER,
    xp INTEGER,
    rank BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.name,
        p.avatar_url,
        p.streak_days,
        p.xp,
        ROW_NUMBER() OVER (ORDER BY p.streak_days DESC) as rank
    FROM profiles p
    WHERE p.is_active = true AND p.streak_days > 0
    ORDER BY p.streak_days DESC
    LIMIT 100;
END;
$$ LANGUAGE plpgsql;

-- Check and unlock achievements
CREATE OR REPLACE FUNCTION check_and_unlock_achievements(p_user_id UUID)
RETURNS void AS $$
DECLARE
    v_profile RECORD;
    v_achievement RECORD;
BEGIN
    -- Get user profile
    SELECT * INTO v_profile FROM profiles WHERE id = p_user_id;
    
    -- Check each achievement
    FOR v_achievement IN 
        SELECT * FROM achievements 
        WHERE id NOT IN (
            SELECT achievement_id FROM user_achievements WHERE user_id = p_user_id
        )
    LOOP
        -- Check if user meets requirement
        IF (
            (v_achievement.requirement_type = 'streak' AND v_profile.streak_days >= v_achievement.requirement_value) OR
            (v_achievement.requirement_type = 'books_completed' AND v_profile.total_books_completed >= v_achievement.requirement_value) OR
            (v_achievement.requirement_type = 'pages_read' AND v_profile.total_pages_read >= v_achievement.requirement_value)
        ) THEN
            -- Unlock achievement
            INSERT INTO user_achievements (user_id, achievement_id)
            VALUES (p_user_id, v_achievement.id)
            ON CONFLICT DO NOTHING;
            
            -- Award XP
            UPDATE profiles 
            SET xp = xp + v_achievement.xp_reward
            WHERE id = p_user_id;
            
            -- Create notification
            INSERT INTO notifications (user_id, title, message, type)
            VALUES (
                p_user_id,
                'Yangi Yutuq! 🏆',
                'Siz "' || v_achievement.title || '" yutuqini qo\'lga kiritdingiz! +' || v_achievement.xp_reward || ' XP',
                'achievement'
            );
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Handle new user registration
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_default_org_id UUID;
BEGIN
    -- Get default organization
    SELECT id INTO v_default_org_id FROM organizations WHERE slug = 'unilib-platform';
    
    -- Insert profile
    INSERT INTO profiles (id, email, name, organization_id, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        v_default_org_id,
        'student'
    )
    ON CONFLICT (id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- ============================================
-- 12. SEED DATA (Achievements)
-- ============================================

INSERT INTO achievements (key, title, description, icon, xp_reward, tier, requirement_type, requirement_value) VALUES
    ('streak_3', 'Boshlang\'ich', '3 kun ketma-ket o\'qish', '🔥', 25, 'bronze', 'streak', 3),
    ('streak_7', 'Haftalik', '7 kun ketma-ket o\'qish', '🔥', 50, 'silver', 'streak', 7),
    ('streak_30', 'Oylik', '30 kun ketma-ket o\'qish', '🔥', 100, 'gold', 'streak', 30),
    ('books_1', 'Birinchi Kitob', 'Birinchi kitobni tugatish', '📚', 50, 'bronze', 'books_completed', 1),
    ('books_5', 'Kitobxon', '5 ta kitobni tugatish', '📚', 100, 'silver', 'books_completed', 5),
    ('books_10', 'Kutubxona Faxriysi', '10 ta kitobni tugatish', '📚', 200, 'gold', 'books_completed', 10),
    ('pages_100', 'Yuz Sahifa', '100 sahifa o\'qish', '📖', 25, 'bronze', 'pages_read', 100),
    ('pages_500', 'Besh Yuz Sahifa', '500 sahifa o\'qish', '📖', 75, 'silver', 'pages_read', 500),
    ('pages_1000', 'Ming Sahifa', '1000 sahifa o\'qish', '📖', 150, 'gold', 'pages_read', 1000)
ON CONFLICT (key) DO NOTHING;

-- ============================================
-- MIGRATION COMPLETE
-- ============================================

-- Verify tables
SELECT 'Migration completed successfully!' as status;
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
