# Serverless DINOv2 Deep Learning Inference System on AWS EKS Fargate

> **Infrastructure Status Note:** To manage cloud expenses efficiently, the production EKS Fargate cluster is spun up dynamically via Terraform for testing cycles and torn down post-verification. The active deployment artifacts, logs, and live Swagger document verification have been recorded below as static proof of architecture completion.

## 🏗️ Architecture Overview

The system uses an enterprise-grade, serverless Kubernetes design to host high-performance PyTorch model endpoints with zero sustained EC2 server overhead.

![AWS Architectural Diagram](docs/EKS_Fargate_ALB.png)

### Core Infrastructure Highlights
* **Serverless Compute (AWS Fargate):** Isolated, custom-sized runtime environments that hold the PyTorch weights permanently in memory, entirely bypassing server maintenance and serverless cold-start latency.
* **AWS Load Balancer Controller:** Dynamically provisions an Internet-facing Application Load Balancer mapping incoming HTTP port 80 targets directly to Fargate Pod IPs using VPC-native container routing (`target-type: ip`).
* **IAM Roles for Service Accounts (IRSA):** Uses secure AWS OIDC identity providers to grant the container runtime precise permission scopes to read dataset inputs from AWS S3 without hardcoded access credentials.

![EKS running pods - 2 x core DNS, 2 x ALB controller, 1 x model app] (docs/eks_pods.png)
![ALB monitoring screenshot] (docs/ALB_monitor.png)

---

## 🖼️ Deployment Proof of Work

### 1. Interactive API Gateway (FastAPI Swagger UI)
![Swagger UI /health enpoint] (docs/swagger_ping.png)
![Swagger UI /predictions enpoint] (docs/swagger_predictions.png)
The system dynamically exposes its machine learning signature via FastAPI's documentation layer, hosted natively behind the AWS Application Load Balancer:
`http://k8s-celldino-[...].us-east-1.elb.amazonaws.com/docs`

### 2. High-Performance Test Batch Run Logs
*Add your terminal output screenshot here*
Using raw streaming binary payload configurations over the network via our evaluation harness script (`test_inference.py`), sequential images are processed out of AWS S3 with instant, sub-second tracking classifications returned:

```
for index, s3_key in enumerate(image_keys, start=1):
    filename = os.path.basename(s3_key)
    print(f"[{index}/10] Downloading: {filename}")
    
    try:
        file_stream = io.BytesIO()
        s3_client.download_fileobj(S3_BUCKET, s3_key, file_stream)
        image_bytes = file_stream.getvalue()
    except Exception as s3_err:
        print(f"Failed downloading from S3: {s3_err}")
        continue

    content_type = "image/png" if filename.lower().endswith((".png")) else "image/jpeg"

    print(f"Sending bytes to ALB /invocations...")
    try:
        # POST the raw binary payload directly in the body
        response = requests.post(
            INVOCATIONS_URL,
            data=image_bytes,
            headers={"Content-Type": content_type},
            timeout=30  # Standard timeout safety window
        )
        
        # Check response status
        if response.status_code == 200:
            prediction = response.json()
            print(f"Success! Response: {prediction}")
        else:
            print(f"API returned Error Code {response.status_code}: {response.text}")
            
    except requests.exceptions.RequestException as req_err:
        print(f"Failed connecting to Inference Endpoint: {req_err}")

    print("-" * 60)

print("Inference batch run complete!")
```

![Prediction results] (docs/python_logs.png)