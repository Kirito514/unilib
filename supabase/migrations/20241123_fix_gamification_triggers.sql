-- Function to update total pages read in profiles when daily_progress changes
CREATE OR REPLACE FUNCTION update_total_pages_from_daily()
RETURNS TRIGGER AS $$
DECLARE
    v_pages_diff INTEGER;
    v_user_id UUID;
BEGIN
    -- Calculate difference in pages read
    -- If INSERT, OLD is null, so use 0
    v_pages_diff := NEW.pages_read - COALESCE(OLD.pages_read, 0);
    
    -- Only proceed if pages increased
    IF v_pages_diff > 0 THEN
        -- Get user_id from schedule
        SELECT user_id INTO v_user_id
        FROM reading_schedule
        WHERE id = NEW.schedule_id;

        -- Update profile
        UPDATE profiles
        SET total_pages_read = COALESCE(total_pages_read, 0) + v_pages_diff
        WHERE id = v_user_id;

        -- Check achievements
        PERFORM check_and_award_achievements(v_user_id);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for daily_progress
DROP TRIGGER IF EXISTS trigger_update_pages_read ON daily_progress;
CREATE TRIGGER trigger_update_pages_read
    AFTER INSERT OR UPDATE OF pages_read ON daily_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_total_pages_from_daily();

-- Recalculate total pages for all users to fix missing data
DO $$
BEGIN
    UPDATE profiles p
    SET total_pages_read = (
        SELECT COALESCE(SUM(dp.pages_read), 0)
        FROM daily_progress dp
        JOIN reading_schedule rs ON dp.schedule_id = rs.id
        WHERE rs.user_id = p.id
    );
END $$;
