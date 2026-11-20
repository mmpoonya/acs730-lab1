# Lab 6

Instructions for this section will be provided in class and on Blackboard when we reach it.

Put your work for Lab 6 in this folder.

- **Runner-to-instance mechanism and why:** We connected to the target EC2 instances using AWS Systems Manager Session Manager rather than SSH so we neither store a long-lived private SSH key in GitHub repository secrets nor open port 22 inbound to runners whose IP addresses change dynamically.
- **What `changed=0` on a second run proves:** A second run reporting `changed=0` does not mean the playbook did nothing; it proves that every task inspected the live state of the host, found it already matched the desired configuration defined by the role, and applied no redundant changes—making the role safe to run on fresh or already-configured instances and safe to run from a pipeline on every merge.
- **Why deregistering an AMI is not enough:** Deregistering an AMI only removes the image registration; the backing EBS snapshot remains as stored data that continues to bill, and once the AMI is deregistered, `aws ec2 describe-images` no longer links that snapshot ID back to the AMI.

## Boot-to-Ready Comparison

| Approach | Time (s) | What Is Included |
| --- | --- | --- |
| Converge-on-boot (Terraform + SSM + Ansible) | 323 seconds | EC2 instance launch, SSM agent registration, `dnf` package download/install, Jinja2 template & systemd service setup, and first HTTP 200 response |
| Golden AMI (Packer + Launch) | 119 seconds | EC2 instance launch from pre-baked AMI, boot/service startup, and first HTTP 200 response |

- **Where time goes in the slow path:** In the converge-on-boot path, the delay comes primarily from waiting for the SSM agent to register and `dnf` to pull packages over the network per instance on every run rather than from the Ansible task logic itself.
- **Cost trade-off (build vs. launch):** A golden AMI shifts the configuration work once to image build time rather than repeating it $N$ times at launch time, so it pays off when launching more than a couple of instances and loses out when launching just one instance because you pay the Packer build overhead up front.
- **What breaks with golden AMIs:** A golden AMI is a frozen point in time—security and package updates released after the bake are missing without an ongoing rebuild cadence, and inspecting what is inside a baked image is less transparent at a glance than reading a playbook or role.
- **What breaks with converge-on-boot:** Every launch depends on external package mirrors and network endpoints being reachable right then; a mirror outage or an off-hours autoscaling event (such as 3:00 a.m.) is exactly when a live network dependency in the boot path can stall readiness.
- **SSM bucket-and-region constraint:** Session Manager / SSM operations in this lab depend on matching the configured AWS region and any required S3/SSM bucket or endpoint constraints so the SSM agent and runner can establish and transfer session data cleanly.
- **Recommendation:** Golden AMI, because launching multiple instances or scaling out avoids repeating package downloads and agent-registration wait times on every boot—though I would switch to converge-on-boot if we frequently change application/configuration logic and only launch single short-lived instances where baking a new AMI takes longer than configuring in place.

