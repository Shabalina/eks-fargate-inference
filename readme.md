## 🔬 Cell-DINO: End-to-End Cellular Image Classification
[Live Demo Page](https://dub.sh/cell-classifier-demo) | [Architecture Overview](#system-architecture)

A production-grade MLOps pipeline for classifying cellular images using DINO-based features, deployed on AWS with a fully automated CI/CD pipeline.

### 🔬 Project Motivation & Evolution
**Context**: This project originated from the **Recursion Cellular Image Classification challenge**. Unlike standard contest practices, this project avoids over-fitting to specific plate/batch effects to reach the highest accuracy possible, focusing instead on robust, generalisable feature extraction for real-world inference.

**Model Selection & Benchmarking:**
During the research phase, several architectures were evaluated for their efficacy in capturing the complex morphological features of cellular microscopy, including **DenseNet121**, classic **Vision Transformers (ViTs)**, and **DINO** (Self-Supervised ViT). Ultimately, the DINO-based model—pre-trained specifically on large-scale cellular datasets—was selected for its superior feature representation and biological signal extraction.

**Inference & Deployment**
Following the research phase, a cloud-native inference stack was engineered around the DINO model weights with the highest validation metrics:
- Feature Extraction: The DINO backbone processes images to generate high-dimensional embeddings.
- Serverless Hosting: Deployed via SageMaker Serverless Inference to provide an on-demand, scalable API while maintaining a $0$ cost footprint during idle periods.
- UI Integration: A Streamlit-based frontend that pulls from a managed S3 gallery, providing a seamless interface for researchers to run "Point-and-Click" classification.

### System Architecture 

- **Frontend:** Streamlit (hosted on Streamlit Cloud).

- **Model Inference:** SageMaker Endpoints (PyTorch/DINO).

- **API Layer:** AWS API Gateway with direct SageMaker invocation.

- **Infrastructure:** Terraform (using Workspaces for Environment Isolation).

- **CI/CD:** GitHub Actions (Automated Docker builds to ECR & Terraform Apply).

$~$

<ins>**Deployment Lifecycle Flow diagram:**<ins>

![Deployment Flow](docs/images/DINO_Lifecycle_Flow.drawio.png)

$~$

<ins>**User Experience & Data Flow diagram:**<ins>

![Data Flow](docs/images/architecture_diagram.png)

$~$

### Key Engineering Features

- **Multi-Environment Deployment:** Managed separate QA and Production environments using Terraform Workspaces and Git branching strategies.

- **Optimised Inference:** Cost-Optimised Serverless Architecture and S3-backed gallery for low-latency user experience.

- **Cloud-Native Security:** Secured AWS credentials using GitHub Secrets and scoped IAM policies (Least Privilege).

- **Automated Containerisation:** Built custom Docker images optimised for SageMaker inference, managed via Amazon ECR.


### Project Structure

```bash
.
├── .github/workflows/  # CI/CD Pipeline
├── src/                # Model logic & Inference scripts
├── terraform/          # Infrastructure as Code (Workspaces: QA/Prod)
├── ui/                 # Streamlit Application
└── weights/            # Model artifacts (managed via Git LFS)
```

###  Future Roadmap 

- Implement automated model evaluation gates in CI/CD.
- Add CloudWatch dashboards for inference monitoring.
- Integration of A/B testing for model variants.
