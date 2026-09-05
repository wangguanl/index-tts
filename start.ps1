#Requires -Version 5.0
<#
.SYNOPSIS
    启动 IndexTTS WebUI。
.DESCRIPTION
    本机默认：IndexTTS-2 + FP16。
    默认从 7860 启动；若已被占用则自动顺延到下一个空闲端口。
    用法见 docs/本地运行.md
.EXAMPLE
    .\start.ps1
.EXAMPLE
    .\start.ps1 -Version 2.5
.EXAMPLE
    .\start.ps1 -Port 7870 -NoFp16
#>
param(
    [ValidateSet("2", "2.5")]
    [string]$Version = "2",

    [int]$Port = 7860,

    [string]$ModelDir = "",

    [switch]$NoFp16
)

$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

if (-not $ModelDir) {
    if ($Version -eq "2.5") {
        $ModelDir = "./checkpoints_2.5"
    }
    else {
        $ModelDir = "./checkpoints"
    }
}

if (-not $env:HF_ENDPOINT) {
    $env:HF_ENDPOINT = "https://hf-mirror.com"
}

if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Error "未找到 uv。请先安装：https://docs.astral.sh/uv/getting-started/installation/"
}

if (-not (Test-Path -LiteralPath ".venv")) {
    Write-Host "未检测到 .venv，请先手动安装依赖后再启动："
    Write-Host '  uv sync --extra webui --default-index "https://mirrors.aliyun.com/pypi/simple"'
    exit 1
}

$required = @{
    "2"   = @("config.yaml", "bpe.model", "gpt.pth", "s2mel.pth", "wav2vec2bert_stats.pt")
    "2.5" = @("config.yaml", "gpt.pth", "s2mel.pth", "codec.pth", "multilingual_zh_ja_yue_char_del.tiktoken", "wav2vec2bert_stats.pt")
}

$missing = @()
foreach ($name in $required[$Version]) {
    $path = Join-Path $ModelDir $name
    if (-not (Test-Path -LiteralPath $path)) {
        $missing += $name
    }
}

if ($missing.Count -gt 0) {
    Write-Host "模型目录 $ModelDir 缺少 IndexTTS-$Version 所需文件："
    $missing | ForEach-Object { Write-Host "  - $_" }
    Write-Host ""
    if ($Version -eq "2.5") {
        Write-Host "下载到独立目录，避免覆盖现有 IndexTTS-2 权重："
        Write-Host "  hf download IndexTeam/IndexTTS-2.5 --local-dir=checkpoints_2.5"
        Write-Host "  或 modelscope download --model IndexTeam/IndexTTS-2.5 --local_dir checkpoints_2.5"
    }
    else {
        Write-Host "  hf download IndexTeam/IndexTTS-2 --local-dir=checkpoints"
        Write-Host "  或 modelscope download --model IndexTeam/IndexTTS-2 --local_dir checkpoints"
    }
    exit 1
}

function Test-PortListening([int]$Candidate) {
    $listeners = Get-NetTCPConnection -LocalPort $Candidate -State Listen -ErrorAction SilentlyContinue
    return [bool]$listeners
}

function Find-FreePort([int]$Preferred) {
    for ($candidate = $Preferred; $candidate -lt ($Preferred + 20); $candidate++) {
        if (-not (Test-PortListening $candidate)) {
            return $candidate
        }
        Write-Host "端口 $candidate 已被占用，尝试下一个..."
    }
    Write-Error "从 $Preferred 起连续 20 个端口都被占用，请用 -Port 指定空闲端口。"
}

$Port = Find-FreePort $Port

$uvArgs = @(
    "run", "webui.py",
    "--version", $Version,
    "--model_dir", $ModelDir,
    "--port", "$Port"
)
if (-not $NoFp16) {
    $uvArgs += "--fp16"
}

Write-Host "IndexTTS-$Version 启动中..."
Write-Host "模型目录: $ModelDir"
if (-not $NoFp16) {
    Write-Host "精度: FP16/BF16"
}
else {
    Write-Host "精度: FP32"
}
Write-Host "访问地址: http://127.0.0.1:$Port"
Write-Host ""

& uv @uvArgs
exit $LASTEXITCODE
