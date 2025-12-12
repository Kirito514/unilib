# Offline Book Save Performance Optimization

## Issue
User reports very slow loading when saving offline books.

## Performance Logging Added

### Console Timers
```typescript
console.time('⏱️ Book insert');
// ... book insert query
console.timeEnd('⏱️ Book insert');

console.time('⏱️ Copies insert');
// ... copies insert query
console.timeEnd('⏱️ Copies insert');
```

## Testing Instructions

1. Open browser console (F12)
2. Create new offline book
3. Check console for timing:
   - `⏱️ Book insert:` - should be < 100ms
   - `⏱️ Copies insert:` - should be < 200ms

## Possible Causes

### 1. Database Indexes Not Applied
**Check**: Run migration `20251212_performance_indexes.sql`
**Impact**: Queries 50-80% slower without indexes

### 2. Network Latency
**Check**: Supabase dashboard → Database → Performance
**Impact**: Adds 100-500ms per query

### 3. Too Many Copies
**Check**: How many copies being created?
**Impact**: Linear increase with copy count

## Quick Fixes

### If Book Insert is Slow (> 500ms)
- Check database connection
- Verify no RLS policy issues
- Check for triggers on books table

### If Copies Insert is Slow (> 1000ms)
- Apply database indexes
- Reduce number of copies
- Check for duplicate barcode validation overhead

## Database Indexes Needed

```sql
-- Run this migration if not already done
CREATE INDEX IF NOT EXISTS idx_books_book_type ON books(book_type);
CREATE INDEX IF NOT EXISTS idx_physical_copies_book_id ON physical_book_copies(book_id);
CREATE INDEX IF NOT EXISTS idx_physical_copies_barcode ON physical_book_copies(barcode);
CREATE INDEX IF NOT EXISTS idx_physical_copies_status ON physical_book_copies(status);
```

## Expected Performance

**Good**:
- Book insert: 50-150ms
- Copies insert (1-5 copies): 100-300ms
- Total: < 500ms

**Acceptable**:
- Book insert: 150-300ms
- Copies insert: 300-600ms
- Total: < 1000ms

**Slow** (needs optimization):
- Book insert: > 500ms
- Copies insert: > 1000ms
- Total: > 2000ms
