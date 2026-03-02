# ============================================================
# Yaki DevOps Lab - Pre-Demo Health Check (Improved)
# ============================================================

$UBUNTU_IP = "10.93.107.240"
$UBUNTU_USER = "ubuntu"
$DOCKERHUB_USER = "yaki2026"
$DOCKERHUB_IMAGE = "my-web-app"

$global:pass = 0
$global:fail = 0
$global:warn = 0

function Check-Pass($msg) { Write-Host "  [PASS] $msg" -ForegroundColor Green; $global:pass++ }
function Check-Fail($msg) { Write-Host "  [FAIL] $msg" -ForegroundColor Red; $global:fail++ }
function Check-Warn($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow; $global:warn++ }
function Section($title) {
    Write-Host ""
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host "  $title" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Cyan
}

Clear-Host
Write-Host ""
Write-Host "  ============================================" -ForegroundColor Blue
Write-Host "   Yaki DevOps Lab - Pre-Demo Health Check   " -ForegroundColor White
Write-Host "  ============================================" -ForegroundColor Blue
Write-Host "  Running at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

# ============================================================
# 1. Local Tools
# ============================================================
Section "1. Local Tools"

try { $d = docker version --format '{{.Server.Version}}' 2>$null; if ($d) { Check-Pass "Docker is running (v$d)" } else { Check-Fail "Docker is not running" } } catch { Check-Fail "Docker not found" }
try { $k = kubectl version --client 2>$null; if ($k) { Check-Pass "kubectl is installed" } else { Check-Fail "kubectl not found" } } catch { Check-Fail "kubectl not found" }
try { $ki = kind version 2>$null; if ($ki) { Check-Pass "kind is installed ($ki)" } else { Check-Fail "kind not found" } } catch { Check-Fail "kind not found" }
try { $g = git --version 2>$null; if ($g) { Check-Pass "git is installed ($g)" } else { Check-Fail "git not found" } } catch { Check-Fail "git not found" }

# ============================================================
# 2. Kind Clusters
# ============================================================
Section "2. Kind Clusters"
try {
    $clusters = kind get clusters 2>$null
    if ($clusters -match "dev-cluster") { Check-Pass "dev-cluster is running" } else { Check-Fail "dev-cluster not found" }
    if ($clusters -match "staging-cluster") { Check-Pass "staging-cluster is running" } else { Check-Fail "staging-cluster not found" }
} catch { Check-Fail "Could not get kind clusters" }

# ============================================================
# 3. Kubernetes Pods
# ============================================================
Section "3. Kubernetes Pods"
try {
    kubectl config use-context kind-dev-cluster 2>$null | Out-Null
    $pods = kubectl get pods 2>$null
    if ($pods -match "my-web-app-dev.*Running") { Check-Pass "my-web-app-dev pod is Running" } else { Check-Fail "my-web-app-dev pod is NOT running" }
} catch { Check-Fail "Could not check dev-cluster pods" }

try {
    kubectl config use-context kind-staging-cluster 2>$null | Out-Null
    $pods2 = kubectl get pods 2>$null
    if ($pods2 -match "my-web-app-staging.*Running") { Check-Pass "my-web-app-staging pod is Running" } else { Check-Fail "my-web-app-staging pod is NOT running" }
} catch { Check-Fail "Could not check staging-cluster pods" }

kubectl config use-context kind-dev-cluster 2>$null | Out-Null

# ============================================================
# 4. Docker Images (Local)
# ============================================================
Section "4. Docker Images (Local)"
$images = docker images --format "{{.Repository}}:{{.Tag}}" 2>$null
if ($images -match "$DOCKERHUB_USER/${DOCKERHUB_IMAGE}:dev") { Check-Pass "Image :dev exists locally" } else { Check-Warn "Image :dev not found locally" }
if ($images -match "$DOCKERHUB_USER/${DOCKERHUB_IMAGE}:staging") { Check-Pass "Image :staging exists locally" } else { Check-Warn "Image :staging not found locally" }

# ============================================================
# 5. Docker Hub Connectivity
# ============================================================
Section "5. Docker Hub Connectivity"
try {
    $loginCheck = docker login 2>&1
    if ($loginCheck -match "Login Succeeded" -or $loginCheck -match "existing credentials") { Check-Pass "Docker Hub login OK (user: $DOCKERHUB_USER)" } else { Check-Warn "Docker Hub login may require credentials" }
} catch { Check-Warn "Could not verify Docker Hub login" }

# ============================================================
# 6. Git Repository
# ============================================================
Section "6. Git Repository"
$repoPath = "C:\terraform\my-web-app"
if (Test-Path $repoPath) {
    Set-Location $repoPath
    $remote = git remote get-url origin 2>$null
    if ($remote -match "yaki-devops-lab") { Check-Pass "GitHub remote configured: $remote" } else { Check-Fail "GitHub remote not configured correctly" }
    $branch = git branch --show-current 2>$null
    Check-Pass "Current branch: $branch"
    $status = git status --short 2>$null
    if ($status) { Check-Warn "Uncommitted changes found" } else { Check-Pass "Working directory is clean" }
    $branches = git branch -a 2>$null
    if ($branches -match "main") { Check-Pass "Branch main exists" } else { Check-Fail "Branch main missing" }
    if ($branches -match "dev") { Check-Pass "Branch dev exists" } else { Check-Fail "Branch dev missing" }
    if ($branches -match "staging") { Check-Pass "Branch staging exists" } else { Check-Fail "Branch staging missing" }
} else { Check-Fail "Project folder not found at $repoPath" }

