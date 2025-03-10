# DevSecOps

## Overview
This repository provides a **practical DevSecOps solution** integrating **Jenkins, Terraform, AWS (EKS, ECR, S3, VPN), and Helm** for secure, automated CI/CD pipelines. This setup enables seamless hybrid cloud deployment, secure infrastructure provisioning, and automated application delivery.

## Features
- ✅ **Hybrid Cloud CI/CD** – On-prem Jenkins securely deploys to AWS resources.
- ✅ **Infrastructure as Code (IaC)** – Terraform provisions **EKS, ECR, VPN, and S3**.
- ✅ **Secure Container Management** – Store and manage Docker images in **Amazon ECR**.
- ✅ **Automated Deployments** – Deploy applications to **EKS using Helm charts**.
- ✅ **Least Privilege IAM Roles** – Secure access with **AWS IAM role-based policies**.
- ✅ **Terraform State Management** – Encrypted **S3 backend with DynamoDB state locking**.
- ✅ **Auto Cleanup Pipeline** – Automatically **destroy AWS resources after testing**.

## Repository Structure

The repository contains Terraform configurations and resources for setting up various AWS services in an automated and secure manner. Here's a breakdown of the key files:

- **`backend.tf`**: Configures the S3 backend and DynamoDB for state management and locking.
- **`ecr.tf`**: Defines the configuration for Amazon ECR (Elastic Container Registry) to store Docker images.
- **`eks.tf`**: Defines the configuration for the EKS cluster, including VPC, subnets, and node groups.
- **`iam-roles.tf`**: Defines IAM roles and policies for secure access management.
- **`load-balancer.tf`**: Configures the load balancer (ALB) for application access.
- **`provider.tf`**: Contains AWS provider configurations and credentials.
- **`rds.tf`**: Configures the RDS (Relational Database Service) instance for storing application data.
- **`security-group-eks.tf`**: Configures security groups for EKS control plane and worker nodes.
- **`security-group-rds.tf`**: Configures security groups for RDS instances.
- **`variables.tf`**: Defines the input variables for the configuration.

## EKS Terraform Module Configuration

This Terraform configuration sets up an **Amazon EKS (Elastic Kubernetes Service)** cluster using the **`terraform-aws-modules/eks/aws`** module. Below is a breakdown of the key components:

### **Cluster Configuration**:
- **Cluster Name**: The EKS cluster is named based on the `var.cluster_name` variable.
- **Cluster Version**: The cluster is provisioned with Kubernetes version `1.31`.
- **VPC and Subnets**: The EKS cluster is launched in the VPC specified by `data.aws_vpc.default.id` and the subnets defined by `data.aws_subnets.default.ids`.
- **Public Access**: The `cluster_endpoint_public_access` is set to `true`, enabling public access to the EKS cluster endpoint.
- **IAM Admin Permissions**: The `enable_cluster_creator_admin_permissions` is set to `true`, allowing the cluster creator to have admin access to the cluster.

### **Security Groups**:
- The **EKS control plane** is protected by a security group referenced as `aws_security_group.eks_control_plane_sg`.
- **Worker nodes** are assigned a separate security group `aws_security_group.eks_worker_node_sg` for better isolation and security.

### **Managed Node Group**:
- **Instance Types**: The node group uses `t3.small` instances by default, with a minimum size of `1`, a maximum size of `3`, and a desired size of `2`.
- **Security Groups**: The worker nodes are associated with the worker node security group (`aws_security_group.eks_worker_node_sg`).
- **IAM Role**: The worker nodes are attached to an IAM role (`aws_iam_role.worker_node_role`) that grants the necessary permissions for accessing other AWS resources like ECR, S3, etc.

### **Access Control**:
- The **`aws_eks_access_entry`** resource grants access to the EKS cluster for the IAM user specified by `var.admin_user`. This enables the specified user (e.g., admin) to manage and interact with the cluster.

### **Subnets**:
- The `data "aws_subnets"` block ensures that the appropriate subnets are used for the EKS cluster by filtering them based on the VPC ID.

This configuration provides a scalable, secure, and manageable EKS cluster with best practices for IAM roles and access control. You can modify the `var.cluster_name`, instance types, and other parameters to customize the deployment to your needs.
