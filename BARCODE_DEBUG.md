# Barcode Debugging Guide

## Issue
User reports only 1 barcode showing when 2 copies are created.

## Debug Steps

### 1. Check Console Logs
When creating a book with 2 copies, check browser console (F12) for:

```
📊 Generated barcodes: [...]
📊 Number of copies: 2
🎨 BarcodePrintModal received barcodes: [...]
🎨 Barcode count: 2
```

**Expected**: Both should show 2 barcodes
**If not**: Problem is in book creation logic

### 2. Check Modal Display
- Open barcode print modal
- Count how many barcode previews show
- Check if both preview and print sections have same count

### 3. Check Print Preview
- Click "Chop Etish" button
- Open browser print preview
- Count pages - should be 2 pages (one barcode per page)

## Possible Issues

### Issue 1: Array Not Populating
**Symptom**: Console shows empty array or only 1 item
**Fix**: Check `copies.map(c => c.barcode)` in create page

### Issue 2: Modal Not Rendering All
**Symptom**: Console shows 2 barcodes but modal shows 1
**Fix**: Check `barcodes.map()` in modal component

### Issue 3: Canvas Refs Not Working
**Symptom**: Barcodes in array but canvases not rendering
**Fix**: Check `previewCanvasRefs` and `printCanvasRefs`

## Current Settings

**Barcode Dimensions** (58mm x 30mm):
- width: 1.5
- height: 50
- fontSize: 14
- margin: 2

**Print Settings**:
- Page size: 58mm x 30mm
- One barcode per page
- page-break-after: always

## Test Procedure

1. Create new book
2. Set copies: 2
3. Submit
4. Check console logs
5. Count barcodes in modal
6. Print preview
7. Report results
