![alt text](https://github.com/dev126712/three-tier-architecture/blob/6235857785ad7c407f1f26ef24c3ce65f9fb1e3f/Untitled%20Diagram.drawio.png)

# 1 Infrastructure ci ( ci-terraform.yml )
````
name: Deploy Terraform
on: 
  push:
    paths: 
      - '**.tf'
      - '.github/workflows/ci-terraform.yml'
permissions:
  contents: read
  packages: read
  pull-requests: write

jobs:
````
### -1 Terraform check 
````
verify:
    env:
        AWS_ACCESS_KEY_ID: "${{ secrets.AWS_ACCESS_KEY_ID }}"
        AWS_SECRET_ACCESS_KEY: "${{ secrets.AWS_SECRET_ACCESS_KEY }}"
    runs-on: ubuntu-latest
    steps:
      - name: Code Checkout
        uses: actions/checkout@v3

      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform init
        run: terraform init

      - name: Terraform fmt
        run: terraform fmt
        
      - name: Terraform validate
        run: terraform validate 

      - name: Terraform fmt check
        run: terraform fmt -check -recursive  

      - name: Terraform Plan
        run: terraform plan  

````
# 2 Security scan ( security.yml )
````
name: security check

on:
  push:
    branches:
      - main
    paths: '**'

permissions:
  contents: read

````

### -1 Security check on workflows yml files
````
 secirity-scan-on-workflows:
    runs-on: ubuntu-latest
    permissions:
      contents: write 
    steps:
    - name: checkout repo
      uses: actions/checkout@v4

    - name: Run Checkov Security Scan on yml files
      uses: bridgecrewio/checkov-action@master
      with:
        directory:  .github/workflows
        output_format: cli
        soft_fail: true
        quiet: true  
````
#### -2 Security check on Terraform files
````
secirity-scan-on-terraform-files:
    runs-on: ubuntu-latest
    permissions:
      contents: write 
    steps:
    - name: checkout repo
      uses: actions/checkout@v4

    - name: Run Checkov Security Scan on yml files
      uses: bridgecrewio/checkov-action@master
      with:
        directory:  .
        output_format: cli
        soft_fail: true
        quiet: true
````

