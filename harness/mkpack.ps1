# mkpack.ps1: assemble the Windows pack and zip it.
#   -Vme   vme.exe from build-windows.sh
#   -Roms  directory holding mvme147.zip
#   -Disk  the installed disk, compressed (chdman copy -i sysv68.chd -o sysv68-r3v7.chd)
#   -Out   where the pack folder and its zip go (default: .\out)
param([Parameter(Mandatory)] [string]$Vme, [Parameter(Mandatory)] [string]$Roms,
      [Parameter(Mandatory)] [string]$Disk, [string]$Out = 'out')
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$Out = (New-Item -ItemType Directory -Force $Out).FullName
$pack = Join-Path $Out 'SysV68-MVME147-Windows'
if (Test-Path $pack) { Remove-Item $pack -Recurse -Force }
New-Item -ItemType Directory -Force $pack, "$pack\roms", "$pack\disk", "$pack\ini" | Out-Null
Copy-Item $Vme "$pack\vme.exe"
$strip = Get-Command strip.exe -ErrorAction SilentlyContinue
if ($strip) { & $strip.Source "$pack\vme.exe" }
Copy-Item (Join-Path $Roms 'mvme147.zip') "$pack\roms\"
Copy-Item $Disk "$pack\disk\sysv68-r3v7.chd"
Copy-Item "$repo\harness\lua\autoboot.lua" $pack
Copy-Item "$repo\pack\ini\ui.ini" "$pack\ini\"
# a blank MAME NVRAM is all 0xff, and 147Bug then boots a file named by that garbage; ship it zeroed
New-Item -ItemType Directory -Force "$pack\state\nvram\miniforce" | Out-Null
[IO.File]::WriteAllBytes("$pack\state\nvram\miniforce\vme_slot1_mvme147_m48t18", (New-Object byte[] 2048))
foreach ($f in 'SYSV68.bat', 'RESET.bat', 'README.txt') {
    $t = (Get-Content "$repo\pack\$f" -Raw) -replace "`r?`n", "`r`n"
    [IO.File]::WriteAllText("$pack\$f", $t, [Text.Encoding]::ASCII)
}
$zip = "$pack.zip"
if (Test-Path $zip) { Remove-Item $zip }
Compress-Archive -Path $pack -DestinationPath $zip -CompressionLevel Optimal
Get-Item $zip | Select-Object FullName, Length
