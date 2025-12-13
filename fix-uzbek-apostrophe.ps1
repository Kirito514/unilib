# Uzbek Apostrophe Fix Script
# Replaces o'with o'(U+02BB) in TypeScript/TSX files

$files = Get-ChildItem -Path ".\app", ".\components" -Include *.tsx, *.ts -Recurse

$count = 0
$filesChanged = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $originalContent = $content
    
    # Replace o'with o'(U+02BB - modifier letter turned comma)
    $content = $content -replace "o'", "o'"
    
    # Replace g' with gʻ (U+02BB)
    $content = $content -replace "g'", "gʻ"
    
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
        $filesChanged++
        Write-Host "✓ Fixed: $($file.Name)" -ForegroundColor Green
        
        # Count replacements
        $replacements = ([regex]::Matches($originalContent, "o'|g'")).Count
        $count += $replacements
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "✅ Tuzatish tugadi!" -ForegroundColor Green
Write-Host "Files changed: $filesChanged" -ForegroundColor Yellow
Write-Host "Total replacements: $count" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
