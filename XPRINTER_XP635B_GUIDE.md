# Xprinter XP-635B - Barcode Printing Guide

## Printer Specifications

**Model**: Xprinter XP-635B
**Type**: Thermal Label Printer
**Print Method**: Direct Thermal
**Resolution**: 203 DPI (typical for thermal printers)
**Supported Formats**: CODE128, EAN-13, Code39, QR Code

---

## Optimized Barcode Settings

### For Thermal Label Printing
```typescript
{
    format: 'CODE128',
    width: 2,              // Compact for 58mm labels
    height: 60,            // Optimal height for thermal
    displayValue: true,
    fontSize: 14,
    margin: 5,             // Minimal margins
    background: '#ffffff',
    lineColor: '#000000'
}
```

**Why These Settings?**
- **width: 2** - Fits perfectly on 58mm thermal labels
- **height: 60** - Compact but still scannable
- **margin: 5** - Minimal waste on thermal paper
- **fontSize: 14** - Clear text on small labels

---

## Recommended Label Sizes

### Standard Thermal Labels
- **58mm x 40mm** - Most common (recommended)
- **58mm x 30mm** - Compact option
- **80mm x 50mm** - Larger labels (if available)

### Continuous Roll
- **58mm width** - Auto-height based on content
- **80mm width** - For wider barcodes

---

## Print Settings

### In Browser Print Dialog
1. **Printer**: Select "Xprinter XP-635B"
2. **Paper Size**: 58mm x 40mm (or custom)
3. **Margins**: None (0mm)
4. **Scale**: 100%
5. **Orientation**: Portrait

### Printer Configuration
- **Print Speed**: Medium (for better quality)
- **Darkness**: Medium to Dark
- **Label Type**: Gap/Mark sensor
- **Tear Mode**: Tear-off

---

## Print Output

### What Will Print
✅ **ONLY the barcode** - Clean, minimal
✅ **Barcode number** - Below the barcode
✅ **White background** - For thermal contrast

### What Will NOT Print
❌ Headers/titles
❌ Borders/decorations
❌ Preview elements
❌ UI buttons

---

## How to Use

### Step 1: Generate Barcodes
1. Create book or add copies
2. Click "Print Barcodes" button
3. Modal opens with preview

### Step 2: Print
1. Click "Chop Etish" button
2. Select Xprinter XP-635B
3. Check print preview
4. Click Print

### Step 3: Apply Labels
1. Peel label from backing
2. Apply to book spine or cover
3. Ensure label is flat and smooth

---

## Troubleshooting

### Issue: Barcode Too Large
**Solution**: Labels are cut off
- Use 58mm x 40mm labels
- Check printer paper size setting
- Reduce barcode width if needed

### Issue: Barcode Too Small
**Solution**: Hard to scan
- Increase width to 3
- Increase height to 80
- Use larger label size (80mm)

### Issue: Multiple Barcodes Per Label
**Solution**: Only want one per label
- Already configured for one per label
- Check `page-break-after: always` in CSS

### Issue: Blank Labels
**Solution**: Nothing printing
- Check thermal paper is loaded correctly
- Ensure print side is facing up
- Check printer darkness setting

### Issue: Faded Print
**Solution**: Barcode not dark enough
- Increase printer darkness
- Check thermal paper quality
- Replace thermal head if old

---

## Label Loading

### Xprinter XP-635B Label Loading
1. Open printer cover
2. Insert label roll (print side up)
3. Thread through guides
4. Close cover
5. Press feed button to align

### Paper Sensor
- **Gap sensor**: For labels with gaps
- **Mark sensor**: For labels with black marks
- Configure in printer settings

---

## Maintenance

### Regular Cleaning
- Clean thermal head weekly
- Use thermal head cleaning pen
- Remove dust and debris
- Check for label adhesive buildup

### Thermal Paper Storage
- Store in cool, dry place
- Avoid direct sunlight
- Use within 1-2 years
- Keep away from heat sources

---

## Cost Optimization

### Label Recommendations
- **58mm x 40mm** - Most economical
- **1000 labels per roll** - Standard
- **Direct thermal paper** - No ribbon needed
- **Quality**: Medium grade (for library use)

### Print Settings
- **Darkness**: Medium (saves thermal head)
- **Speed**: Medium (better quality, less waste)
- **Calibration**: Regular (prevents waste)

---

## Scanner Compatibility

### Optic X-9300 + Xprinter XP-635B
✅ **Perfect Combination**
- Thermal printed barcodes scan well
- CODE128 supported by both
- Compact labels easy to apply
- High contrast for reliable scanning

### Testing
1. Print test barcode
2. Apply to book
3. Scan with Optic X-9300
4. Verify number matches

---

## Quick Reference

**Barcode Format**: CODE128
**Label Size**: 58mm x 40mm
**Print Method**: Direct Thermal
**Margins**: 0mm
**One Barcode Per Label**: Yes ✅
**Clean Output**: Yes ✅
**Scanner Compatible**: Yes ✅

---

## Support

**Printer Manual**: Check for detailed specifications
**Label Supplier**: Ensure correct size (58mm x 40mm)
**Thermal Paper**: Direct thermal, not thermal transfer
**Test Print**: Always test before bulk printing
