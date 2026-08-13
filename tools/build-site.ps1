# Build the site index.html by injecting tools/site-data.json into tools/index.html.template.
# Writes to the repo root (parent of tools/). Path-independent.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$toolsDir = $PSScriptRoot
$repoRoot = Split-Path $toolsDir -Parent

$json = [System.IO.File]::ReadAllText((Join-Path $toolsDir 'site-data.json'), [System.Text.Encoding]::UTF8)
# JSON is valid JS; only guard against "</script" inside strings breaking the HTML
$safe = $json -replace '</', '<\/'
$inject = "window.AWESOME = $safe;"
$tpl = [System.IO.File]::ReadAllText((Join-Path $toolsDir 'index.html.template'), [System.Text.Encoding]::UTF8)
$marker = '/*__AWESOME_DATA__*/'
if (-not $tpl.Contains($marker)) { throw 'marker not found in template' }
$final = $tpl.Replace($marker, $inject)
$outPath = Join-Path $repoRoot 'index.html'
[System.IO.File]::WriteAllText($outPath, $final, (New-Object System.Text.UTF8Encoding($false)))
Write-Output "index.html written: $((Get-Item $outPath).Length) bytes"
