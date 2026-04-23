# DevSecOps - Numeric Application

A Spring Boot microservice with a fully automated DevSecOps pipeline. The pipeline integrates security scanning at every stage — from source code to runtime — before deploying to Kubernetes.

## Application

A simple REST API built with Spring Boot that performs numeric operations. Runs on port `8080`.

## Pipeline Overview

The Jenkins pipeline runs the following stages in order:

| Stage | Tool | Purpose |
|---|---|---|
| Secret Scan | Gitleaks | Detect hardcoded secrets in source code |
| Build | Maven | Compile and package the JAR |
| SCA - Dependency Scan | Trivy + OWASP Dependency-Check | Scan dependencies for known CVEs (parallel) |
| SAST | SonarQube | Static code analysis and quality gate |
| Docker Vulnerability Scan | Trivy + OPA Conftest | Scan Dockerfile for vulnerabilities and policy violations (parallel) |
| Docker Build & Push | Docker | Build image tagged with Git commit SHA and push to Docker Hub |
| Kubernetes Vulnerability Scan | Trivy + OPA Conftest | Scan K8s manifests for vulnerabilities and policy violations (parallel) |
| Kubernetes Deployment | kubectl | Deploy to DEV cluster |
| DAST | OWASP ZAP | Dynamic application security testing against live deployment |

## Prerequisites

### Jenkins Plugins
- Pipeline
- SonarQube Scanner
- HTML Publisher
- Docker Pipeline
- Kubernetes CLI

### Jenkins Credentials

| Credential ID | Type | Used For |
|---|---|---|
| `docker-hub` | Username/Password | Docker Hub push |
| `kubeconfig` | Secret file | Kubernetes cluster access |
| `nvd-api-key` | Secret text | OWASP Dependency-Check NVD API |

### Tools on Jenkins Agent
- Docker
- Maven
- Trivy
- kubectl

### SonarQube
- A running SonarQube instance
- Configure a webhook in SonarQube pointing to `http://<jenkins-url>/sonarqube-webhook/` for faster quality gate results

### OWASP Dependency-Check Database (optional, speeds up SCA)
Pre-download the NVD database to avoid downloading it on every run:
```bash
docker run --rm \
  -v /var/lib/jenkins/.m2/repository/org/owasp/dependency-check-data/9.0:/usr/share/dependency-check/data \
  owasp/dependency-check:latest \
  --updateonly \
  --nvdApiKey <your-nvd-api-key>
```
The pipeline mounts this path automatically on subsequent runs.

## Installation

**1. Clone the repo**
```bash
git clone <repo-url>
cd kubernetes-devops-security
```

**2. Configure Jenkins**
- Add the credentials listed above
- Add a SonarQube server under `Manage Jenkins → Configure System` with the name `SonarQube`
- Create a Pipeline job pointing to this repo

**3. Update environment values in the Jenkinsfile**
```groovy
applicationURL = "http://<your-server-ip>"
```
And update the SonarQube host URL and token in the `SonarQube Analysis` stage.

**4. Run the pipeline**

Trigger a build. Reports are published to the Jenkins build page:
- Trivy Dependency Scan Report
- OWASP Dependency Check Report
- OWASP ZAP HTML Report

## Project Structure

```
├── Jenkinsfile                   # CI/CD pipeline definition
├── Dockerfile                    # Container image definition
├── k8s_deployment_service.yaml   # Kubernetes Deployment and Service
├── opa-docker-security.rego      # OPA policy for Dockerfile
├── opa-k8s-security.rego         # OPA policy for K8s manifests
├── trivy-docker-image-scan.sh    # Trivy Docker image scan script
├── trivy-k8s-scan.sh             # Trivy K8s manifest scan script
├── zap.sh                        # OWASP ZAP DAST script
└── src/                          # Spring Boot application source
```
