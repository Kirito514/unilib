# Consolidate ALL SQL files from supabase folder into one
# Date: 2025-12-13

$outputFile = "supabase\ALL_SQL_CONSOLIDATED.sql"

Write-Host "Searching for all SQL files in supabase folder..." -ForegroundColor Cyan

# Find all SQL files recursively
$sqlFiles = Get-ChildItem -Path "supabase" -Filter "*.sql" -Recurse | Sort-Object FullName

Write-Host "Found $($sqlFiles.Count) SQL files`n" -ForegroundColor Green

# Header
@"
-- ============================================================================
-- ALL SQL FILES CONSOLIDATED - UniLib Platform
-- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
-- Total Files: $($sqlFiles.Count)
-- Description: Every single SQL file from supabase folder
-- ============================================================================

"@ | Out-File -FilePath $outputFile -Encoding UTF8

# Add each file with separator
$fileCount = 0
foreach ($file in $sqlFiles) {
    $fileCount++
    $relativePath = $file.FullName.Replace("$PWD\", "")
    
    Write-Host "[$fileCount/$($sqlFiles.Count)] Adding: $relativePath" -ForegroundColor Green
    
    # Add separator
    @"

-- ============================================================================
-- FILE $fileCount of $($sqlFiles.Count): $relativePath
-- Size: $([math]::Round($file.Length / 1KB, 2)) KB
-- ============================================================================

"@ | Out-File -FilePath $outputFile -Append -Encoding UTF8
    
    # Add file content
    Get-Content $file.FullName -Raw | Out-File -FilePath $outputFile -Append -Encoding UTF8
}

# Footer
@"

-- ============================================================================
-- END OF CONSOLIDATED FILE
-- Total Files Included: $($sqlFiles.Count)
-- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
-- ============================================================================
"@ | Out-File -FilePath $outputFile -Append -Encoding UTF8

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Consolidation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Output file: $outputFile" -ForegroundColor Yellow
Write-Host "Total files: $($sqlFiles.Count)" -ForegroundColor Yellow
Write-Host "File size: $([math]::Round((Get-Item $outputFile).Length / 1KB, 2)) KB" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# List all included files
Write-Host "Included files:" -ForegroundColor Cyan
$sqlFiles | ForEach-Object { 
    $relativePath = $_.FullName.Replace("$PWD\", "")
    Write-Host "  - $relativePath" -ForegroundColor Gray
}
