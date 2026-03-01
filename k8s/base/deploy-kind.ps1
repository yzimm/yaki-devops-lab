# Configurable variables
$clusters = @("staging-cluster", "prod-cluster")  # kind cluster names
$imageName = "my-web-app"
$imageTag = "dev"  # change per environment if needed
$deploymentFile = "deployment.yaml"
$namespace = "default"

foreach ($cluster in $clusters) {

    Write-Host "`n===== Deploying to cluster: $cluster =====" -ForegroundColor Cyan

    # 1. Load the Docker image into the cluster
    Write-Host "Loading Docker image ${imageName}:${imageTag} into $cluster..."
    kind load docker-image "${imageName}:${imageTag}" --name $cluster

    # 2. Switch kubectl context
    Write-Host "Switching kubectl context to $cluster..."
    kubectl config use-context "kind-$cluster"

    # 3. Update deployment YAML with correct image
    Write-Host "Updating deployment.yaml with ${imageName}:${imageTag}..."
    (Get-Content $deploymentFile) -replace '(image:\s*.*)', "image: ${imageName}:${imageTag}`r`n        imagePullPolicy: IfNotPresent" | 
        Set-Content $deploymentFile

    # 4. Apply the deployment
    Write-Host "Applying deployment..."
    kubectl apply -f $deploymentFile

    # 5. Delete old pods to force refresh
    Write-Host "Deleting old pods..."
    kubectl delete pod -l app=$imageName --namespace $namespace -ignore-not-found

    # 6. Wait for pods to be ready
    Write-Host "Waiting for pods to be ready..."
    kubectl wait --for=condition=Ready pod -l app=$imageName --timeout=120s --namespace $namespace

    Write-Host "Deployment completed for $cluster!" -ForegroundColor Green
}