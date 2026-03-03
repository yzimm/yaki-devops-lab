# ============================================================
# QuickFix.ps1 - Standalone Repair & Health Check
# ============================================================

$UBUNTU_IP = "10.93.107.240"
$UBUNTU_USER = "ubuntu"

# --- Helper Functions ---
function Section($title) {
    Write-Host "`n=======================================" -ForegroundColor Cyan
    Write-Host "  $title" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Cyan
}
function Check-Pass($msg) { Write-Host "  [PASS] $msg" -ForegroundColor Green }
function Check-Fail($msg) { Write-Host "  [FAIL] $msg" -ForegroundColor Red }

# --- Execution ---
Section "8. Argo CD and Monitoring (Ubuntu VM)"

try {
    # Testing SSH and checking ArgoCD Pods
    $argoPods = ssh -o ConnectTimeout=5 "${UBUNTU_USER}@${UBUNTU_IP}" "kubectl get pods -n argocd 2>`$null"
    
    if ($argoPods -match "argocd-server.*Running") { 
        Check-Pass "ArgoCD Server is running on Ubuntu VM" 
    } else { 
        Check-Fail "ArgoCD Server NOT found. You must install it on the VM." 
    }

    # Checking for the Prod App Pod
    $prodPods = ssh "${UBUNTU_USER}@${UBUNTU_IP}" "kubectl get pods -n prod 2>`$null"
    if ($prodPods -match "my-web-app.*Running") { 
        Check-Pass "Prod pod found on Ubuntu VM" 
    } else { 
        Check-Fail "Prod pod NOT found. ArgoCD hasn't synced the 'prod' overlay yet." 
    }
} catch {
    Check-Fail "Could not connect to Ubuntu VM at $UBUNTU_IP. Check your SSH keys/connection."
}

Section "9. Grafana Check"
try {
    $grafana = ssh "${UBUNTU_USER}@${UBUNTU_IP}" "kubectl get pods -A | grep grafana"
    if ($grafana -match "Running") {
        Check-Pass "Grafana pod is active on VM"
    } else {
        Check-Fail "Grafana not found."
    }
} catch {
    Check-Fail "Grafana check failed."
}