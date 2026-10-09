# Lab 3

Instructions for this section will be provided in class and on Blackboard when we reach it.

Put your work for Lab 3 in this folder.

### Why OIDC vs. Stored Keys?
A production environment uses OpenID Connect (OIDC) to assume roles dynamically without storing long-lived credentials, eliminating the risk of static key leakage. Conversely, this course uses temporary session-scoped secrets to simplify local setup, and damage is limited because these credentials expire automatically within a few hours and carry minimal IAM permissions.

## Operational Troubleshooting & Recovery

* **ExpiredToken on a deploy:** Your lab session ended. Start a new one, re-run `./scripts/refresh-gha-creds.sh`, and re-run the job. Nothing in the repository changes.
* **"Input required and not supplied: aws-region":** The `AWS_REGION` variable does not exist—this is not a credential problem. Run the refresh script or set it manually using:
  ```bash
  gh variable set AWS_REGION --body us-east-1
