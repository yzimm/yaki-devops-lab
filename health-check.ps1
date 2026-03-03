# ============================================================
# Yaki DevOps Lab - Pre-Demo Health Check
# ============================================================

$UBUNTU_IP      = "10.93.107.240"
$UBUNTU_USER    = "ubuntu"
$DOCKERHUB_USER = "yaki2026"
$DOCKERHUB_IMAGE = "my-web-app"

$global:pass = 0
$global:fail = 0
$global:warn = 0

function Check-Pass($msg) { Write-Host "  [PASS] $msg" -ForegroundColor Green;  $global:pass++ }
function Check-Fail($msg) { Write-Host "  [FAIL] $msg" -ForegroundColor Red;    $global:fail++ }
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

Section "1. Local Tools"
try { $d = docker version --format '{{.Server.Version}}' 2>$null; if ($d) { Check-Pass "Docker is running (v$d)" } else { Check-Fail "Docker is not running" } } catch { Check-Fail "Docker not found" }
try { $k = kubectl version --client 2>&1; if ($k -match "Client Version|clientVersion") { Check-Pass "kubectl is installed" } else { Check-Fail "kubectl not found" } } catch { Check-Fail "kubectl not found" }
try { $ki = kind version 2>$null; if ($ki) { Check-Pass "kind is installed ($ki)" } else { Check-Fail "kind not found" } } catch { Check-Fail "kind not found" }
try { $g = git --version 2>$null; if ($g) { Check-Pass "git is installed ($g)" } else { Check-Fail "git not found" } } catch { Check-Fail "git not found" }

Section "2. Kind Clusters"
try {
    $clusters = kind get clusters 2>$null
    if ($clusters -match "dev-cluster")     { Check-Pass "dev-cluster is running" }     else { Check-Fail "dev-cluster not found" }
    if ($clusters -match "staging-cluster") { Check-Pass "staging-cluster is running" } else { Check-Fail "staging-cluster not found" }
} catch { Check-Fail "Could not get kind clusters" }

Section "3. Kubernetes Pods (Kind clusters)"
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

Section "4. Docker Images (Local)"
$images = docker images --format "{{.Repository}}:{{.Tag}}" 2>$null
if ($images -match "$DOCKERHUB_USER/${DOCKERHUB_IMAGE}:dev")     { Check-Pass "Image :dev exists locally" }     else { Check-Warn "Image :dev not found locally" }
if ($images -match "$DOCKERHUB_USER/${DOCKERHUB_IMAGE}:staging") { Check-Pass "Image :staging exists locally" } else { Check-Warn "Image :staging not found locally" }

Section "5. Docker Hub Connectivity"
try {
    $loginCheck = docker login 2>&1
    if ($loginCheck -match "Login Succeeded|existing credentials") { Check-Pass "Docker Hub login OK (user: $DOCKERHUB_USER)" } else { Check-Warn "Docker Hub login may require credentials" }
} catch { Check-Warn "Could not verify Docker Hub login" }

Section "6. Git Repository"
$repoPath = "C:\terraform\my-web-app"
if (Test-Path $repoPath) {
    Push-Location $repoPath
    $remote = git remote get-url origin 2>$null
    if ($remote -match "yaki-devops-lab") { Check-Pass "GitHub remote configured: $remote" } else { Check-Fail "GitHub remote not configured correctly" }
    $branch = git branch --show-current 2>$null
    Check-Pass "Current branch: $branch"
    $gitstatus = git status --short 2>$null
    if ($gitstatus) { Check-Warn "Uncommitted changes found" } else { Check-Pass "Working directory is clean" }
    $branches = git branch -a 2>$null
    if ($branches -match "main")    { Check-Pass "Branch main exists" }    else { Check-Fail "Branch main missing" }
    if ($branches -match "dev")     { Check-Pass "Branch dev exists" }     else { Check-Fail "Branch dev missing" }
    if ($branches -match "staging") { Check-Pass "Branch staging exists" } else { Check-Fail "Branch staging missing" }
    Pop-Location
} else { Check-Fail "Repo path not found: $repoPath" }

Section "7. Ubuntu VM Connectivity ($UBUNTU_IP)"
if (Test-Connection -ComputerName $UBUNTU_IP -Count 2 -Quiet -ErrorAction SilentlyContinue) { Check-Pass "Ubuntu VM is reachable (ping)" } else { Check-Warn "Ubuntu VM ping failed" }
$sshTest = & ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${UBUNTU_USER}@${UBUNTU_IP}" "echo SSH_OK" 2>$null
if ($sshTest -match "SSH_OK") { Check-Pass "SSH connection successful" } else { Check-Fail "SSH connection failed (check keys / passwordless access)" }

