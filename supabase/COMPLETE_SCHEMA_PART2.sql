-- ============================================
-- COMPLETE DATABASE SCHEMA - UniLib Platform
-- Part 2: INDEXES, FUNCTIONS, TRIGGERS, RLS
-- Generated: 2025-12-13
-- ============================================
-- Run this AFTER running COMPLETE_SCHEMA.sql Part 1

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Profiles indexes
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_student_number ON profiles(student_number);
CREATE INDEX IF NOT EXISTS idx_profiles_student_id ON profiles(student_id);
CREATE INDEX IF NOT EXISTS idx_profiles_hemis_id ON profiles(hemis_id);
CREATE INDEX IF NOT EXISTS idx_profiles_hemis_login ON profiles(hemis_login);
CREATE INDEX IF NOT EXISTS idx_profiles_xp ON profiles(xp DESC);
CREATE INDEX IF NOT EXISTS idx_profiles_streak ON profiles(streak_days DESC);
CREATE INDEX IF NOT EXISTS idx_profiles_leaderboard ON profiles(xp DESC, streak_days DESC) WHERE is_active = true;

-- Book checkouts indexes
CREATE INDEX IF NOT EXISTS idx_book_checkouts_status ON book_checkouts(status);
CREATE INDEX IF NOT EXISTS idx_book_checkouts_user_id ON book_checkouts(user_id);
CREATE INDEX IF NOT EXISTS idx_book_checkouts_due_date ON book_checkouts(due_date);
CREATE INDEX IF NOT EXISTS idx_book_checkouts_physical_copy_id ON book_checkouts(physical_copy_id);
CREATE INDEX IF NOT EXISTS idx_checkouts_user_status ON book_checkouts(user_id, status);
CREATE INDEX IF NOT EXISTS idx_book_checkouts_checked_out_at ON book_checkouts(checked_out_at DESC) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_book_checkouts_returned_at ON book_checkouts(returned_at DESC) WHERE status = 'returned';

