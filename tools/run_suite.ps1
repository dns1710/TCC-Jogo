param([string[]]$Suites)
$g = "D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe"
foreach ($s in $Suites) {
    Write-Host "=== $s"
    $out = & $g --headless --path . "res://tools/$s.tscn" 2>&1 | Out-String
    $code = $LASTEXITCODE
    ($out -split "`n") | Where-Object { $_ -notmatch "leak|ObjectDB|^\s+at:|resources still|^\s*$" } | Select-Object -First 25
    Write-Host "exit=$code"
}
