# Generate site-data.json (full descriptions + keywords + community merge) for the website.
# Path-independent: reads/writes next to this script (tools/).
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$toolsDir = $PSScriptRoot

$topDataPath = Join-Path $toolsDir 'top-data.json'
if (-not (Test-Path $topDataPath)) {
  Write-Output 'top-data.json missing; downloading from xiaohai-78/Top ...'
  Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/xiaohai-78/Top/main/data.json' -UseBasicParsing -TimeoutSec 60 -OutFile $topDataPath
}
$raw = [System.IO.File]::ReadAllText($topDataPath, [System.Text.Encoding]::UTF8)
$j = $raw | ConvertFrom-Json
$byName = @{}
foreach ($r in $j.repos) { $byName[$r.name] = $r }

$cats = [ordered]@{
  'Web UI 与主题' = @('dsh-ui-whale','dsh-stickers','dsh-skins','dsh-qq2006','dsh-deep-whale','dsh-custom-css','chat-width','dsh-focus-chat','dsh-web-archive','dsh-question-collapse','dsh-suggested-replies','dsh-selection-chat','dsh-message-edit','dsh-input-history','dsh-paste-input','dsh-drag-and-drop','dsh-multimedia-webui-input','dsh-web-ui-notify','dsh-live-stats','dsh-tps','dsh-ui-progress','dsh-task-status','dsh-working-activity','dsh-navbar','dsh-turn-navigator','dsh-split-panes','dsh-diff-viewer','dsh-annotation','dsh-chat-thumb','dsh-mobileweb-adapter')
  '会话、记忆与上下文' = @('dsh-memory-evolve','dsh-easy-ctx-manager','session-persistence-rdb','session-teleport','dsh-session-search','dsh-session-health','dsh-engram-relay','zotero-wave-rag','dsh-kb-sieve','dsh-context7','dsh-mnemon','dsh-session-cluster','dsh-turn-rewind','dsh-rewind','dsh-checkpoint','context-doctor','session-chatlog','dsh-skill-session-recovery')
  '工具集与数据' = @('dsh-toolkit','dsh-tool-json','dsh-tool-calculator','dsh-tool-regex','dsh-tool-csv','dsh-tool-time','dsh-tool-encoding','dsh-tool-markdown','dsh-tool-diff','dsh-tool-stat','dsh-tool-schema','dsh-tool-search','dsh-tool-browser','dsh-code-map','dsh-data-agent','dsh-latex','dsh-mineru','dsh-bash-encoding')
  'Agent 循环与工作流' = @('dsh-slice-agent-loop','dsh-sidechain','dsh-plan-execute','dsh-evolve','dsh-deep-research','dsh-deepresearch','mstar-workflow','dsh-alphasolve','dsh-agent-budget','dsh-subagent-tree','dsh-advisor','dsh-a2a','dsh-acp','dsh-pi-adapter','dsh-teamwork','dsh-self-control-guard','dsh-llm-fallbacks','dsh-auto-approval','dsh-super-injector','dsh-web-workflow-visualizer','dsh-inspect')
  '桌面、终端与远程' = @('deepseek-harness-desktop','oh-dsh-desktop','dsh-desktop-mac','dsh-desktop-electron','dsh-companion','dsh-pet','dsh-island','dsh-web-panel','dsh-cc-tui','dsh-grok-tui','dsh-opencode-server','dsh-tui-front-door','dsh-vscode','dsh-cc-connect','dsh-remote','dsh-android','dsh-ohos-patch','dsh-pty-windows','dsh-shell-windows','dsh-desktop-tools','dsh-session-hub')
  '浏览器与消息通道' = @('dsh-browser','dsh-browser-panel','dsh-kimi-browser','dsh-webbridge','dsh-kimi-bridge','dsh-codex-bridge','ego-browser','dsh-browser-bridge','dsh-wecom-bot','dsh-weixin-bot','qqbot','dsh-feishu-bot','dsh-feishu-notify','telegram','tg-bot','dsh-voice-chat','dsh-computer-use')
  '视觉与生成式 UI' = @('dsh-vision','dsh-vision-toolkit','dsh-genui','dsh-visualize','dsh-aigc-canvas','dsh-design','DSH-UI4A','dsh-prompt-studio')
  '学习、生态与基建' = @('dshfind','dsh-101','dsh-explain','dsh-plugin-guide','dsh-plugin-dev','dsh-cordis-rocks','dsh-plugin-skills','dsh-skill-stats','dsh-skills-manager','dsh-plugin-check','deep-standard-skill','plugin-registry','hub','marisa','dsh-mega','dsh-plus','official-plugins-port','dsh-harness-ops','dsh-security-audit','dsh-cyber-sec','dsh-trace','dsh-external-research','dsh-coding-receipt','plugin-template','dsh-cordis-examples')
  '游戏与整活' = @('dsh-minigames','dsh-gomoku','dsh-auto-chess','dsh-d399','dsh-lazyfish','dsh-meme','dsh-music-player','dsh-ads','dsh-anti-ads','dsh-sfw','7d7d','toybox','deepseek-manners','dsh-stock-market','dsh-tavern-plugin','dsh-agent-rp','group-chat-diary','dsh-club','whale-girl','ui-status-label')
}

