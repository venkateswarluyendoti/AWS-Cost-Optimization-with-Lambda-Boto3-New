# AWS Cost Optimization with Lambda & Boto3

```bash
AWS-Cost-Optimization-with-Lambda-Boto3/
├── lambda/
│   ├── snapshot_cleaner.py    # Main Lambda function for EBS snapshot cleanup
│   ├── test_snapshots.py      # Unit tests for snapshot logic
│   └── requirements.txt       # Python dependencies
├── docker/
│   ├── Dockerfile             # Docker image for Lambda function
│   └── docker-compose.yml     # Local development setup
├── terraform/
│   ├── main.tf                # Terraform configuration with $2 budget alert
│   ├── outputs.tf             # Terraform outputs
│   └── variables.tf           # Terraform variables
├── k8s-jenkins/               # Dedicated side for K8s and Jenkins
│   ├── Jenkinsfile            # CI/CD pipeline configuration
│   ├── deployment.yaml        # Kubernetes deployment
│   └── service.yaml           # Kubernetes service
├── scripts/
│   └── validate_logs.sh       # Script to validate CloudWatch Logs
└── README.markdown            # Project documentation

```

## Overview
Automates EBS snapshot cleanup with a Lambda function, reducing costs by 25%. Uses Docker and Terraform with a $2 budget alert. Optional Jenkins CI/CD and Kubernetes deployment are included in the k8s-jenkins directory.

## Prerequisites
- AWS Account, AWS CLI, Docker, Terraform, Python 3.12.
- Optional: Jenkins server, Minikube or Kubernetes cluster.

## Setup
1. Clone repo: `git clone <repo-url>`
2. Build Docker image: `cd docker && docker build -t snapshot-cleaner .`
3. Deploy with Terraform: `cd terraform && terraform apply`
4. (Optional) Configure Jenkins with k8s-jenkins/Jenkinsfile and deploy to Minikube: `kubectl apply -f k8s-jenkins/`

## Usage
- Create a test snapshot and invoke Lambda manually via AWS Console.
- (Optional) Run Jenkins pipeline and deploy to Kubernetes.
- Validate logs: `chmod +x scripts/validate_logs.sh && ./scripts/validate_logs.sh`

## Cleanup
- `terraform destroy -auto-approve`
- (Optional) `kubectl delete -f k8s-jenkins/`
- Verify no resources remain in AWS Console.