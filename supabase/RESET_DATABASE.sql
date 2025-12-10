-- ============================================
-- DANGER: This will DELETE ALL DATA!
-- Only run if you want to start fresh
-- ============================================

-- Drop all tables (in correct order to avoid foreign key conflicts)
DROP TABLE IF EXISTS admin_action_logs CASCADE;
DROP TABLE IF EXISTS book_reviews CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS user_achievements CASCADE;
DROP TABLE IF EXISTS achievements CASCADE;
DROP TABLE IF EXISTS citations CASCADE;
DROP TABLE IF EXISTS user_progress CASCADE;
DROP TABLE IF EXISTS group_members CASCADE;
DROP TABLE IF EXISTS study_groups CASCADE;
DROP TABLE IF EXISTS book_checkouts CASCADE;
DROP TABLE IF EXISTS physical_book_copies CASCADE;
DROP TABLE IF EXISTS daily_progress CASCADE;
DROP TABLE IF EXISTS reading_schedule CASCADE;
DROP TABLE IF EXISTS books CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS organizations CASCADE;

-- Drop all custom functions (from all migrations)
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS update_group_member_count() CASCADE;
DROP FUNCTION IF EXISTS update_copy_status_on_checkout() CASCADE;
DROP FUNCTION IF EXISTS update_copy_status_on_return() CASCADE;
DROP FUNCTION IF EXISTS generate_barcode(UUID, INTEGER, TEXT) CASCADE;
DROP FUNCTION IF EXISTS update_overdue_checkouts() CASCADE;
DROP FUNCTION IF EXISTS get_overdue_checkouts(UUID) CASCADE;
DROP FUNCTION IF EXISTS check_and_award_achievements(UUID) CASCADE;
DROP FUNCTION IF EXISTS calculate_level(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS update_level_on_xp_change() CASCADE;
DROP FUNCTION IF EXISTS award_xp_on_daily_goal() CASCADE;
DROP FUNCTION IF EXISTS update_total_pages_read() CASCADE;
DROP FUNCTION IF EXISTS update_streak() CASCADE;
DROP FUNCTION IF EXISTS reset_streak_if_needed() CASCADE;
DROP FUNCTION IF EXISTS get_leaderboard_by_xp(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS get_leaderboard_by_streak(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS create_notification(UUID, TEXT, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS mark_notification_as_read(UUID) CASCADE;
DROP FUNCTION IF EXISTS award_achievement_notification() CASCADE;

-- Drop migration tracking (optional - uncomment if needed)
-- DROP SCHEMA IF EXISTS supabase_migrations CASCADE;
-- CREATE SCHEMA supabase_migrations;

-- Database is now clean and ready for fresh migrations or SETUP_ALL_TABLES.sql


