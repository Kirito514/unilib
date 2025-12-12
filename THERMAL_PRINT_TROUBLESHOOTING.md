# Thermal Label Print Troubleshooting

## Issue
2 barcodes printing on first page, second page empty.

## Root Cause
CSS `page-break-after` not working reliably for thermal labels in browsers.

## Solution Applied

### 1. Fixed Page Dimensions
```css
html, body {
    width: 57mm;
    height: 30mm;
}
```

### 2. Exact Height Constraints
```css
.barcode-print-page {
    height: 30mm !important;
    min-height: 30mm !important;
    max-height: 30mm !important;
}
```

### 3. Both Break Properties
```css
page-break-before: always;
page-break-after: always;
```

### 4. First/Last Child Exceptions
```css
.barcode-print-page:first-child {
    page-break-before: auto;
}
.barcode-print-page:last-child {
    page-break-after: auto;
}
```

## Testing

1. Create 2 copies
2. Open print modal
3. Click "Chop Etish"
4. Check print preview:
   - Should show 2 pages
   - Page 1: Barcode 1 (centered)
   - Page 2: Barcode 2 (centered)

## If Still Not Working

### Browser Print Settings
- Scale: 100%
- Margins: None
- Headers/Footers: Off

### Alternative: Manual Print
1. Print page 1 only
2. Load next label
3. Print page 2 only

### Last Resort: Single Barcode Mode
Print one barcode at a time instead of batch.