$out = [ordered]@{}
$out['src'] = 'dsh-external (via xiaohai-78/Top, 2026-08-13)'
$out['gen'] = (Get-Date).ToString('yyyy-MM-dd')
$out['live'] = 'https://raw.githubusercontent.com/xiaohai-78/Top/main/data.json'
$out['cats'] = [ordered]@{}

# ---- keyword dictionary for the tag-cloud / keyword lookup ----
$keywordMap = [ordered]@{
  '记忆'   = @('记忆','memory')
  '上下文' = @('上下文','context')
  '会话'   = @('会话','session')
  '搜索'   = @('搜索','search')
  '工具'   = @('工具','tool')
  '侧边栏' = @('侧边栏','sidebar')
  '终端'   = @('终端','terminal','pty')
  'TUI'    = @('tui')
  'Git'    = @('git')
  '浏览器' = @('浏览器','browser','chrome')
  '视觉'   = @('视觉','vision','图片','截图','ocr')
  '语音'   = @('语音','voice')
  '通知'   = @('通知','notify')
  '工作流' = @('工作流','workflow')
  'Agent'  = @('agent','子代理')
  '技能'   = @('技能','skill')
  '皮肤'   = @('皮肤','换肤','skin','主题')
  '桌宠'   = @('桌宠','宠物','pet','鲸鱼','whale')
  '游戏'   = @('游戏','五子棋','自走棋','game','俄罗斯方块')
  '远程'   = @('远程','ssh','remote')
  'MCP'    = @('mcp')
  'RAG'    = @('rag','知识库')
  'LaTeX'  = @('latex')
  '数据'   = @('数据','data','database','sql')
  '表情'   = @('表情','sticker','meme')
  '聊天'   = @('聊天','chat','对话')
  'Web'    = @('web')
  '桌面'   = @('桌面','desktop')
  '移动'   = @('手机','mobile','android','ios','pwa')
  '进度'   = @('进度','progress','任务')
  'Diff'   = @('diff','差异')
  'JSON'   = @('json')
  'CSV'    = @('csv')
  '正则'   = @('正则','regex')
  'Markdown' = @('markdown')
  '时间'   = @('时间','time','tps','日期')
  '编码'   = @('编码','encoding','base64','哈希','hash')
  '安全'   = @('安全','security','审计','audit','渗透')
  '分享'   = @('分享','share')
  '批注'   = @('批注','annotation')
  '回滚'   = @('回滚','rewind','回溯')
  '角色'   = @('角色扮演','rp','tavern','silly')
  '音乐'   = @('音乐','music')
  '股票'   = @('股票','stock')
  '历史'   = @('历史','history')
  '健康'   = @('健康','health')
  '代码'   = @('代码','code','编程','vscode')
  '文档'   = @('文档','阅读','doc')
}
function Get-Keywords($name, $desc, $topics) {
  $hay = (($name + ' ' + $desc + ' ' + $topics).ToLowerInvariant())
  $hits = New-Object System.Collections.Generic.List[string]
  foreach ($kw in $keywordMap.Keys) {
    foreach ($pat in $keywordMap[$kw]) {
      if ($hay.Contains($pat.ToLowerInvariant())) {
        $hits.Add($kw)
        break
      }
    }
    if ($hits.Count -ge 6) { break }
  }
  return @($hits)
}

