# pack-test.ps1: unzip the pack and run its SYSV68.bat exactly as shipped, headless, driven by
# pack-test.lua: log in, type a few commands, shut down. -Again boots the same copy once more.
param([Parameter(Mandatory)] [string]$Zip, [string]$Dir = 'pack-test-run', [switch]$Again)
$ErrorActionPreference = 'Stop'
$Dir = (New-Item -ItemType Directory -Force $Dir).FullName
$pack = Join-Path $Dir 'SysV68-MVME147-Windows'
if (-not $Again) {
    if (Test-Path $pack) { Remove-Item $pack -Recurse -Force }
    Expand-Archive $Zip -DestinationPath $Dir
}
Remove-Item "$Dir\console.txt" -ErrorAction SilentlyContinue
$env:PACK = $pack
$env:TESTDIR = $Dir
$t0 = Get-Date
& cmd /c "`"$pack\SYSV68.bat`" -video none -sound none -seconds_to_run 1200 -autoboot_script `"$PSScriptRoot\pack-test.lua`"" > "$Dir\mame.txt" 2>&1
"exit $LASTEXITCODE, $([int]((Get-Date) - $t0).TotalSeconds) s"
Select-String -Path "$Dir\console.txt" -Pattern 'M68030|ERASE-OK|secured for powering down|\[pack-test\]' | ForEach-Object { $_.Line }
