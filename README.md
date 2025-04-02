# DevSecOps

## Overview
This repository provides a **practical DevSecOps solution** integrating **Jenkins, Terraform, AWS (EKS, ECR, S3, VPN), and Helm** for secure, automated CI/CD pipelines. This setup enables seamless hybrid cloud deployment, secure infrastructure provisioning, and automated application delivery.

## Branches
This repository contains multiple branches, each dedicated to a specific aspect of the DevSecOps workflow:

- 🔹 **[asp-deployment](https://github.com/Sanchistor/DevSecOps-practice/tree/asp-deployment)** – Manages the deployment of ASP.NET applications with enabled SAST/DAST/Dependency scanning and Image scanning security validation.
- 🔹 **[main](https://github.com/Sanchistor/DevSecOps-practice/tree/main)** – The primary branch containing description of production-ready configurations.
- 🔹 **[provision-resources](https://github.com/Sanchistor/DevSecOps-practice/tree/provion-resources)** – Handles Terraform and Amazon Lambda scripts for provisioning AWS infrastructure that can be destroyed by one button.
- 🔹 **[wagtail-deployment](https://github.com/Sanchistor/DevSecOps-practice/tree/wagtail-deployment)** – Deploys Wagtail CMS Helm with enabled SAST/DAST/Dependency scanning and Image scanning security validation.

## Features
- ✅ **Hybrid Cloud CI/CD** – On-prem Jenkins securely deploys to AWS resources.
- ✅ **Infrastructure as Code (IaC)** – Terraform provisions **EKS, ECR, VPN, and S3**.
- ✅ **Secure Container Management** – Store and manage Docker images in **Amazon ECR**.
- ✅ **Automated Deployments** – Deploy applications to **EKS using Helm charts**.
- ✅ **Least Privilege IAM Roles** – Secure access with **AWS IAM role-based policies**.
- ✅ **Terraform State Management** – Encrypted **S3 backend with DynamoDB state locking**.
- ✅ **Auto Cleanup Pipeline** – Automatically **destroy AWS resources after testing**.

## Getting Started
### **1. Clone the Repository**
```sh
git clone https://github.com/Sanchistor/DevSecOps-practice.git
cd DevSecOps-practice
```

### **2. Setup AWS Credentials**
Ensure your AWS credentials are configured for Terraform and Jenkins to access AWS services:
```sh
aws configure
```

### **3. Initialize Terraform & Deploy Resources**
```sh
terraform init
terraform apply -auto-approve
```

### **4. Configure Jenkins & Run Pipeline**
- Set up Jenkins with the necessary **plugins** (Terraform, AWS CLI, Docker, Helm, and Kubernetes).
- Add your AWS credentials to Jenkins.
- Run the Jenkins pipeline to build and deploy applications securely.

## Cleanup
To **destroy all AWS resources** after testing:
```sh
terraform destroy -auto-approve
```

🚀 Happy Coding!

