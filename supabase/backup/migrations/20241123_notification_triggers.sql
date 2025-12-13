-- Drop existing trigger and function first to avoid conflicts
DROP TRIGGER IF EXISTS on_achievement_unlocked ON user_achievements;
DROP FUNCTION IF EXISTS handle_new_achievement();

-- Function to handle achievement notifications
create or replace function handle_new_achievement()
returns trigger as $$
declare
  achievement_title text;
  achievement_desc text;
begin
  -- Get achievement details
  select title, description into achievement_title, achievement_desc
  from achievements
  where id = new.achievement_id;

  -- Insert notification
  insert into notifications (user_id, title, message, type, link)
  values (
    new.user_id,
    'Yangi yutuq! 🏆',
    'Siz "' || achievement_title || '" yutug''iga erishdingiz!',
    'achievement',
    '/achievements'
  );

  return new;
end;
$$ language plpgsql security definer;

-- Trigger
create trigger on_achievement_unlocked
  after insert on user_achievements
  for each row
  execute function handle_new_achievement();
