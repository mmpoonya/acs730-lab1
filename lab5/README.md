# Lab 5

Instructions for this section will be provided in class and on Blackboard when we reach it.

Put your work for Lab 5 in this folder.

## Why for_each here and count there

* **Subnets use for_each** because they are distinct resources with stable keys (e.g., `a`, `b`). Adding a new subnet key or removing one cleanly adds or destroys only that specific resource without affecting the indices or identities of the remaining subnets.
* **The same subnets with count would be a trap** because index-based lists (`[0]`, `[1]`) cause shifting issues if a middle item is removed, forcing Terraform to needlessly destroy and recreate subsequent resources.
* **The artifact bucket uses count** because it represents a binary toggle (yes/no) for a single optional resource, resulting in exactly two plans ("0 to add" or "1 to add") with no stable multi-item keys needed. 

**Summary rule:** Use `count` when the question is *how many*, and `for_each` when the question is *which ones*.

## Why not plan and apply against real AWS on every pull request

* **It costs money per run, not per month:** Every pull request would build and destroy real infrastructure. With multiple students pushing code, this creates thousands of expensive cycles against a fixed budget. LocalStack is free and isolates resources locally.
* **It requires long-lived credentials in the repository:** Running real applies from GitHub Actions requires storing AWS access keys as secrets. These can leak, require rotation, and in an Academy account, they cannot be properly scoped because IAM write permissions are restricted.
* **Academy sessions expire:** Lab credentials only last a few hours, meaning a PR opened on the weekend would fail due to expired credentials rather than code issues, training developers to ignore failing checks.
* **It is slow and flaky:** Real API calls introduce network latency, eventual consistency errors, and rate limits, while concurrent pull requests can collide on names and state files in a shared account.
* **Limits of LocalStack:** A green LocalStack run proves that the configuration is coherent and the graph builds properly. However, it does not validate IAM policies or actual instance boot execution (`user_data`), meaning real AWS validations belong on merge or on a scheduled pipeline rather than every PR.
