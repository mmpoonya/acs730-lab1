# Lab 5

Instructions for this section will be provided in class and on Blackboard when we reach it.

Put your work for Lab 5 in this folder.

## Why for_each here and count there

* **Subnets use for_each** because they are distinct resources with stable keys (e.g., `a`, `b`). Adding a new subnet key or removing one cleanly adds or destroys only that specific resource without affecting the indices or identities of the remaining subnets.
* **The same subnets with count would be a trap** because index-based lists (`[0]`, `[1]`) cause shifting issues if a middle item is removed, forcing Terraform to needlessly destroy and recreate subsequent resources.
* **The artifact bucket uses count** because it represents a binary toggle (yes/no) for a single optional resource, resulting in exactly two plans ("0 to add" or "1 to add") with no stable multi-item keys needed. 

**Summary rule:** Use `count` when the question is *how many*, and `for_each` when the question is *which ones*.
