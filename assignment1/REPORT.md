# Assignment 1 — Multi-Environment CI/CD Deployment

**Course:** ACS730  
**Repository:** `mmpoonya/acs730-lab1`

## 1. Introduction

This assignment extends the Week 7 infrastructure provisioning and application deployment pipeline into a multi-environment CI/CD solution. The objectives are to reduce infrastructure configuration duplication, automate deployment promotion, protect deployment credentials, and introduce application secret management and infrastructure monitoring.

Terraform provisions AWS infrastructure, Ansible configures the web application through AWS Systems Manager (SSM), and GitHub Actions orchestrates deployment. GitHub Environments controls production approval and credential access. AWS Academy temporary session credentials are used instead of long-lived access keys.

## 2. Reusable Terraform Module

The Week 7 Terraform configuration was refactored into a reusable module at `assignment1/terraform/modules/infrastructure/`.

| File | Responsibility |
|---|---|
| `versions.tf` | Terraform and AWS provider requirements |
| `variables.tf` | Typed inputs and validation |
| `locals.tf` | Resource naming and common tags |
| `network.tf` | Default VPC lookup and security group |
| `compute.tf` | EC2 provisioning and AMI lookup |
| `secrets.tf` | Application secret retrieval |
| `monitoring.tf` | CloudWatch CPU alarms |
| `outputs.tf` | Infrastructure and application metadata |

The module accepts environment name, instance count, instance type, HTTP CIDR blocks, additional tags, and CPU alarm threshold. Shared naming conventions and the Academy instance profile are defined as local values. Outputs expose instance IDs, public IP addresses, web URLs, security group ID, environment name, secret metadata and alarm names.

The `count` meta-argument is used for EC2 instances and their corresponding alarms because instances are interchangeable and share the same configuration. `for_each` would be preferable for resources with distinct configurations or stable logical identifiers, since removing an item from a count-indexed collection can shift resource addresses.

The module uses encrypted EC2 root volumes, requires IMDSv2, and permits HTTP traffic without opening SSH. Ansible uses SSM Session Manager rather than SSH. The public HTTP endpoint is suitable for this demonstration but would require HTTPS and additional access controls in production.

## 3. Multi-Environment Configuration

The `dev`, `staging`, and `prod` root configurations call the same infrastructure module with environment-specific inputs.

| Configuration | Dev | Staging | Prod |
|---|---|---|---|
| Instance type | t3.micro | t3.micro | t3.micro |
| Instance count | 1 | 1 | 1 |
| Environment | dev | staging | prod |
| Purpose tag | Development | Testing | Production |
| CPU alarm threshold | 90% | 85% | 80% |

Each root uses the existing S3 backend bucket with a distinct state key:

- `assignment1/dev/terraform.tfstate`
- `assignment1/staging/terraform.tfstate`
- `assignment1/prod/terraform.tfstate`

Backend encryption and S3 state locking are enabled. Separate state keys prevent Terraform operations in one environment from directly managing resources tracked by another environment's state.

Development was initially deployed and tested locally, then destroyed. Staging and production were deployed through GitHub Actions. All environments share the AWS Academy account and default VPC, but use separate resources, tags and state files. This is logical separation, not full network or IAM isolation. Separate accounts and VPCs would be preferable for real production workloads.

