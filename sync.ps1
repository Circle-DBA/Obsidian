# Obsidian vault 一键同步脚本
# 推荐用法：双击同目录下的「一键同步.cmd」
# 或在本目录手动运行： powershell -ExecutionPolicy Bypass -File sync.ps1

$repo = $PSScriptRoot
Set-Location $repo

# 仅在交互式（未重定向输入）时暂停，避免脚本被管道调用时卡住
function Pause-IfInteractive {
    if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
        Read-Host "按回车键退出"
    }
}

Write-Host "================================" -ForegroundColor Yellow
Write-Host "      Obsidian 一键同步" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Yellow
Write-Host "仓库: $repo"
Write-Host ""

# 1. 确认当前目录是 git 仓库
if (-not (Test-Path (Join-Path $repo '.git'))) {
    Write-Host "[错误] 当前目录不是 git 仓库: $repo" -ForegroundColor Red
    Pause-IfInteractive
    exit 1
}

# 2. 检查远程可达性与认证
Write-Host "==> 检查远程连接..." -ForegroundColor Cyan
git ls-remote origin 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[错误] 无法连接远程仓库 origin（网络或 SSH 认证问题）" -ForegroundColor Red
    Write-Host "       请检查网络，或运行: ssh -T git@github.com"
    Pause-IfInteractive
    exit 1
}
Write-Host "    远程连接正常" -ForegroundColor Green

# 3. 先提交本地变更（保证工作区干净，避免 pull 时被覆盖）
$changes = git status --porcelain
if ($changes) {
    Write-Host "==> 发现本地变更，正在提交..." -ForegroundColor Cyan
    git add -A
    $msg = "sync: " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    git commit -m $msg
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[错误] 提交失败" -ForegroundColor Red
        Pause-IfInteractive
        exit 1
    }
    Write-Host "    已提交: $msg" -ForegroundColor Green
} else {
    Write-Host "==> 无本地变更，跳过提交" -ForegroundColor DarkGray
}

# 4. 拉取远程更新（合并，不 rebase，不强制）
Write-Host "==> 拉取远程更新..." -ForegroundColor Cyan
git pull --no-rebase origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[错误] 拉取失败，可能存在合并冲突。" -ForegroundColor Red
    Write-Host "       请解决冲突后重新运行本脚本。当前状态:" -ForegroundColor Red
    git status
    Pause-IfInteractive
    exit 1
}

# 5. 推送到 GitHub
Write-Host "==> 推送到 GitHub..." -ForegroundColor Cyan
git push origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host "[错误] 推送失败。可能远程有新提交，请重新运行本脚本先拉取再推送。" -ForegroundColor Red
    Pause-IfInteractive
    exit 1
}

Write-Host ""
Write-Host "================================" -ForegroundColor Green
Write-Host "        同步完成" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Pause-IfInteractive
exit 0
