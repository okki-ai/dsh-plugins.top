# Discover & validate public dsh-plugin topic repos, then emit a catalog JSON.
# Validation heuristics for "is a legitimate DSH plugin":
#   +3  dsh.plugin.json manifest exists (marisa protocol)
#   +3  package.json has top-level "dsh" key with bundle info (official dsh.bundle.patch protocol)
#   +2  package.json dependencies reference @deepseek-ai/* or cordis
#   +1  repo name starts with dsh- / contains dsh
#   +1  description mentions DeepSeek Harness / dsh
# Valid when score >= 3.
# Path-independent: outputs next to this script (tools/community-plugins.json).
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$headers = @{ 'User-Agent' = 'dsh-discover-agent' }
$outFile = Join-Path $PSScriptRoot 'community-plugins.json'

$topics = @('dsh-plugin', 'deepseek-harness')
$catalog = [ordered]@{}
$order = New-Object System.Collections.Generic.List[string]

foreach ($topic in $topics) {
  for ($page = 1; $page -le 2; $page++) {
    $url = "https://api.github.com/search/repositories?q=topic:$topic&sort=stars&order=desc&per_page=100&page=$page"
    Write-Output "== search topic: $topic (page $page)"
    try {
      $resp = Invoke-RestMethod -Uri $url -Headers $headers -UseBasicParsing -TimeoutSec 30
    } catch {
      Write-Output "  search failed: $($_.Exception.Message)"
      continue
    }
    if ($page -eq 1) { Write-Output "  total_count: $($resp.total_count)" }
    foreach ($it in $resp.items) {
      if ($it.fork) { continue }
      $fn = $it.full_name
      if (-not $catalog.Contains($fn)) {
        $catalog[$fn] = [ordered]@{
          name       = $it.name
          owner      = $it.owner.login
          url        = $it.html_url
          stars      = $it.stargazers_count
          lang       = $it.language
          desc       = $it.description
          topics     = @($it.topics)
          branch     = $it.default_branch
          archived   = $it.archived
          signals    = [ordered]@{}
          score      = 0
          valid      = $false
          excluded   = ''
        }
        $order.Add($fn)
      }
    }
  }
}

if ($order.Count -eq 0) {
  Write-Output 'no candidates found (network/search failed); keeping existing community-plugins.json'
  exit 0
}

Write-Output "== validating $($order.Count) candidates (raw file probes)"
function Get-Raw($fn, $branch, $file) {
  $u = "https://raw.githubusercontent.com/$fn/$branch/$file"
  try {
    $r = Invoke-WebRequest -Uri $u -Headers $headers -UseBasicParsing -TimeoutSec 15
    return $r.Content
  } catch { return $null }
}

foreach ($fn in $order) {
  $repo = $catalog[$fn]
  $sig = $repo.signals
  $score = 0
  $branch = $repo.branch

  $pkgText = Get-Raw $fn $branch 'package.json'
  if ($pkgText) {
    try {
      $pkg = $pkgText | ConvertFrom-Json
      if ($pkg.PSObject.Properties['dsh']) {
        $sig['pkg.dsh'] = 'package.json has "dsh" key'
        $score += 3
      }
      $deps = @()
      if ($pkg.PSObject.Properties['dependencies']) { $deps += $pkg.dependencies.PSObject.Properties.Name }
      if ($pkg.PSObject.Properties['devDependencies']) { $deps += $pkg.devDependencies.PSObject.Properties.Name }
      $dshell = $deps | Where-Object { $_ -like '@deepseek-ai/*' -or $_ -eq 'cordis' }
      if ($dshell) {
        $sig['pkg.deps'] = ('deps: ' + ($dshell -join ', '))
        $score += 2
      }
      if ($pkg.name -and $pkg.name -like 'dsh-*') {
        $sig['pkg.name'] = 'name starts with dsh-'
        $score += 1
      }
    } catch { $sig['pkg.parse'] = 'package.json unparsable' }
  }

  $manifest = Get-Raw $fn $branch 'dsh.plugin.json'
  if ($manifest) {
    $sig['manifest'] = 'dsh.plugin.json exists'
    $score += 3
  }

  $desc = [string]$repo.desc
  if ($desc -match 'deepseek[- ]harness| dsh|plugin') {
    $sig['desc'] = 'description mentions DSH/plugin'
    $score += 1
  }
  if ($repo.name -match '^dsh-|dsh') { $score += 1 }

  $repo.score = $score
  $repo.valid = ($score -ge 3)
  if ($fn -eq 'deepseek-ai/deepseek-harness') {
    $repo.valid = $false
    $repo.excluded = 'core harness repo, not a plugin'
  }
  if ($repo.archived) {
    $repo.valid = $false
    if (-not $repo.excluded) { $repo.excluded = 'archived' }
  }
}

$valid = @($catalog.GetEnumerator() | Where-Object { $_.Value.valid } | Sort-Object { $_.Value.score } -Descending)
Write-Output ""
Write-Output "== VALID plugins: $($valid.Count) / $($order.Count)"

# ---- emit catalog json ----
$out = [ordered]@{
  source  = 'GitHub public topics: dsh-plugin + deepseek-harness'
  fetched = (Get-Date).ToString('yyyy-MM-dd HH:mm')
  total_candidates = $order.Count
  plugins = @()
}
foreach ($fn in ($valid | ForEach-Object { $_.Key })) {
  $v = $catalog[$fn]
  $out.plugins += [ordered]@{
    name = $v.name; owner = $v.owner; url = $v.url
    stars = $v.stars; lang = $v.lang; desc = $v.desc
    topics = @($v.topics); signals = ($v.signals | ForEach-Object { "$($_.Name)" }) -join ', '
    score = $v.score
    archived = $v.archived
    excluded = $v.excluded
  }
}
$json = $out | ConvertTo-Json -Depth 6 -Compress
[System.IO.File]::WriteAllText($outFile, $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Output ""
Write-Output "community-plugins.json written: $($out.plugins.Count) plugins"
