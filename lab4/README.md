# Lab 4

Instructions for this section will be provided in class and on Blackboard when we reach it.

Put your work for Lab 4 in this folder.

## 1. Build, Run, and Health Check Instructions

* **Build the Docker Image locally:**
  ```bash
  docker build -t acs730-lab4:latest lab4/

* **Run the Container:**
```bash
docker run -d --name app -p 8000:8000 acs730-lab4:latest

* **Access the Health Endpoint (/healthz):**
```bash
curl http://localhost:8000/healthz

## 2. Image Size Table

| Image | Base Image                | Size   | Rebuild Time |
|-------|---------------------------|--------|--------------|
| Naive | python:latest             | 1.15GB | 4.8s         |
| Slim  | python:3.12-slim-bookworm | 137MB  | 0.5s         |

- how much of the difference is the base image
> The slim image is 1.02GB smaller than the naive image

- whether the dependency layer is CACHED on a code-only rebuild and in which image
> On a code-only rebuild, the dependency installation layer was successfully CACHED in the Slim image because requirements.txt was copied and installed before app.py.

- what .dockerignore kept out of the context
> The .dockerignore file successfully kept out heavy, sensitive, and unnecessary files (such as .git, .github, __pycache__/, *.md, and local evidence/ directories) from entering the Docker build context.

## 3. CI Timings & Caching Performance Table

| Component / Step            | Baseline (No Cache) | Cache Hit | Worth It?                                                                                                          |
| --------------------------- | ------------------- | --------- | ------------------------------------------------------------------------------------------------------------------ |
| Pip Install Step            | 11s                 | 6s        | Yes — Speeds up test matrix execution by avoiding redundant package downloads from PyPI on unchanged dependencies. |
| Docker Build Step           | 11s                 | 7s        | Yes — Reusing cached GHA layers avoids rebuilding static system dependencies and OS packages from scratch.         |
| Whole Workflow (Wall Clock) | 1m 3s               | 49s       | Yes — Cumulative savings drastically shorten feedback loops for minor code tweaks.                                 |

- Why GHCR is Tagged by SHA Rather Than `latest`
> It ensures strict immutability and reproducibility. Using `latest` creates race conditions where different deployments reference different code states under the same name, making rollbacks impossible and provenance tracing unreliable.

- Why a Composite Action vs. a Reusable Workflow:
> The dependency setup is a collection of discrete steps that must execute directly within the exact same runner context as the test job, making a composite action the correct choice. Conversely, the container image build is a distinct job requiring elevated permissions (`packages: write`) that the test job deliberately must not have, which requires a separate reusable workflow.

- GitHub Actions vs. AWS-Native Recommendation
> An AWS-native pipeline replaces GitHub Actions with CodePipeline (orchestration), CodeBuild (builds and tests), and Amazon ECR (container registry).
> Runners: GitHub Actions uses hosted or self-hosted runners; CodeBuild uses managed, temporary build environments that can access your AWS VPC.
> Credentials: GitHub Actions uses GITHUB_TOKEN or OIDC/IAM roles; AWS services use IAM service roles and temporary credentials.
> AWS Academy limitations: Restricted IAM permissions may prevent creating the roles required by CodePipeline and CodeBuild. GitHub Actions avoids these setup restrictions by running CI/CD outside the AWS Academy account.

## 4. Experiments

- Intentional Test Failure Validation
> Modifying an expected status code in test_app.py from 404 to 200 successfully turned the test job red, proving that automated quality gates function as intended before reverting back to the stable state.

- Cache Invalidation Testing
> Altering requirements.txt correctly triggered a cache miss on the pip install step, forcing a fresh download from PyPI and updating the cache store for subsequent runs.
