-- Update existing profiles with formatted names (Title Case)
-- Convert "FAYZULLAYEV ORZUBEK KAMALIDDIN O'G'LI" to "Fayzullayev Orzubek Kamaliddin O'g'li"

UPDATE profiles
SET name = INITCAP(LOWER(name))
WHERE name = UPPER(name) AND name IS NOT NULL;

-- INITCAP capitalizes first letter of each word
