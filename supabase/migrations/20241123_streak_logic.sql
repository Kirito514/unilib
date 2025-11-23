-- Add last_streak_update to profiles if not exists
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS last_streak_update DATE;

-- Function to handle streak updates
CREATE OR REPLACE FUNCTION handle_streak_update()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
    v_last_update DATE;
    v_current_streak INTEGER;
    v_goal_date DATE;
BEGIN
    -- Only proceed if goal is completed
    IF NEW.completed = TRUE AND (OLD.completed IS NULL OR OLD.completed = FALSE) THEN
        -- Use the date from the progress record
        v_goal_date := NEW.date::DATE;
        
        -- Get user_id from schedule
        SELECT user_id INTO v_user_id
        FROM reading_schedule
        WHERE id = NEW.schedule_id;
        
        -- Get current profile data
        SELECT last_streak_update, streak_days 
        INTO v_last_update, v_current_streak
        FROM profiles
        WHERE id = v_user_id;
        
        -- Initialize streak if null
        v_current_streak := COALESCE(v_current_streak, 0);
        
        IF v_last_update = v_goal_date THEN
            -- Already updated for this date, do nothing
            RETURN NEW;
        ELSIF v_last_update = v_goal_date - INTERVAL '1 day' THEN
            -- Consecutive day, increment streak
            UPDATE profiles
            SET streak_days = v_current_streak + 1,
                last_streak_update = v_goal_date
            WHERE id = v_user_id;
        ELSE
            -- Missed a day or first time, reset to 1
            UPDATE profiles
            SET streak_days = 1,
                last_streak_update = v_goal_date
            WHERE id = v_user_id;
        END IF;
        
        -- Check for streak achievements (reuse existing function)
        PERFORM check_and_award_achievements(v_user_id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
DROP TRIGGER IF EXISTS trigger_update_streak ON daily_progress;
CREATE TRIGGER trigger_update_streak
    AFTER INSERT OR UPDATE ON daily_progress
    FOR EACH ROW
    EXECUTE FUNCTION handle_streak_update();
