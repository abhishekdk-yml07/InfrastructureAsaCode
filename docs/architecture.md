# Architecture Decisions — Infrastructure as Code

## ADR-001: Remote State in S3 + DynamoDB

**Status:** Accepted
**Context:** Local Terraform state causes conflicts when multiple engineers run `apply` simultaneously.
**Decision:** Store state in S3 with server-side encryption, use DynamoDB for state locking.
**Consequences:** Requires bootstrapping the S3 bucket and table before first use. Added one-time setup step documented in README.

---

## ADR-002: One NAT Gateway per AZ in Production

**Status:** Accepted
**Context:** A single NAT Gateway is a single point of failure. If the AZ hosting it goes down, all private subnet traffic fails.
**Decision:** Deploy one NAT Gateway per Availability Zone in production. Use `single_nat_gateway = true` only in dev/staging to save cost.
**Cost impact:** +~$65/month in prod for HA. Acceptable for SLA requirements.

---

## ADR-003: IMDSv2 Required on All EC2 Instances

**Status:** Accepted
**Context:** IMDSv1 is vulnerable to SSRF attacks that can leak IAM credentials from the metadata service.
**Decision:** Set `http_tokens = "required"` in the launch template. This forces IMDSv2 (token-based) for all metadata requests.
**Migration note:** Any application code using IMDSv1 directly must be updated to use a PUT request for the token first.

---

## ADR-004: Database Passwords via Secrets Manager

**Status:** Accepted
**Context:** Storing passwords in Terraform variables means they appear in state files and CI logs.
**Decision:** Use `random_password` resource + `aws_secretsmanager_secret`. Password never appears in tfvars. Application fetches it at runtime from Secrets Manager.
**Consequence:** Applications need IAM permission `secretsmanager:GetSecretValue` on the specific secret ARN.

---

## ADR-005: Deletion Protection Conditional on Environment

**Status:** Accepted
**Context:** Accidentally destroying a production RDS or ALB is catastrophic. But deletion protection blocks `terraform destroy` in dev, which is annoying.
**Decision:** `deletion_protection = var.environment == "prod"` — enabled in prod, disabled elsewhere.

---

## ADR-006: S3 Lifecycle Policies

**Status:** Accepted
**Decision:** Objects move to STANDARD_IA after 30 days, GLACIER after 90 days. Non-current versions expire at 90 days.
**Cost impact:** ~60% storage cost reduction for objects older than 30 days.
