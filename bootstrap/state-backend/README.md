# Remote State Bootstrap

Use this stack to create and manage the remote state backend before applying the main environment stacks.

This bootstrap creates:
- an encrypted versioned S3 bucket for state
- a lock table for safe team operations
- public access blocking on the state bucket

Typical flow:
1. run this bootstrap stack first
2. apply it once to create the shared backend resources
3. initialize the lab and prod environments against that backend