-- Books indexes
CREATE INDEX IF NOT EXISTS idx_books_category ON books(category);
CREATE INDEX IF NOT EXISTS idx_books_book_type ON books(book_type);
CREATE INDEX IF NOT EXISTS idx_books_title ON books(title);
CREATE INDEX IF NOT EXISTS idx_books_author ON books(author);
CREATE INDEX IF NOT EXISTS idx_books_rating ON books(rating DESC);
CREATE INDEX IF NOT EXISTS idx_books_created ON books(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_books_online_only ON books(id, created_at DESC) WHERE cover_url IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_books_category_rating ON books(category, rating DESC) WHERE cover_url IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_books_search_gin ON books USING gin(to_tsvector('english', title || ' ' || author));

-- Physical book copies indexes
CREATE INDEX IF NOT EXISTS idx_physical_copies_book_id ON physical_book_copies(book_id);
CREATE INDEX IF NOT EXISTS idx_physical_copies_status ON physical_book_copies(status);
CREATE INDEX IF NOT EXISTS idx_physical_copies_barcode ON physical_book_copies(barcode);

-- User progress indexes
CREATE INDEX IF NOT EXISTS idx_user_progress_user_id ON user_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_book_id ON user_progress(book_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_user_book ON user_progress(user_id, book_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_last_read ON user_progress(last_read_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_progress_active ON user_progress(user_id, last_read_at DESC) WHERE progress_percentage > 0 AND progress_percentage < 100;

-- Reading schedule indexes
CREATE INDEX IF NOT EXISTS idx_reading_schedule_user_status ON reading_schedule(user_id, status);
CREATE INDEX IF NOT EXISTS idx_reading_schedule_dates ON reading_schedule(start_date, end_date);

-- Daily progress indexes
CREATE INDEX IF NOT EXISTS idx_daily_progress_date ON daily_progress(date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_progress_schedule ON daily_progress(schedule_id);
CREATE INDEX IF NOT EXISTS idx_daily_progress_schedule_date ON daily_progress(schedule_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_progress_completed ON daily_progress(completed) WHERE completed = true;

-- User achievements indexes
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_unlocked_at ON user_achievements(unlocked_at DESC);

-- Achievements indexes
CREATE INDEX IF NOT EXISTS idx_achievements_requirement_type ON achievements(requirement_type);

-- Library views indexes
CREATE INDEX IF NOT EXISTS idx_library_views_book_id ON library_views(book_id);
CREATE INDEX IF NOT EXISTS idx_library_views_user_id ON library_views(user_id);
CREATE INDEX IF NOT EXISTS idx_library_views_created_at ON library_views(created_at);

-- ============================================
-- STUDENT ID GENERATION FUNCTIONS
-- ============================================

CREATE OR REPLACE FUNCTION get_year_sequence(year_suffix TEXT)
RETURNS TEXT AS $$
DECLARE
    seq_name TEXT;
BEGIN
    seq_name := 'student_id_seq_' || year_suffix;
    
    IF NOT EXISTS (SELECT 1 FROM pg_sequences WHERE schemaname = 'public' AND sequencename = seq_name) THEN
        EXECUTE format('CREATE SEQUENCE %I START WITH 1', seq_name);
    END IF;
    
    RETURN seq_name;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_student_id()
RETURNS TEXT AS $$
DECLARE
    current_year TEXT;
    year_suffix TEXT;
    seq_name TEXT;
    next_id INTEGER;
    student_id TEXT;
BEGIN
    current_year := to_char(CURRENT_DATE, 'YY');
    year_suffix := current_year;
    seq_name := get_year_sequence(year_suffix);
    EXECUTE format('SELECT nextval(%L)', seq_name) INTO next_id;
    student_id := year_suffix || LPAD(next_id::TEXT, 3, '0');
    RETURN student_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- BARCODE GENERATION FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION generate_barcode(
    p_book_id UUID,
    p_copy_number INTEGER,
    p_org_slug TEXT DEFAULT 'UNI'
) RETURNS TEXT AS $$
DECLARE
    short_id TEXT;
    padded_copy TEXT;
BEGIN
    short_id := UPPER(SUBSTRING(p_book_id::TEXT FROM 1 FOR 8));
    padded_copy := LPAD(p_copy_number::TEXT, 3, '0');
    RETURN 'BOOK-' || p_org_slug || '-' || short_id || '-' || padded_copy;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- LEVEL CALCULATION FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION calculate_level(p_xp INTEGER)
RETURNS INTEGER AS $$
BEGIN
    RETURN FLOOR(SQRT(p_xp::FLOAT / 100.0)) + 1;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- ACHIEVEMENT CHECKING FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION check_and_award_achievements(p_user_id UUID)
RETURNS TABLE(achievement_id UUID, achievement_key TEXT, achievement_title TEXT, xp_reward INTEGER) AS $$
DECLARE
    v_streak INTEGER;
    v_books_completed INTEGER;
    v_pages_read INTEGER;
    v_daily_goals INTEGER;
    v_achievement RECORD;
BEGIN
    SELECT 
        streak_days,
        total_books_completed,
        total_pages_read,
        total_daily_goals_completed
    INTO 
        v_streak,
        v_books_completed,
        v_pages_read,
        v_daily_goals
    FROM profiles
    WHERE id = p_user_id;

    FOR v_achievement IN 
        SELECT a.id, a.key, a.title, a.xp_reward, a.requirement_type, a.requirement_value
        FROM achievements a
        WHERE NOT EXISTS (
            SELECT 1 FROM user_achievements ua 
            WHERE ua.user_id = p_user_id AND ua.achievement_id = a.id
        )
    LOOP
        IF (v_achievement.requirement_type = 'streak' AND v_streak >= v_achievement.requirement_value) OR
           (v_achievement.requirement_type = 'books_completed' AND v_books_completed >= v_achievement.requirement_value) OR
           (v_achievement.requirement_type = 'pages_read' AND v_pages_read >= v_achievement.requirement_value) OR
           (v_achievement.requirement_type = 'daily_goal' AND v_daily_goals >= v_achievement.requirement_value) THEN
            
            INSERT INTO user_achievements (user_id, achievement_id)
            VALUES (p_user_id, v_achievement.id);
            
            UPDATE profiles
            SET xp = xp + v_achievement.xp_reward
            WHERE id = p_user_id;
            
            achievement_id := v_achievement.id;
            achievement_key := v_achievement.key;
            achievement_title := v_achievement.title;
            xp_reward := v_achievement.xp_reward;
            RETURN NEXT;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- LEADERBOARD FUNCTIONS
-- ============================================

CREATE OR REPLACE FUNCTION get_leaderboard_by_xp(limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    user_id UUID,
    name TEXT,
    avatar_url TEXT,
    xp INTEGER,
    level INTEGER,
    rank BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id AS user_id,
        p.name,
        p.avatar_url,
        p.xp,
        p.level,
        ROW_NUMBER() OVER (ORDER BY p.xp DESC) AS rank
    FROM profiles p
    WHERE p.is_active = true
    ORDER BY p.xp DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_leaderboard_by_streak(limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    user_id UUID,
    name TEXT,
    avatar_url TEXT,
    streak_days INTEGER,
    xp INTEGER,
    rank BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id AS user_id,
        p.name,
        p.avatar_url,
        p.streak_days,
        p.xp,
        ROW_NUMBER() OVER (ORDER BY p.streak_days DESC, p.xp DESC) AS rank
    FROM profiles p
    WHERE p.is_active = true
    ORDER BY p.streak_days DESC, p.xp DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- HEALTH CHECK FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION simple_health_check()
RETURNS TABLE (
    metric TEXT,
    value TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 'Total Tables'::TEXT, 
           (SELECT count(*)::TEXT FROM pg_tables WHERE schemaname = 'public');
    
    RETURN QUERY
    SELECT 'Total Indexes'::TEXT,
           (SELECT count(*)::TEXT FROM pg_indexes WHERE schemaname = 'public');
    
    RETURN QUERY
    SELECT 'Database Size'::TEXT,
           pg_size_pretty(pg_database_size(current_database()));
    
    RETURN QUERY
    SELECT 'Active Connections'::TEXT,
           (SELECT count(*)::TEXT FROM pg_stat_activity WHERE state = 'active');
END;
$$ LANGUAGE plpgsql;

-- Continue in Part 3...
