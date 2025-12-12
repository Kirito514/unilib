# Optic X-9300 Scanner - Barcode Optimization Guide

## Scanner Specifications

**Model**: Optic X-9300 (Сканер штрих-кода)
**Type**: Handheld/Desktop Barcode Scanner
**Common Use**: Retail, Library, Warehouse

---

## Supported Barcode Formats

Optic X-9300 typically supports:
- ✅ **CODE128** - Supported
- ✅ **EAN-13** - Supported
- ✅ **EAN-8** - Supported
- ✅ **Code39** - Supported
- ✅ **Code93** - Supported
- ✅ **UPC-A/E** - Supported
- ✅ **Interleaved 2 of 5** - Supported

**Good News**: CODE128 is supported! ✅

---

## Common Issues & Solutions

### Issue 1: Barcode Too Small
**Problem**: Scanner cannot focus on small barcodes
**Solution**: Increase barcode size

**Current Settings**:
```typescript
width: 3,
height: 100
```

**Recommended Settings**:
```typescript
width: 4,      // Wider bars
height: 120,   // Taller barcode
margin: 15     // More white space
```

---

### Issue 2: Print Quality
**Problem**: Blurry or low-contrast print
**Solutions**:
- Use high-quality printer (300+ DPI)
- Print on white paper (not gray/colored)
- Use laser printer (not inkjet if possible)
- Ensure black ink is fresh

---

### Issue 3: Barcode Density
**Problem**: Bars too close together
**Solution**: Increase width parameter

**Test Different Widths**:
- width: 2 - Very dense (hard to scan)
- width: 3 - Medium density (current)
- width: 4 - Recommended for Optic X-9300
- width: 5 - Very wide (easier to scan)

---

### Issue 4: Scanner Configuration
**Problem**: Scanner not configured for CODE128
**Solution**: Check scanner settings

**How to Configure Optic X-9300**:
1. Scan configuration barcode from manual
2. Enable CODE128 symbology
3. Set to auto-detect mode
4. Test with sample barcode

---

## Recommended Barcode Settings for Optic X-9300

### Optimal Configuration
```typescript
JsBarcode(canvas, barcode, {
    format: 'CODE128',
    width: 4,              // ✅ Increased for better scanning
    height: 120,           // ✅ Taller for easier targeting
    displayValue: true,
    fontSize: 22,          // ✅ Larger text
    margin: 15,            // ✅ More white space
    background: '#ffffff',
    lineColor: '#000000',
    textMargin: 8,
    marginTop: 15,
    marginBottom: 15,
    flat: true             // ✅ Better for some scanners
});
```

---

## Print Recommendations

### Paper Size
- **A4** or **Letter** size
- **White** background only
- **80gsm+** paper weight

### Print Settings
- **Quality**: Best/High
- **Color**: Black & White
- **Scale**: 100% (no scaling)
- **Margins**: At least 1cm on all sides

### Printer Type
- ✅ **Laser Printer** - Best quality
- ⚠️ **Inkjet** - Acceptable if high quality
- ❌ **Thermal** - May fade over time

---

## Testing Procedure

### Step 1: Print Test Barcode
1. Generate barcode with new settings
2. Print on white A4 paper
3. Check print quality visually

### Step 2: Scanner Test
1. Hold scanner 5-15cm from barcode
2. Press trigger button
3. Listen for beep sound
4. Check if number appears

### Step 3: Troubleshooting
If still not working:
- Try different distances (5cm, 10cm, 15cm)
- Adjust lighting (avoid glare)
- Try different angles
- Check scanner battery/power

---

## Alternative Solutions

### Option 1: Use EAN-13 Format
If CODE128 still doesn't work:
```typescript
format: 'EAN13',  // More widely supported
```

**Note**: Requires exactly 13 digits

### Option 2: Use Code39 Format
More basic but very reliable:
```typescript
format: 'CODE39',
```

**Note**: Larger size, fewer characters

### Option 3: Add Quiet Zones
Increase margins for better detection:
```typescript
margin: 20,  // Large white space around barcode
```

---

## Quick Fix Checklist

- [ ] Increase width to 4
- [ ] Increase height to 120
- [ ] Increase margins to 15
- [ ] Print on white paper
- [ ] Use laser printer if available
- [ ] Check scanner is powered on
- [ ] Verify scanner beeps when triggered
- [ ] Test at 10cm distance
- [ ] Ensure good lighting
- [ ] Check barcode is not wrinkled

---

## Expected Results

**After Optimization**:
- ✅ Scanner should beep immediately
- ✅ Barcode number should appear in input
- ✅ Scan distance: 5-20cm
- ✅ Scan time: < 1 second
- ✅ Success rate: 95%+

---

## Support Resources

**Scanner Manual**: Check for configuration barcodes
**Test Barcode**: Generate simple "123456789012" for testing
**Scanner Settings**: May need to enable CODE128 in scanner config

---

## Next Steps

1. Update barcode settings (width: 4, height: 120)
2. Print new test barcodes
3. Test with Optic X-9300
4. Report results
5. Fine-tune if needed
