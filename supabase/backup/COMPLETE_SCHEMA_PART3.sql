-- ============================================
-- COMPLETE DATABASE SCHEMA - UniLib Platform
-- Part 3: TRIGGERS AND RLS POLICIES
-- Generated: 2025-12-13
-- ============================================
-- Run this AFTER running Part 1 and Part 2

-- ============================================
-- TRIGGERS
-- ============================================

-- Update level when XP changes
CREATE OR REPLACE FUNCTION update_level_on_xp_change()
RETURNS TRIGGER AS $$
BEGIN
    NEW.level := calculate_level(NEW.xp);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_level ON profiles;
CREATE TRIGGER trigger_update_level
    BEFORE UPDATE OF xp ON profiles
    FOR EACH ROW
    WHEN (OLD.xp IS DISTINCT FROM NEW.xp)
    EXECUTE FUNCTION update_level_on_xp_change();

-- Award XP on daily goal completion
CREATE OR REPLACE FUNCTION award_xp_on_daily_goal()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    IF NEW.completed = TRUE AND (OLD.completed IS NULL OR OLD.completed = FALSE) THEN
        SELECT user_id INTO v_user_id
        FROM reading_schedule
        WHERE id = NEW.schedule_id;
        
        UPDATE profiles
        SET 
            xp = xp + 50,
            total_daily_goals_completed = COALESCE(total_daily_goals_completed, 0) + 1
        WHERE id = v_user_id;
        
        PERFORM check_and_award_achievements(v_user_id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_award_xp_daily_goal ON daily_progress;
CREATE TRIGGER trigger_award_xp_daily_goal
    AFTER INSERT OR UPDATE ON daily_progress
    FOR EACH ROW
    EXECUTE FUNCTION award_xp_on_daily_goal();

-- Update total pages read
CREATE OR REPLACE FUNCTION update_total_pages_read()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.progress_percentage = 100 AND (OLD.progress_percentage IS NULL OR OLD.progress_percentage < 100) THEN
        UPDATE profiles
        SET 
            total_books_completed = total_books_completed + 1,
            xp = xp + 200
        WHERE id = NEW.user_id;
        
        PERFORM check_and_award_achievements(NEW.user_id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_total_pages ON user_progress;
CREATE TRIGGER trigger_update_total_pages
    AFTER UPDATE ON user_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_total_pages_read();

-- Update physical copy status on checkout
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

DROP TRIGGER IF EXISTS checkout_update_copy_status ON book_checkouts;
CREATE TRIGGER checkout_update_copy_status
    AFTER INSERT ON book_checkouts
    FOR EACH ROW
    EXECUTE FUNCTION update_copy_status_on_checkout();

-- Update physical copy status on return
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

DROP TRIGGER IF EXISTS return_update_copy_status ON book_checkouts;
CREATE TRIGGER return_update_copy_status
    BEFORE UPDATE ON book_checkouts
    FOR EACH ROW
    EXECUTE FUNCTION update_copy_status_on_return();

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_physical_copies_updated_at ON physical_book_copies;
CREATE TRIGGER update_physical_copies_updated_at
    BEFORE UPDATE ON physical_book_copies
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.profiles (
        id,
        email,
        name,
        role,
        xp,
        level,
        streak_days,
        total_pages_read,
        total_books_completed,
        is_active
    ) VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        'student',
        0,
        1,
        0,
        0,
        0,
        true
    );
    
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE physical_book_copies ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_checkouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_schedule ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE library_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE citations ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_groups ENABLE ROW LEVEL SECURITY;

-- Profiles policies
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Public profiles are viewable by authenticated users" ON profiles;
CREATE POLICY "Public profiles are viewable by authenticated users"
    ON profiles FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Librarians can update user XP" ON profiles;
CREATE POLICY "Librarians can update user XP"
    ON profiles FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid()
            AND p.role IN ('librarian', 'head_librarian', 'org_admin', 'system_admin', 'super_admin')
        )
    );

-- Books policies
DROP POLICY IF EXISTS "Anyone can view books" ON books;
CREATE POLICY "Anyone can view books"
    ON books FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Books are viewable by everyone" ON books;
CREATE POLICY "Books are viewable by everyone"
    ON books FOR SELECT
    USING (true);

-- Physical book copies policies
DROP POLICY IF EXISTS "Anyone can view physical copies" ON physical_book_copies;
CREATE POLICY "Anyone can view physical copies"
    ON physical_book_copies FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Physical copies are viewable by everyone" ON physical_book_copies;
CREATE POLICY "Physical copies are viewable by everyone"
    ON physical_book_copies FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Librarians can insert physical copies" ON physical_book_copies;
CREATE POLICY "Librarians can insert physical copies"
    ON physical_book_copies FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role IN ('librarian', 'head_librarian', 'org_admin', 'system_admin', 'super_admin')
        )
    );

DROP POLICY IF EXISTS "Librarians can update physical copies" ON physical_book_copies;
CREATE POLICY "Librarians can update physical copies"
    ON physical_book_copies FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role IN ('librarian', 'head_librarian', 'org_admin', 'system_admin', 'super_admin')
        )
    );

-- Book checkouts policies
DROP POLICY IF EXISTS "Users can view own checkouts" ON book_checkouts;
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

DROP POLICY IF EXISTS "Librarians can create checkouts" ON book_checkouts;
CREATE POLICY "Librarians can create checkouts"
    ON book_checkouts FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role IN ('librarian', 'head_librarian', 'org_admin', 'system_admin', 'super_admin')
        )
    );

DROP POLICY IF EXISTS "Librarians can update checkouts" ON book_checkouts;
CREATE POLICY "Librarians can update checkouts"
    ON book_checkouts FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role IN ('librarian', 'head_librarian', 'org_admin', 'system_admin', 'super_admin')
        )
    );

-- User progress policies
DROP POLICY IF EXISTS "Users can view own progress" ON user_progress;
CREATE POLICY "Users can view own progress"
    ON user_progress FOR SELECT
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own progress" ON user_progress;
CREATE POLICY "Users can update own progress"
    ON user_progress FOR ALL
    USING (user_id = auth.uid());

-- Achievements policies
DROP POLICY IF EXISTS "Achievements are viewable by everyone" ON achievements;
CREATE POLICY "Achievements are viewable by everyone"
    ON achievements FOR SELECT
    USING (true);

-- User achievements policies
DROP POLICY IF EXISTS "Users can view their own achievements" ON user_achievements;
CREATE POLICY "Users can view their own achievements"
    ON user_achievements FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System can insert achievements" ON user_achievements;
CREATE POLICY "System can insert achievements"
    ON user_achievements FOR INSERT
    WITH CHECK (true);

-- Reading schedule policies
DROP POLICY IF EXISTS "Users can manage own schedule" ON reading_schedule;
CREATE POLICY "Users can manage own schedule"
    ON reading_schedule FOR ALL
    USING (user_id = auth.uid());

-- Daily progress policies
DROP POLICY IF EXISTS "Users can manage own daily progress" ON daily_progress;
CREATE POLICY "Users can manage own daily progress"
    ON daily_progress FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM reading_schedule
            WHERE id = daily_progress.schedule_id
            AND user_id = auth.uid()
        )
    );

-- Notifications policies
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
CREATE POLICY "Users can view own notifications"
    ON notifications FOR SELECT
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
CREATE POLICY "Users can update own notifications"
    ON notifications FOR UPDATE
    USING (user_id = auth.uid());

-- ============================================
-- SCHEMA COMPLETE
-- ============================================
-- Run simple_health_check() to verify installation
SELECT * FROM simple_health_check();
