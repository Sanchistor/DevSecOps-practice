# DevSecOps

## Overview
This repository provides a **practical DevSecOps solution** integrating **Jenkins, Terraform, AWS (EKS, ECR, S3, VPN, RDS), and Helm** for secure, automated CI/CD pipelines. This setup enables seamless hybrid cloud deployment, secure infrastructure provisioning, and automated application delivery.

## Hosting Wagtail on Kubernetes
This project includes the deployment of a **Wagtail** application to an **AWS EKS cluster** using **Helm**. The application will connect to **Amazon RDS** for database management. 

### **Deployment Overview**:
- **Kubernetes Cluster**: Hosted on **AWS EKS**.
- **Database**: Uses **Amazon RDS** for data persistence.
- **Helm**: Manages application deployment on **EKS**.
- **CI/CD**: Utilizes **Jenkins** for building and deploying the Wagtail application.
