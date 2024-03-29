locals {
  role_name = "SymRuntime${title(var.environment)}"

  # Variables to generate a list of AWS IAM Roles that the Sym Runtime Role can assume.
  # The Sym Runtime Role can assume roles in the /sym/ path in the current AWS account and all accounts specified in the
  # account_id_safelist input variable.
  accessible_account_ids = concat([data.aws_caller_identity.current.account_id], var.account_id_safelist)
  assumable_role_arns    = [for acct in local.accessible_account_ids : "arn:aws:iam::${acct}:role/sym/*"]
}

# A data source to read the effective Account ID, User ID, and ARN in which Terraform is authorized.
data "aws_caller_identity" "current" {}

# A data source to read the effective AWS region in which Terraform is authorized.
data "aws_region" "current" {}

# A random UUID that will be used as the External ID in the aws_iam_role.sym_runtime_connector_role's Assume Role Policy
resource "random_uuid" "external_id" {}

# This is the role that the Sym Runtime will assume in your AWS account to perform actions such as
# reading secrets from AWS Secrets Manager.
resource "aws_iam_role" "sym_runtime_connector_role" {
  name = local.role_name
  path = "/sym/"

  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = [var.sym_account_id]
        }
        Condition = {
          StringEquals = {
            # This role can only be assumed if Sym provides this specific UUID as the External ID.
            "sts:ExternalId" = random_uuid.external_id.result
          }
        }
      }
    ]
    Version = "2012-10-17"
  })

  tags = var.tags
}

resource "aws_iam_policy" "assume_roles" {
  name = local.role_name
  path = "/sym/"

  description = "These are base permissions required for the Sym Runtime to perform any actions in your AWS account. This policy allows the Sym Runtime to assume roles in the /sym/ path in the current AWS account and any AWS accounts specified in the account_id_safelist."
  policy = jsonencode({
    Statement = [{
      Action   = "sts:AssumeRole"
      Effect   = "Allow"
      Resource = local.assumable_role_arns
    }]
    Version = "2012-10-17"
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "attach_assume_roles" {
  policy_arn = aws_iam_policy.assume_roles.arn
  role       = aws_iam_role.sym_runtime_connector_role.name
}

# An Integration that tells the Sym Runtime which AWS Role to assume to perform actions in your AWS account.
resource "sym_integration" "runtime_context" {
  type = "permission_context"
  name = "${var.environment}-runtime-context"

  # This tells Sym which AWS account the IAM Role is in.
  # It is different from settings.external_id below, which is the AWS-specific external_id.
  external_id = data.aws_caller_identity.current.account_id

  settings = {
    cloud       = "aws"
    region      = data.aws_region.current.name
    role_arn    = aws_iam_role.sym_runtime_connector_role.arn
    external_id = random_uuid.external_id.result
    account_id  = data.aws_caller_identity.current.account_id
  }
}

resource "sym_runtime" "this" {
  name = var.environment

  # Give the Sym Runtime the permissions defined by the runtime_context resource.
  context_id = sym_integration.runtime_context.id
}
