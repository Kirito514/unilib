-- Function to get leaderboard data
CREATE OR REPLACE FUNCTION get_leaderboard(
    limit_count INTEGER DEFAULT 50,
    time_range TEXT DEFAULT 'all_time' -- 'all_time' or 'weekly'
)
RETURNS TABLE (
    user_id UUID,
    full_name TEXT,
    avatar_url TEXT,
    xp INTEGER,
    level INTEGER,
    streak_days INTEGER,
    rank BIGINT
) AS $$
BEGIN
    -- For now, we only support 'all_time' logic fully.
    -- Weekly logic would require a separate table or column tracking weekly XP.
    -- We'll just return based on total XP for now, but structure it for future expansion.
    
    IF time_range = 'weekly' THEN
        -- Placeholder for weekly logic (currently same as all_time but could be different)
        RETURN QUERY
        SELECT
            p.id as user_id,
            p.name as full_name,
            p.avatar_url,
            p.xp,
            p.level,
            p.streak_days,
            RANK() OVER (ORDER BY p.xp DESC) as rank
        FROM profiles p
        ORDER BY p.xp DESC
        LIMIT limit_count;
    ELSE
        -- All Time (Default)
        RETURN QUERY
        SELECT
            p.id as user_id,
            p.name as full_name,
            p.avatar_url,
            p.xp,
            p.level,
            p.streak_days,
            RANK() OVER (ORDER BY p.xp DESC) as rank
        FROM profiles p
        ORDER BY p.xp DESC
        LIMIT limit_count;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get streak leaderboard
CREATE OR REPLACE FUNCTION get_streak_leaderboard(
    limit_count INTEGER DEFAULT 50
)
RETURNS TABLE (
    user_id UUID,
    full_name TEXT,
    avatar_url TEXT,
    xp INTEGER,
    level INTEGER,
    streak_days INTEGER,
    rank BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id as user_id,
        p.name as full_name,
        p.avatar_url,
        p.xp,
        p.level,
        p.streak_days,
        RANK() OVER (ORDER BY p.streak_days DESC) as rank
    FROM profiles p
    WHERE p.streak_days > 0
    ORDER BY p.streak_days DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
