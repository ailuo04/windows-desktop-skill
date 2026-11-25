#requires -Version 7.0
[CmdletBinding()]
param(
    [string]$SkillsRoot,
    [switch]$UpdateSkill
)

$ErrorActionPreference = 'Stop'
if (-not $IsWindows) { throw '此安装脚本需要 Windows 和 PowerShell 7。' }
$configRoot = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
$skillName = 'agent-desktop-windows'
if (-not $SkillsRoot) {
    $SkillsRoot = Join-Path $env:USERPROFILE '.agents/skills'
    $legacyRoot = Join-Path $configRoot 'skills'
    if ((Test-Path -LiteralPath (Join-Path $legacyRoot "$skillName/SKILL.md")) -and
        -not (Test-Path -LiteralPath (Join-Path $SkillsRoot "$skillName/SKILL.md"))) {
        $SkillsRoot = $legacyRoot
    }
}
$source = Join-Path $PSScriptRoot "skills/$skillName/SKILL.md"
$targetDir = Join-Path $SkillsRoot $skillName
$target = Join-Path $targetDir 'SKILL.md'
$sourceHash = (Get-FileHash -LiteralPath $source).Hash
$exists = Test-Path -LiteralPath $target
$needsCopy = -not $exists -or (Get-FileHash -LiteralPath $target).Hash -ne $sourceHash
if ($exists -and $needsCopy -and -not $UpdateSkill) {
    throw "目标文件已存在且内容不同。核对后可用 -UpdateSkill 更新：$target"
}

$codex = Get-Command codex.cmd,codex.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $codex) { throw '需要可在终端运行的 Codex CLI。安装后重新运行此脚本。' }
$listing = & $codex.Source mcp list --json
if ($LASTEXITCODE -ne 0) { throw '读取 Codex MCP 配置失败。' }
$server = ($listing | ConvertFrom-Json) | Where-Object name -eq 'agent-desktop'
if ($server) {
    if (-not $server.enabled) { throw '已有 agent-desktop 配置处于禁用状态。请先检查该配置。' }
    Write-Host '已复用现有 agent-desktop MCP 注册。'
} else {
    $npm = Get-Command npm.cmd -CommandType Application -ErrorAction SilentlyContinue
    if (-not $npm) { throw '首次安装 MCP 需要 Node.js 18 或更高版本及 npm。' }
    $architecture = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()
    $hashes = @{
        x64 = 'a7ef5e539fb97287a35eb9ed49d3803b4d6bd705bc4106eb28617229f9be679e'
        arm64 = 'd3c93ca08a335b1b3bb1854200e17b639f8c914fabb1f721c8df6814a5cce087'
    }
    if (-not $hashes.ContainsKey($architecture)) { throw "不支持的 Windows 架构：$architecture" }
    $prefix = Join-Path $configRoot 'tools/agent-desktop/1.3.1'
    $binary = Join-Path $prefix "node_modules/agent-desktop/bin/agent-desktop-win32-$architecture.exe"
    if (-not (Test-Path -LiteralPath $binary -PathType Leaf)) {
        & $npm.Source install --prefix $prefix --no-save --no-package-lock --ignore-scripts --no-audit --no-fund agent-desktop@1.3.1
        if ($LASTEXITCODE -ne 0) { throw 'npm 安装 agent-desktop 失败。' }
    }
    if ((Get-FileHash -LiteralPath $binary).Hash -ne $hashes[$architecture]) { throw 'agent-desktop 可执行文件校验失败。' }
    & $binary version | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'agent-desktop 无法启动。' }
    & $codex.Source mcp add agent-desktop -- $binary mcp | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'Codex MCP 注册失败。' }
}

if ($needsCopy) {
    [IO.Directory]::CreateDirectory($targetDir) | Out-Null
    $temporary = Join-Path $targetDir ([IO.Path]::GetRandomFileName())
    try {
        [IO.File]::Copy($source, $temporary)
        [IO.File]::Move($temporary, $target, ($exists -and $UpdateSkill.IsPresent))
    } finally {
        if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
    }
}
if ((Get-FileHash -LiteralPath $target).Hash -ne $sourceHash) { throw '技能文件校验失败。' }
Write-Host "技能就绪：$target"
Write-Host '新开一个 Codex 会话，请 AI 使用 agent-desktop 查询版本并列出窗口，验证客户端连接。'
