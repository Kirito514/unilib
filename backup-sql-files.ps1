# Move all SQL files to backup folder (except ALL_SQL_CONSOLIDATED.sql)
# Date: 2025-12-13

$backupFolder = "supabase\backup"
$consolidatedFile = "supabase\ALL_SQL_CONSOLIDATED.sql"

Write-Host "Creating backup folder..." -ForegroundColor Cyan

# Create backup folder if it doesn't exist
if (!(Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder | Out-Null
    Write-Host "Created: $backupFolder" -ForegroundColor Green
} else {
    Write-Host "Backup folder already exists" -ForegroundColor Yellow
}

# Find all SQL files except the consolidated one
$sqlFiles = Get-ChildItem -Path "supabase" -Filter "*.sql" -Recurse | 
    Where-Object { $_.FullName -ne (Resolve-Path $consolidatedFile).Path }

Write-Host "`nFound $($sqlFiles.Count) SQL files to move`n" -ForegroundColor Green

# Move each file
$movedCount = 0
foreach ($file in $sqlFiles) {
    $relativePath = $file.FullName.Replace("$PWD\supabase\", "")
    $targetPath = Join-Path $backupFolder $relativePath
    $targetDir = Split-Path $targetPath -Parent
    
    # Create target directory if needed
    if (!(Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    
    # Move file
    Move-Item -Path $file.FullName -Destination $targetPath -Force
    $movedCount++
    Write-Host "[$movedCount/$($sqlFiles.Count)] Moved: $relativePath" -ForegroundColor Gray
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Backup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Files moved: $movedCount" -ForegroundColor Yellow
Write-Host "Backup location: $backupFolder" -ForegroundColor Yellow
Write-Host "Main file: $consolidatedFile" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# Show current SQL files in supabase folder
Write-Host "Current SQL files in supabase folder:" -ForegroundColor Cyan
Get-ChildItem -Path "supabase" -Filter "*.sql" -Recurse | ForEach-Object {
    $relativePath = $_.FullName.Replace("$PWD\", "")
    Write-Host "  OK $relativePath" -ForegroundColor Green
}
