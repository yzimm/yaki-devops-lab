$environments = @("dev", "staging", "prod")

foreach ($env in $environments) {

    $path = "terraform/$env"

    # Create environment folder
    New-Item -ItemType Directory -Force -Path $path

    # Create required files
    New-Item -ItemType File -Force -Path "$path/main.tf"
    New-Item -ItemType File -Force -Path "$path/variables.tf"
    New-Item -ItemType File -Force -Path "$path/terraform.tfvars"

    Write-Host "Created structure for $env"
}