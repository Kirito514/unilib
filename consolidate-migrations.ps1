# Consolidate all SQL migration files into one
# Date: 2025-12-13

$outputFile = "supabase\CONSOLIDATED_ALL_MIGRATIONS.sql"

# Header
@"
-- ============================================================================
-- CONSOLIDATED MIGRATION FILE - UniLib Platform
-- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
-- Description: All SQL migrations consolidated into single file
-- ============================================================================

"@ | Out-File -FilePath $outputFile -Encoding UTF8

# List of important migration files in order
$migrationFiles = @(
    "supabase\migrations\20251213_add_student_id.sql",
    "supabase\migrations\20251213_add_student_id_trigger.sql",
    "supabase\FORCE_CREATE_INDEXES.sql",
    "supabase\FIX_STUDENT_IDS.sql"
)

# Add each file with separator
foreach ($file in $migrationFiles) {
    if (Test-Path $file) {
        Write-Host "Adding: $file" -ForegroundColor Green
        
        # Add separator
        @"

-- ============================================================================
-- FILE: $file
-- ============================================================================

"@ | Out-File -FilePath $outputFile -Append -Encoding UTF8
        
        # Add file content
        Get-Content $file | Out-File -FilePath $outputFile -Append -Encoding UTF8
    } else {
        Write-Host "Skipping (not found): $file" -ForegroundColor Yellow
    }
}

# Footer
@"

-- ============================================================================
-- END OF CONSOLIDATED MIGRATION
-- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
-- ============================================================================
"@ | Out-File -FilePath $outputFile -Append -Encoding UTF8

Write-Host "`nConsolidation complete!" -ForegroundColor Cyan
Write-Host "Output file: $outputFile" -ForegroundColor Cyan
Write-Host "`nFile size: $((Get-Item $outputFile).Length / 1KB) KB" -ForegroundColor Green
