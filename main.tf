locals {
  role_name  = "SymRuntime${title(var.environment_name)}"
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
      },
      # Allow for role self-assumption due to Sym engine internals.
      # Initial provisioning of the role fails if we specify the role ARN as a
      # resource, so using a PrincipalArn condition as suggested here:
      # https://aws.amazon.com/premiumsupport/knowledge-center/iam-trust-policy-error/
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = ["*"] # This is constrained by the PrincipalArn condition to only the current role
        }
        Condition = {
          StringEquals = {
            "aws:PrincipalArn" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/sym/${local.role_name}"
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

  description = "These are base permissions required for the Sym Runtime to perform any actions in your AWS account. This policy allows the Sym Runtime to assume roles in the /sym/ path in safelisted accounts."
  policy = jsonencode({
    Statement = [{
      Action   = "sts:AssumeRole"
      Effect   = "Allow"
      Resource = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/sym/*"]
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
  name = "${var.environment_name}-runtime-context"

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
  name = var.environment_name

  # Give the Sym Runtime the permissions defined by the runtime_context resource.
  context_id = sym_integration.runtime_context.id
}