Section "8. Argo CD and Monitoring (Ubuntu VM)"

# ArgoCD - single app named my-web-app
$result = & ssh -o BatchMode=yes -o StrictHostKeyChecking=no "${UBUNTU_USER}@${UBUNTU_IP}" "sudo kubectl get application my-web-app -n argocd -o jsonpath='{.status.sync.status},{.status.health.status}' 2>/dev/null" 2>$null
if ($result -match "Synced,Healthy") {
    Check-Pass "Argo CD: my-web-app - Synced and Healthy"
} elseif ($result) {
    Check-Fail "Argo CD: my-web-app - $result"
} else {
    Check-Warn "Argo CD: my-web-app - could not retrieve status"
}

# Monitoring pods
$monOutput = & ssh -o BatchMode=yes -o StrictHostKeyChecking=no "${UBUNTU_USER}@${UBUNTU_IP}" "sudo kubectl get pods -n monitoring --no-headers 2>/dev/null" 2>$null
if ($monOutput) {
    foreach ($line in ($monOutput -split "`n")) {
        $line = $line.Trim()
        if ($line -eq "") { continue }
        $parts = $line -split "\s+"
        $pname = $parts[0]; $pstatus = $parts[2]
        if ($pstatus -eq "Running") { Check-Pass "Monitoring: $pname is Running" } else { Check-Fail "Monitoring: $pname is $pstatus" }
    }
} else { Check-Warn "No monitoring pods found or SSH output empty" }

# Prod pod
$prodOutput = & ssh -o BatchMode=yes -o StrictHostKeyChecking=no "${UBUNTU_USER}@${UBUNTU_IP}" "sudo kubectl get pods -n default --no-headers 2>/dev/null" 2>$null
$prodFound = $false
foreach ($line in ($prodOutput -split "`n")) {
    if ($line -match "my-web-app-prod") {
        $pstatus = ($line.Trim() -split "\s+")[2]
        if ($pstatus -eq "Running") { Check-Pass "Prod pod is Running on Ubuntu VM" } else { Check-Fail "Prod pod is $pstatus" }
        $prodFound = $true
    }
}
if (-not $prodFound) { Check-Fail "Prod pod NOT found on Ubuntu VM" }

Section "9. Grafana Dashboard"
try {
    $grafana = Invoke-WebRequest -Uri "http://${UBUNTU_IP}:3000/api/health" -TimeoutSec 5 -UseBasicParsing 2>$null
    if ($grafana.StatusCode -eq 200) { Check-Pass "Grafana is accessible at port 3000" } else { Check-Fail "Grafana returned status $($grafana.StatusCode)" }
} catch { Check-Warn "Grafana not accessible - check port-forward on Ubuntu VM" }

Section "10. Required Project Files"
$requiredFiles = @(
    "app\Dockerfile",
    "app\index.html",
    "build-and-deploy.ps1",
    ".github\workflows\ci.yml",
    "k8s\base\deployment.yaml",
    "k8s\base\service.yaml",
    "k8s\overlays\dev\kustomization.yaml",
    "k8s\overlays\staging\kustomization.yaml",
    "k8s\overlays\prod\kustomization.yaml"
)
foreach ($file in $requiredFiles) {
    $fullPath = Join-Path $repoPath $file
    if (Test-Path $fullPath) { Check-Pass "Found: $file" } else { Check-Fail "Missing: $file" }
}

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "  SUMMARY" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "  PASSED : $global:pass" -ForegroundColor Green
Write-Host "  WARNED : $global:warn" -ForegroundColor Yellow
Write-Host "  FAILED : $global:fail" -ForegroundColor Red
Write-Host ""
if ($global:fail -eq 0 -and $global:warn -eq 0) { Write-Host "  ALL CHECKS PASSED - You are ready to demo!" -ForegroundColor Green }
elseif ($global:fail -eq 0)                      { Write-Host "  WARNINGS FOUND - Demo can proceed but review warnings" -ForegroundColor Yellow }
else                                              { Write-Host "  FAILURES FOUND - Fix issues before demoing" -ForegroundColor Red }
Write-Host ""
Write-Host "  Completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""