# ============================================================
# 7. Ubuntu VM Connectivity
# ============================================================
Section "7. Ubuntu VM Connectivity ($UBUNTU_IP)"
if (Test-Connection -ComputerName $UBUNTU_IP -Count 1 -Quiet 2>$null) { Check-Pass "Ubuntu VM is reachable" } else { Check-Fail "Ubuntu VM is NOT reachable" }
try { $sshTest = ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no "${UBUNTU_USER}@${UBUNTU_IP}" "echo OK" 2>$null; if ($sshTest -match "OK") { Check-Pass "SSH connection successful" } else { Check-Warn "SSH may require password" } } catch { Check-Warn "SSH check failed" }

# ============================================================
# 8. Argo CD and Monitoring (Ubuntu VM)
# ============================================================
Section "8. Argo CD and Monitoring (Ubuntu VM)"
try {
    # Get Argo CD applications as JSON
    $argoJson = ssh $UBUNTU_USER@$UBUNTU_IP "kubectl get applications -n argocd -o json" 2>$null
    $apps = $argoJson | ConvertFrom-Json
    foreach ($app in $apps.items) {
        $name = $app.metadata.name
        $sync = $app.status.sync.status
        $health = $app.status.health.status
        if ($sync -eq "Synced" -and $health -eq "Healthy") { Check-Pass "Argo CD: $name - Synced and Healthy" } else { Check-Fail "Argo CD: $name - NOT Synced or Healthy" }
    }

    # Monitoring pods JSON
    $monJson = ssh $UBUNTU_USER@$UBUNTU_IP "kubectl get pods -n monitoring -o json" 2>$null
    $monPods = $monJson | ConvertFrom-Json
    foreach ($pod in $monPods.items) {
        $pname = $pod.metadata.name
        $status = $pod.status.phase
        if ($status -eq "Running") { Check-Pass "$pname is Running" } else { Check-Fail "$pname is NOT running" }
    }

    # Prod pod check
    $prodJson = ssh $UBUNTU_USER@$UBUNTU_IP "kubectl get pods -n default -o json" 2>$null
    $prodPods = $prodJson | ConvertFrom-Json
    foreach ($pod in $prodPods.items) {
        if ($pod.metadata.name -match "my-web-app-prod" -and $pod.status.phase -eq "Running") { Check-Pass "Prod pod is Running on Ubuntu VM" }
    }

} catch { Check-Warn "Could not run remote checks - SSH manually to verify" }

# ============================================================
# 9. Grafana Dashboard
# ============================================================
Section "9. Grafana Dashboard"
try {
    $grafana = Invoke-WebRequest -Uri "http://${UBUNTU_IP}:3000/api/health" -TimeoutSec 5 -UseBasicParsing 2>$null
    if ($grafana.StatusCode -eq 200) { Check-Pass "Grafana is accessible" } else { Check-Fail "Grafana returned status $($grafana.StatusCode)" }
} catch { Check-Warn "Grafana is not accessible - check port-forward" }

# ============================================================
# 10. Required Project Files
# ============================================================
Section "10. Required Project Files"
$files = @(
    "C:\terraform\my-web-app\app\Dockerfile",
    "C:\terraform\my-web-app\app\index.html",
    "C:\terraform\my-web-app\build-and-deploy.ps1",
    "C:\terraform\my-web-app\.github\workflows\ci.yml",
    "C:\terraform\my-web-app\k8s\base\deployment.yaml",
    "C:\terraform\my-web-app\k8s\base\service.yaml",
    "C:\terraform\my-web-app\k8s\overlays\dev\kustomization.yaml",
    "C:\terraform\my-web-app\k8s\overlays\staging\kustomization.yaml",
    "C:\terraform\my-web-app\k8s\overlays\prod\kustomization.yaml"
)
foreach ($file in $files) { if (Test-Path $file) { Check-Pass "Found: $($file.Replace('C:\terraform\my-web-app\',''))" } else { Check-Fail "Missing: $file" } }

# ============================================================
# SUMMARY
# ============================================================
Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "  SUMMARY" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "  PASSED : $global:pass" -ForegroundColor Green
Write-Host "  WARNED : $global:warn" -ForegroundColor Yellow
Write-Host "  FAILED : $global:fail" -ForegroundColor Red
Write-Host ""

if ($global:fail -eq 0 -and $global:warn -eq 0) { Write-Host "  ALL CHECKS PASSED - You are ready to demo!" -ForegroundColor Green }
elseif ($global:fail -eq 0) { Write-Host "  WARNINGS FOUND - Demo can proceed but review warnings above" -ForegroundColor Yellow }
else { Write-Host "  FAILURES FOUND - Fix issues before demoing" -ForegroundColor Red }

Write-Host ""
Write-Host "  Completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""