# 🚀 TerraStream: Auto-Scaling Video Infrastructure

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Bash](https://img.shields.io/badge/GNU%20Bash-4EAA25?style=for-the-badge&logo=GNU-Bash&logoColor=white)
![Apache](https://img.shields.io/badge/Apache-D22128?style=for-the-badge&logo=Apache&logoColor=white)

## 📖 Overview

**TerraStream** is a highly available, Infrastructure-as-Code (IaC) project built with Terraform. 

Inspired by the massive traffic surges experienced by streaming platforms like JioCinema during live sports events (like the IPL), this project serves as a proof-of-concept for handling unpredictable web traffic. It automatically scales compute resources based on CPU load to ensure seamless video delivery without manual intervention.

### ✨ Key Features
* **Bring Your Own Video (BYOV):** Designed for seamless redeployment. Simply replace the `video.mp4` file in the root directory with your own media, run the deployment script, and your custom video is live.
* **Elastic Scalability:** Utilizes AWS Auto Scaling Groups (ASG) mapped to CPU-utilization policies to dynamically add or remove EC2 instances as traffic fluctuates.
* **High Availability:** Traffic is distributed across two Availability Zones via an Application Load Balancer (ALB).
* **Automated Bootstrapping:** EC2 instances automatically configure Apache, install the AWS CLI, and securely fetch the latest media from S3 upon launch.

---

## 🏗️ Architecture

The infrastructure is provisioned entirely on AWS and follows best practices for a public-facing web application:

1. **Network Layer:** A custom Virtual Private Cloud (VPC) spanning two public subnets in `ap-south-1` for redundancy, routed through an Internet Gateway.
2. **Storage Layer:** An Amazon S3 bucket securely hosts the `terrastream.html` frontend and `video.mp4` asset. 
3. **Compute & Scaling Layer:** * An **Application Load Balancer (ALB)** serves as the single point of entry, routing HTTP traffic to healthy instances.
   * An **Auto Scaling Group (ASG)** monitors instance health and CPU loads, triggering scale-out or scale-in events.
   * **EC2 Launch Templates** ensure every new instance uses a standardized `userdata.sh` script to pull the static assets directly from S3 using read-only IAM Instance Profiles.

---

## 🛠️ Prerequisites

Before deploying, ensure your local workstation is configured with the following:
- **Terraform** installed and added to your system path.
- **AWS CLI** installed and configured (`aws configure`) with credentials capable of provisioning VPC, EC2, IAM, S3, and ALB resources.
- A bash-compatible terminal (Git Bash, WSL, or native Linux/macOS terminal) to execute the run script.

---

## 🚀 Quick Start & Deployment

1. **Clone the repository and navigate to the directory:**
   ```bash
   git clone https://github.com/Rohan0323/TerraStream
   cd TerraStream
   ```

2. **(Optional) Add your custom video:**
   Replace the default `video.mp4` file in the repository with any video you want to stream. Ensure the filename remains `video.mp4`.

3. **Deploy the infrastructure:**
   Execute the wrapper script to initialize, validate, plan, and apply the Terraform configuration in one step.
   ```bash
   bash run.sh
   ```

4. **Access the Stream:**
   Upon successful deployment, Terraform will output an Application Load Balancer DNS name (e.g., `streaming_url = "http://terrastream-alb-xxxx.ap-south-1.elb.amazonaws.com"`). 
   
   Open this URL in your browser, appending `/terrastream.html`:
   ```text
   http://<YOUR_ALB_DNS_NAME>/terrastream.html
   ```

---

## 📂 Repository Structure

| File | Description |
| :--- | :--- |
| `main.tf` | Core infrastructure definitions (VPC, ASG, ALB, IAM, Security Groups). |
| `provider.tf` | AWS provider and region configurations. |
| `var.tf` | Parameterized variables for CIDR blocks, regions, and AZs. |
| `userdata.sh` | Bash script injected into EC2 instances for server setup and S3 asset retrieval. |
| `run.sh` | Deployment wrapper script for streamlined Terraform execution. |
| `terrastream.html` | The frontend UI served to the end user. |
| `video.mp4` | The static media asset fetched and streamed by the web server. |

---

## ⚙️ Configuration Variables

Network layouts and regions can be easily customized by overriding the defaults in `var.tf` or passing a `terraform.tfvars` file:

- **Region:** `ap-south-1` (Default)
- **VPC CIDR:** `10.10.0.0/16`
- **Subnet 1 (AZ-A):** `10.10.1.0/24`
- **Subnet 2 (AZ-B):** `10.10.2.0/24`

---

## 🧹 Teardown & Cleanup

To avoid incurring continuous AWS charges, ensure you destroy the infrastructure when you are done testing. 

*Note: The S3 bucket is configured with `force_destroy = true` and will delete the uploaded HTML and video files automatically upon teardown.*

```bash
terraform destroy --auto-approve
```

---

## 🚀 Future Roadmap & Enhancements

To evolve this from a proof-of-concept into a production-grade streaming service, the following architectural upgrades are planned:
- **Content Delivery Network (CDN):** Implement **AWS CloudFront** in front of the S3 bucket to cache video segments globally, reducing origin load and latency.
- **Security:** Attach an ACM certificate to the ALB and enforce HTTPS (`port 443`) listeners.
- **Private Compute:** Move the EC2 Auto Scaling Group into Private Subnets, routing outbound traffic through a NAT Gateway for enhanced security.
- **Modularization:** Refactor the monolithic `main.tf` into distinct, reusable Terraform modules (e.g., `network`, `compute`, `storage`).