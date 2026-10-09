# Lab 3

Instructions for this section will be provided in class and on Blackboard when we reach it.

Put your work for Lab 3 in this folder.

### Why OIDC vs. Stored Keys?
A production environment uses OpenID Connect (OIDC) to assume roles dynamically without storing long-lived credentials, eliminating the risk of static key leakage. Conversely, this course uses temporary session-scoped secrets to simplify local setup, and damage is limited because these credentials expire automatically within a few hours and carry minimal IAM permissions.

