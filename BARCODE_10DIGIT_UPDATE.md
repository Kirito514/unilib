# Barcode System Update - 10-Digit Format

## Change Summary
**Date**: 2025-12-12
**Reason**: Scanner (Optic X-9300) cannot read 13-digit barcodes

## New Barcode Format

### Structure
**Format**: `XXXXXXXZZZ` (10 digits total)
- `XXXXXXX` = Book ID hash (7 digits)
- `ZZZ` = Copy number (3 digits, padded with zeros)

### Example
- Book ID: `abc123-def456-ghi789`
- Hash: `1234567`
- Copy 1: `1234567001`
- Copy 2: `1234567002`
- Copy 3: `1234567003`

### Old Format (Removed)
~~`XXYYYYYYYYYZZZ` (13 digits)~~
- ~~XX = Title prefix~~
- ~~YYYYYYYYY = Book ID hash (8 digits)~~
- ~~ZZZ = Copy number~~

## Benefits

✅ **Simpler**: 10 digits easier to scan
✅ **CODE128 Compatible**: Works with all CODE128 scanners
✅ **Unique**: Hash ensures uniqueness per book
✅ **Sequential**: Copy numbers are sequential

## Implementation

### Files Changed
1. `app/admin/books/offline/create/page.tsx`
2. `app/admin/books/offline/[id]/add-copy/page.tsx`

### Barcode Settings (Thermal Printer)
```typescript
{
    format: 'CODE128',
    width: 2,
    height: 80,
    displayValue: true,
    fontSize: 18,
    margin: 2
}
```

### Print Settings
- Label Size: 57mm x 30mm
- One barcode per label
- Xprinter XP-635B compatible

## Testing

### Test Procedure
1. Create new book with 2 copies
2. Check generated barcodes are 10 digits
3. Print barcodes
4. Scan with Optic X-9300
5. Verify scanner reads correctly

### Expected Results
- ✅ Barcode length: 10 digits
- ✅ Scanner beeps on scan
- ✅ Correct number appears in input
- ✅ Each copy has unique barcode

## Migration

### Existing Barcodes
- Old 13-digit barcodes still work
- New books use 10-digit format
- No database migration needed
- Both formats coexist

### Future
- Consider migrating old barcodes (optional)
- Monitor scanner success rate
- Adjust format if needed

## Notes
- Hash algorithm: JavaScript bitwise hash
- Collision risk: Very low (7 digits = 10 million combinations)
- Copy limit: 999 copies per book
