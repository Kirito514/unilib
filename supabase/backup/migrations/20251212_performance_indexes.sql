-- Performance Optimization: Add Database Indexes
-- Date: 2025-12-12
-- Purpose: Improve query performance for frequently accessed columns

-- Profiles table indexes
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_student_number ON profiles(student_number);

-- Book checkouts indexes
CREATE INDEX IF NOT EXISTS idx_book_checkouts_status ON book_checkouts(status);
CREATE INDEX IF NOT EXISTS idx_book_checkouts_user_id ON book_checkouts(user_id);
CREATE INDEX IF NOT EXISTS idx_book_checkouts_due_date ON book_checkouts(due_date);
CREATE INDEX IF NOT EXISTS idx_book_checkouts_physical_copy_id ON book_checkouts(physical_copy_id);

-- Books table indexes
CREATE INDEX IF NOT EXISTS idx_books_category ON books(category);
CREATE INDEX IF NOT EXISTS idx_books_book_type ON books(book_type);
CREATE INDEX IF NOT EXISTS idx_books_title ON books(title);
CREATE INDEX IF NOT EXISTS idx_books_author ON books(author);

-- Physical book copies indexes
CREATE INDEX IF NOT EXISTS idx_physical_copies_book_id ON physical_book_copies(book_id);
CREATE INDEX IF NOT EXISTS idx_physical_copies_status ON physical_book_copies(status);
CREATE INDEX IF NOT EXISTS idx_physical_copies_barcode ON physical_book_copies(barcode);

-- User progress indexes (if table exists)
CREATE INDEX IF NOT EXISTS idx_user_progress_user_id ON user_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_book_id ON user_progress(book_id);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_checkouts_user_status ON book_checkouts(user_id, status);
CREATE INDEX IF NOT EXISTS idx_user_progress_user_book ON user_progress(user_id, book_id);

-- Performance comment
COMMENT ON INDEX idx_profiles_role IS 'Optimize role-based queries (admin, librarian, student)';
COMMENT ON INDEX idx_book_checkouts_status IS 'Optimize active/overdue checkout queries';
COMMENT ON INDEX idx_books_category IS 'Optimize category filtering';