**Evidence:** [backend-state-keys.txt](https://github.com/mmpoonya/acs730-lab1/blob/main/assignment1/evidence/backend-state-keys.txt).

## 4. GitHub Environments

The `staging` environment deploys automatically when relevant infrastructure or application changes are merged into `main`. The `prod` environment requires manual approval. Both environments restrict deployment branches to `main`.

The production job declares `needs: deploy-staging`, so production deployment is dependent on successful staging provisioning, Ansible configuration and HTTP verification. The deployment workflow is scoped to infrastructure, application and deployment workflow changes to avoid redeploying resources when only documentation or evidence is updated.

For this individual assignment, the repository owner is the production reviewer and self-review is permitted. An independent reviewer and restricted administrative bypass would provide stronger separation of duties in an organizational environment.

**Evidence:** [environments.json](https://github.com/mmpoonya/acs730-lab1/blob/main/assignment1/evidence/environments.json), [prod-branch-policy.json](https://github.com/mmpoonya/acs730-lab1/blob/main/assignment1/evidence/prod-branch-policy.json), [pending approval](https://github.com/mmpoonya/acs730-lab1/blob/main/assignment1/evidence/prod-approval-pending.png), [approved deployment](https://github.com/mmpoonya/acs730-lab1/blob/main/assignment1/evidence/prod-approval-approved.png).

## 5. Credential Management and OIDC

### 5.1 AWS Academy credentials

The pipeline uses three temporary session credential secrets in each of the `staging` and `prod` GitHub Environments:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`

Deployment jobs reference their respective GitHub Environment. Credentials are refreshed at the beginning of each Academy session using:

```bash
./scripts/refresh-gha-creds.sh mmpoonya/acs730-lab1 staging prod
```

The environment-scoped form is necessary to avoid writing refreshed credentials to repository scope. The intended final configuration removes all three repository-level copies. The secret scope evidence must confirm this before submission. Environment-scoped secrets control access within GitHub but do not independently limit AWS permissions, since both environments use the Academy account's session credentials.

**Evidence:** [secrets-scope.txt](https://github.com/mmpoonya/acs730-lab1/blob/main/assignment1/evidence/secrets-scope.txt).

### 5.2 Proposed production OIDC trust policy

In a real AWS account, GitHub Actions could use OpenID Connect (OIDC) to assume an environment-specific IAM role without storing AWS access credentials in GitHub. The following hypothetical production trust policy assumes an existing GitHub OIDC provider in the production account. Replace `<PRODUCTION_ACCOUNT_ID>` with the actual account ID when implementing it.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<PRODUCTION_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:mmpoonya/acs730-lab1:environment:prod"
        }
      }
    }
  ]
}
```

| Element | Explanation |
|---|---|
| `Effect` | Allows role assumption when the trust requirements are satisfied. |
| `Principal.Federated` | Identifies the trusted GitHub OIDC provider in the production account. |
| `Action` | Allows STS to exchange a valid web identity token for temporary role credentials. |
| `aud` | Requires the token to be intended for AWS STS. |
| `sub` | Restricts the token subject to the exact repository and production environment. |
| `StringEquals` | Requires exact matches for both claims. |

A wildcard such as `repo:mmpoonya/acs730-lab1:*` would allow additional repository workflow contexts, potentially including branches or environments that should not have production access. Because the environment-based subject does not include the branch name, the `prod` environment's main-only branch policy and approval gate are important complementary controls. Restricting who can modify workflows and environment settings is also necessary.

The production workflow would require `id-token: write` and would configure AWS authentication using the role ARN. The role would need a separate least-privilege permissions policy. This OIDC policy is a proposal, not a deployed configuration, because AWS Academy restricts IAM administration.

## 6. Real AWS Deployment

The pull request CI workflow validates Terraform for all three environments and checks Ansible playbook syntax. All 12 checks passed before the initial merge, including the four Assignment 1 validation jobs.

After merging into `main`, the deployment workflow performs the following operations:

1. Install Terraform, Python, Ansible and AWS dependencies.
2. Authenticate using environment-scoped session credentials.
3. Initialize the S3 backend, validate Terraform and generate a plan.
4. Apply the saved Terraform plan.
5. Wait for EC2 instances to become accessible through SSM.
6. Configure the web application using Ansible.
7. Verify the application through HTTP requests, checking its environment and Git commit SHA.
8. Wait for production approval after staging succeeds, then repeat the deployment process for production.

The initial application change introduced version 1.1.0 and deployment information on the web page. The application displays its environment, version and build commit. Staging and production are deployed from the same workflow revision.

The workflow uses Terraform 1.10.3, Python 3.12, Ansible Core 2.19.x, amazon.aws 12.1.0 and community.aws 12.0.0. Both AWS collections require Ansible Core 2.18 or later.

| Deployment | Run ID | Duration | Result |
|---|---|---|---|
| Initial multi-environment deployment | 45742886795 | 17m 41s | Success |
| SSM and CloudWatch integration | 45749452890 | 4m 12s | Success |

The second deployment demonstrates that infrastructure improvements can be promoted through the same pipeline and approval mechanism.

**Workflow runs:** [Initial deployment](https://github.com/mmpoonya/acs730-lab1/actions/runs/45742886795), [SSM and CloudWatch deployment](https://github.com/mmpoonya/acs730-lab1/actions/runs/45749452890).

**Evidence:** [staging-apply.txt](https://github.com/mmpoonya/acs730-lab1/blob/main/assignment1/evidence/staging-apply.txt), [prod-apply.txt](https://github.com/mmpoonya/acs730-lab1/blob/main/assignment1/evidence/prod-apply.txt), [pending approval](https://github.com/mmpoonya/acs730-lab1/blob/main/assignment1/evidence/prod-approval-pending.png), [approved deployment](https://github.com/mmpoonya/acs730-lab1/blob/main/assignment1/evidence/prod-approval-approved.png).

## 7. Application Secret Management

AWS Systems Manager Parameter Store stores environment-specific demonstration database passwords rather than hardcoding their values in Terraform. Three Standard-tier SecureString parameters were created outside Terraform using the AWS CLI:

```bash
for env in dev staging prod; do
  aws ssm put-parameter \
    --name "/acs730/assignment1/${env}/db-password" \
    --description "Assignment 1 ${env} placeholder database password" \
    --type SecureString \
    --value "$(openssl rand -hex 24)" \
    --tier Standard \
    --region us-east-1
done
```

The reusable module reads the existing parameter using a data source:

```hcl
data "aws_ssm_parameter" "db_password" {
  name            = "/acs730/assignment1/${var.environment}/db-password"
  with_decryption = true
}
```

The environment input determines the parameter name. Terraform does not manage the parameter lifecycle. Only the parameter name and version are exposed as outputs. The observed staging and production outputs confirmed that both retrieved their respective parameters at version 1.

The password is a demonstration application secret: the current web application does not connect to a database or consume the password at runtime. Decrypted parameter values can be stored in Terraform state even when they are not exposed as outputs. Consequently, state and saved plans must be protected and must never be committed to the public repository. Runtime retrieval using a least-privilege IAM role would be preferable for real application secrets.

**Evidence:** [ssm-parameter.txt](https://github.com/mmpoonya/acs730-lab1/blob/main/assignment1/evidence/ssm-parameter.txt).

## 8. CloudWatch Monitoring

The reusable module creates one CloudWatch metric alarm per EC2 instance, using its actual instance ID as the metric dimension.

| Setting | Value |
|---|---|
| Namespace | AWS/EC2 |
| Metric | CPUUtilization |
| Statistic | Average |
| Period | 300 seconds |
| Evaluation periods | 2 |
| Datapoints to alarm | 2 |
| Comparison | GreaterThanThreshold |
| Missing data treatment | missing |

Five-minute periods match EC2 basic monitoring. The alarm evaluates two datapoints against the configured threshold. Production uses a lower threshold than staging and development to detect elevated CPU utilization earlier.

The observed deployed alarms were:

| Alarm | Threshold | State |
|---|---|---|
| acs730-a1-staging-web-0-high-cpu | 85% | OK |
| acs730-a1-prod-web-0-high-cpu | 80% | OK |

Both alarms were evaluated successfully rather than remaining in `INSUFFICIENT_DATA`. Their `OK` states indicate that the alarm conditions were not met at the time of observation. No SNS notification actions were configured; production monitoring could integrate SNS or an incident management service to notify operators.

**Evidence:** [cloudwatch-alarm.json](https://github.com/mmpoonya/acs730-lab1/blob/main/assignment1/evidence/cloudwatch-alarm.json), [cloudwatch-alarm.png](https://github.com/mmpoonya/acs730-lab1/blob/main/assignment1/evidence/cloudwatch-alarm.png).

## 9. CI/CD Platform Recommendation

For an AWS-only team, GitHub Actions and AWS-native CI/CD using CodePipeline and CodeBuild can both automate testing, Terraform provisioning and application deployment. CodeDeploy can also be used where its deployment mechanisms are appropriate. The decision should depend on identity management, network connectivity, operating costs and team expertise.

**Identity and security.** GitHub Actions can use OIDC to assume environment-specific AWS roles, avoiding stored long-lived credentials. GitHub Environments provides approval and branch restrictions. AWS-native services use IAM service roles directly, reducing the need for external workload identity federation. CodePipeline also supports manual approval stages. Both approaches require least-privilege policies and controlled production access.

**Private network access.** GitHub-hosted runners generally require additional connectivity arrangements to access private AWS resources. Self-hosted runners inside a VPC are another option, but introduce maintenance responsibilities. CodeBuild supports VPC integration, allowing build and deployment tasks to reach private resources when routes, security groups and permissions are correctly configured. This is valuable for private databases and internal services.

**Cost and runner management.** GitHub-hosted runners and CodeBuild both provide managed execution environments, reducing operating system maintenance and patching responsibilities. GitHub Actions costs depend on repository visibility, runner type and usage; CodeBuild costs depend on compute and execution duration, while CodePipeline may introduce orchestration charges. A team should estimate costs using its actual deployment frequency and workload duration rather than assuming either platform is always cheaper.

**Team knowledge and workflow.** GitHub Actions integrates closely with GitHub pull requests, code reviews and repository-based YAML workflows. It is attractive for teams already familiar with GitHub. AWS-native CI/CD requires knowledge of CodePipeline, CodeBuild, IAM and AWS networking, but integrates closely with AWS operational tooling.

**Recommendation.** For an AWS-only organization operating production workloads inside private VPCs, I recommend CodePipeline and CodeBuild because of their direct IAM integration, managed execution environments and VPC connectivity. If the team's workloads do not require private network access and its existing development process is centered on GitHub, GitHub Actions with OIDC is a strong alternative. The successful deployment in this assignment demonstrates that GitHub Actions can effectively support Terraform, Ansible, staging verification and production approval.

## 10. Conclusion

This assignment extended the Week 7 pipeline into a reusable multi-environment CI/CD solution. Terraform modules reduced duplication, separate S3 state keys provided logical environment separation, and GitHub Actions automated infrastructure provisioning and application configuration. GitHub Environments introduced a controlled production approval process.

Temporary AWS Academy credentials supported deployment, SSM Parameter Store demonstrated centralized application secret management, and CloudWatch evaluated real EC2 CPU utilization metrics. Both deployment runs completed successfully.

Future improvements include separate AWS accounts and VPCs, OIDC authentication, runtime secret retrieval, independent production reviewers, HTTPS and automated monitoring notifications.

### Infrastructure cleanup

After completing the deployments and collecting the required evidence, Terraform destroy was executed for all three environments.

| Environment | Resources Destroyed | Result |
|---|---|---|
| Dev | 0 | Previously destroyed |
| Staging | 3 | Successful |
| Production | 3 | Successful |

A total of six remaining Terraform-managed resources were successfully destroyed, including two EC2 instances, two security groups, and two CloudWatch alarms.

The cleanup-check script confirmed that no Assignment 1 EC2 instances or security groups remained. The existing workstation was preserved for future coursework.

This cleanup process prevents unnecessary AWS Academy resource consumption and demonstrates responsible cloud resource lifecycle management.

Evidence: [destroy-complete.txt](https://github.com/mmpoonya/acs730-lab1/blob/main/assignment1/evidence/destroy-complete.txt)
