param(
    [string]$GodotPath = "",
    [ValidateSet('play', 'test', 'chapter-test', 'ui-test', 'ui-logic-test', 'tutorial-test', 'presentation-test')]
    [string]$Mode = 'play'
)
$ErrorActionPreference = 'Stop'
$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'project.godot'))) {
    throw 'project.godot not found. Keep this script inside the project tools folder.'
}
if ([string]::IsNullOrWhiteSpace($GodotPath)) {
    foreach ($Name in @('godot', 'godot4', 'godot_console')) {
        $Command = Get-Command $Name -ErrorAction SilentlyContinue
        if ($Command) { $GodotPath = $Command.Source; break }
    }
    if ([string]::IsNullOrWhiteSpace($GodotPath) -and (Test-Path -LiteralPath 'D:\godot')) {
        $Candidate = Get-ChildItem -LiteralPath 'D:\godot' -Recurse -File -Filter 'Godot*.exe' |
            Where-Object { $_.Name -like '*_console.exe' } |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($Candidate) { $GodotPath = $Candidate.FullName }
    }
}
if ([string]::IsNullOrWhiteSpace($GodotPath) -or -not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
    throw 'Godot not found. Open project.godot in Godot and press F5, or pass -GodotPath to this script.'
}
$ConsolePath = $GodotPath -replace '(?<!_console)\.exe$', '_console.exe'
if ($Mode -ne 'play' -and (Test-Path -LiteralPath $ConsolePath)) { $GodotPath = $ConsolePath }
$LocalDir = Join-Path $ProjectRoot '.local'
New-Item -ItemType Directory -Path $LocalDir -Force | Out-Null
$RunArgs = @('--path', $ProjectRoot, '--log-file', (Join-Path $LocalDir ($Mode + '.log')))
switch ($Mode) {
    'test' { $RunArgs += @('--headless', '--script', 'res://tests/test_suite.gd') }
    'chapter-test' { $RunArgs += @('--headless', '--script', 'res://tests/chapter_probe.gd', '--', '--many-seeds') }
    'ui-test' { $RunArgs += @('--script', 'res://tests/ui_test.gd', '--', '--ui-test') }
    'presentation-test' { $RunArgs += @('--script', 'res://tests/presentation_test.gd', '--', '--ui-test') }
    'tutorial-test' { $RunArgs += @('--headless', '--script', 'res://tests/tutorial_test.gd', '--', '--ui-test') }
    'ui-logic-test' { $RunArgs += @('--headless', '--script', 'res://tests/ui_logic_test.gd', '--', '--ui-test') }
}
Set-Location -LiteralPath $ProjectRoot
& $GodotPath @RunArgs | Out-Host
exit $LASTEXITCODE