foreach ($cat in $cats.Keys) {
  $items = @()
  foreach ($n in $cats[$cat]) {
    $r = $byName[$n]
    if ($null -eq $r) { continue }
    $desc = [string]$r.description
    if ($desc.Length -gt 200) { $desc = $desc.Substring(0, 197) + '…' }
    $lang = if ($null -ne $r.primaryLanguage) { $r.primaryLanguage.name } else { '' }
    $topics = if ($r.allTopics) { @($r.allTopics) } else { @() }
    $items += [ordered]@{ n = $n; s = $r.starsCount; l = $lang; d = $desc; t = $topics; k = (Get-Keywords $n $desc ($topics -join ' ')) }
  }
  $out['cats'][$cat] = $items
}

# --- merge community plugins (public dsh-plugin topic, validated) ---
$commFile = Join-Path $toolsDir 'community-plugins.json'
if (Test-Path $commFile) {
  $comm = ([System.IO.File]::ReadAllText($commFile, [System.Text.Encoding]::UTF8) | ConvertFrom-Json).plugins
  $byName = @{}
  foreach ($cat in $out['cats'].GetEnumerator()) {
    foreach ($it in $cat.Value) { $byName[$it.n] = $it }
  }
  $fresh = New-Object System.Collections.Generic.List[object]
  $mirrorCount = 0
  foreach ($pl in $comm) {
    if ($byName.ContainsKey($pl.name)) {
      # curated entry gets a public mirror link
      $it = $byName[$pl.name]
      if (-not $it.Contains('u')) {
        $it['u'] = $pl.url
        $mirrorCount++
      }
    } else {
      $d = [string]$pl.desc
      if ($d.Length -gt 200) { $d = $d.Substring(0, 197) + '…' }
      $topics = if ($pl.topics) { @($pl.topics) } else { @() }
      $fresh.Add([ordered]@{ n = $pl.name; s = $pl.stars; l = $pl.lang; d = $d; u = $pl.url; o = $pl.owner; t = $topics; k = (Get-Keywords $pl.name $d ($topics -join ' ')) })
    }
  }
  if ($fresh.Count -gt 0) {
    $out['cats']['社区开源 (dsh-plugin topic)'] = @($fresh | Sort-Object { $_.s } -Descending)
  }
  Write-Output "community merged: $mirrorCount mirrors linked, $($fresh.Count) fresh added"
}

$json = $out | ConvertTo-Json -Depth 6 -Compress
# PS 5.1 ConvertTo-Json unrolls single-element arrays at depth; force k/t to always be arrays
$json = [regex]::Replace($json, '"("?(k|t)"?):"([^"]*)"', '"$2":["$3"]')
$siteDataPath = Join-Path $toolsDir 'site-data.json'
[System.IO.File]::WriteAllText($siteDataPath, $json, (New-Object System.Text.UTF8Encoding($false)))
$total = 0
foreach ($cat in $out['cats'].GetEnumerator()) { $total += $cat.Value.Count }
Write-Output "site-data.json: $total items, $((Get-Item $siteDataPath).Length) bytes"
