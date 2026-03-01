param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev","staging","prod","all")]
    [string]$env
)

$ROOT = "C:\terraform\my-web-app"
$APP  = "$ROOT\app"
$DOCKER_USER = "yaki2026"

function Deploy {
    param([string]$environment)
    
    $tag = if ($environment -eq "prod") { "latest" } else { $environment }
    
    Write-Host "`n=== Deploying $environment ===" -ForegroundColor Cyan

    # 1. Build
    Write-Host "1. Building image $DOCKER_USER/my-web-app:$tag..." -ForegroundColor Yellow
    docker build -t "$DOCKER_USER/my-web-app:$tag" $APP
    if ($LASTEXITCODE -ne 0) { Write-Host "Build failed!" -ForegroundColor Red; exit 1 }

    # 2. Push to Docker Hub
    Write-Host "2. Pushing to Docker Hub..." -ForegroundColor Yellow
    docker push "$DOCKER_USER/my-web-app:$tag"
    if ($LASTEXITCODE -ne 0) { Write-Host "Push failed!" -ForegroundColor Red; exit 1 }

    # 3. Load into kind cluster (skip for prod - handled by Argo CD)
    if ($environment -ne "prod") {
        Write-Host "3. Loading into $environment-cluster..." -ForegroundColor Yellow
        kind load docker-image "$DOCKER_USER/my-web-app:$tag" --name "$environment-cluster"
        if ($LASTEXITCODE -ne 0) { Write-Host "Kind load failed!" -ForegroundColor Red; exit 1 }

        # 4. Apply kustomize
        Write-Host "4. Applying kustomize overlay..." -ForegroundColor Yellow
        kubectl apply -k "$ROOT\k8s\overlays\$environment"
        if ($LASTEXITCODE -ne 0) { Write-Host "Apply failed!" -ForegroundColor Red; exit 1 }

        # 5. Restart deployment
        Write-Host "5. Restarting deployment..." -ForegroundColor Yellow
        kubectl rollout restart deployment/my-web-app-$environment
        if ($LASTEXITCODE -ne 0) { Write-Host "Restart failed!" -ForegroundColor Red; exit 1 }

        # 6. Wait for rollout
        Write-Host "6. Waiting for rollout..." -ForegroundColor Yellow
        kubectl rollout status deployment/my-web-app-$environment
    } else {
        Write-Host "3. Prod is managed by Argo CD - image pushed to Docker Hub" -ForegroundColor Magenta
        Write-Host "   Argo CD will automatically deploy when it detects the new image" -ForegroundColor Magenta
    }

    Write-Host "=== $environment deployed successfully! ===" -ForegroundColor Green
}

if ($env -eq "all") {
    Deploy "dev"
    Deploy "staging"
    Deploy "prod"
} else {
    Deploy $env
}

Write-Host "`n=== Final Pod Status ===" -ForegroundColor Cyan
kubectl get pods