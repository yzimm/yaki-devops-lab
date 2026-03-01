# Root path
$root = "C:\terraform\my-web-app\k8s"

Write-Host "Building clean Kubernetes structure..."

# Remove old structure if exists
Remove-Item "$root\dev" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$root\staging" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$root\prod" -Recurse -Force -ErrorAction SilentlyContinue

# Create new structure
New-Item -ItemType Directory -Force -Path "$root\base"
New-Item -ItemType Directory -Force -Path "$root\overlays\dev"
New-Item -ItemType Directory -Force -Path "$root\overlays\staging"
New-Item -ItemType Directory -Force -Path "$root\overlays\prod"

# Create base deployment.yaml
@"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-web-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-web-app
  template:
    metadata:
      labels:
        app: my-web-app
    spec:
      containers:
      - name: my-web-app
        image: my-web-app:latest
        ports:
        - containerPort: 80
"@ | Set-Content "$root\base\deployment.yaml"

# Create base service.yaml
@"
apiVersion: v1
kind: Service
metadata:
  name: my-web-app
spec:
  selector:
    app: my-web-app
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
"@ | Set-Content "$root\base\service.yaml"

# Function to create overlay
function Create-Overlay($env) {
@"
resources:
  - ../../base

nameSuffix: -$env

commonLabels:
  env: $env
"@ | Set-Content "$root\overlays\$env\kustomization.yaml"
}

Create-Overlay "dev"
Create-Overlay "staging"
Create-Overlay "prod"

Write-Host "Kubernetes structure created successfully!"