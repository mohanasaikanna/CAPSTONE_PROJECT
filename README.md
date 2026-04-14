DevOps Capstone Project

End-to-End CI/CD Pipeline using Node.js, Docker, Jenkins, AWS, Prometheus, and Grafana


Introduction

This project demonstrates a complete DevOps workflow by automating the process of building, testing, deploying, and monitoring a Node.js application. It reflects a real-world production setup where code changes are continuously integrated, validated, and delivered with minimal manual intervention.

The implementation focuses on reliability, automation, and observability, which are essential principles in modern DevOps practices.


Objectives

* Automate application delivery using a CI/CD pipeline
* Containerize the application for consistent deployments
* Deploy and manage services on AWS EC2
* Monitor application and system performance
* Implement basic self-healing and maintenance tasks


Architecture Overview

The system follows a continuous delivery pipeline:

Developer → GitHub → Jenkins → Docker Hub → AWS EC2 → Prometheus → Grafana

1. Code is pushed to GitHub
2. Jenkins detects changes and triggers the pipeline
3. Application is built and tested
4. Docker image is created and pushed to Docker Hub
5. Application is deployed to EC2
6. Prometheus collects metrics
7. Grafana visualizes system and application performance

 Technology Stack

| Layer            | Tools            |
| ---------------- | ---------------- |
| Version Control  | GitHub           |
| CI/CD            | Jenkins          |
| Backend          | Node.js          |
|                  |                  |
| Containerization | Docker           |
| Registry         | Docker Hub       |
| Cloud Platform   | AWS EC2 (Ubuntu) |
| Monitoring       | Prometheus       |
| Visualization    | Grafana          |
| Metrics Export   | Node Exporter    |
|                  |                  |


Repository Structure

CAPSTONE_PROJECT/

* app/
  Contains the Node.js application, Dockerfile, and test cases

* monitoring/
  Includes Prometheus and Grafana configuration

* scripts/
  Automation scripts for EC2 setup, backups, and maintenance

* Jenkinsfile
  Defines the CI/CD pipeline

* README.md
  Project documentation


Application Details

The application is built using Express.js and includes:

* A basic web interface
* Health check endpoint for deployment validation
* Prometheus metrics endpoint for monitoring
* Simple API endpoint for application information

API Endpoints

| Endpoint  | Description                       |
| --------- | --------------------------------- |
| /         | Home page                         |
| /health   | Returns application health status |
| /metrics  | Exposes Prometheus metrics        |
| /api/info | Returns application metadata      |

---

CI/CD Pipeline

The Jenkins pipeline automates the entire delivery process through the following stages:

1. Checkout source code from GitHub
2. Install dependencies using npm
3. Build Docker image
4. Push image to Docker Hub
5. Deploy the container to EC2 via SSH
6. Perform health checks to verify deployment
7. Clean up unused Docker resources

This ensures that every code change is validated and deployed consistently.



Docker Workflow

The application is containerized to ensure consistent behavior across environments.

Build Image

docker build -t devops-app ./app

Run Container

docker run -d -p 3000:3000 --name devops-container devops-app

The container exposes the application on port 3000.

---

AWS Deployment

The system is deployed using EC2 instances:

* Jenkins Server for CI/CD
* Application Server for running the containerized app
* Monitoring Server for Prometheus and Grafana

### Security Group Configuration

| Port | Purpose       |
| ---- | ------------- |
| 22   | SSH access    |
| 8080 | Jenkins       |
| 3000 | Application   |
| 9090 | Prometheus    |
| 3001 | Grafana       |
| 9100 | Node Exporter |


Monitoring and Observability

Prometheus is used to collect metrics from:

* Node.js application (/metrics endpoint)
* Node Exporter (system metrics)

Grafana is used to visualize these metrics through dashboards.

Running Monitoring Stack

cd monitoring
docker compose up -d

Access

* Prometheus: http://:9090
* Grafana: http://:3001

Default Grafana credentials:
Username: admin
Password: admin123

---

Automation with Cron Jobs

Basic operational tasks are automated using cron jobs:

* Daily backup of logs
* Cleanup of old logs and Docker resources
* Periodic health checks with automatic container restart

To install cron jobs:

sudo bash scripts/crontab-setup.sh


Testing

The project uses Jest for unit testing. Tests are executed as part of the CI/CD pipeline to ensure code quality before deployment.


Running the Project Locally

Clone the repository and start the application:

git clone https://github.com/mohanasaikanna/CAPSTONE_PROJECT.git
cd CAPSTONE_PROJECT/app

npm install
npm start

The application will be available at:

http://localhost:3000

Key Outcomes

* Automated CI/CD pipeline from code commit to deployment
* Containerized application using Docker
* Cloud deployment on AWS EC2
* Real-time monitoring using Prometheus and Grafana
* Basic self-healing through automation


Future Improvements

* Deploy using Kubernetes for scalability
* Use Terraform for infrastructure provisioning
* Configure HTTPS with a reverse proxy
* Add alerting mechanisms (email or messaging integrations)
* Implement advanced deployment strategies such as blue-green deployment

Author

Mohana Sai Kanna


Conclusion

This project demonstrates practical DevOps implementation by integrating development, deployment, and monitoring into a single automated workflow. It reflects real-world practices and provides a strong foundation for production-ready systems.
