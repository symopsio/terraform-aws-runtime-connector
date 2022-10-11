data "aws_caller_identity" "current" {}

locals {
  target_accts     = concat([data.aws_caller_identity.current.account_id], var.account_id_safelist)
  target_resources = [for acct in local.target_accts : "arn:aws:iam::${acct}:role/sym/*"]

  external_id = trimspace(var.custom_external_id) == "" ? random_uuid.external_id.result : var.custom_external_id
  role_name = "SymRuntime${title(var.environment)}"
}

resource "random_uuid" "external_id" {}

resource "aws_iam_role" "this" {
  name = local.role_name
  path = "/sym/"

  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = concat(var.sym_account_ids, ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.role_name}"])
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = local.external_id
          }
        }
      }
    ]
    Version = "2012-10-17"
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "assume_roles_attach" {
  policy_arn = aws_iam_policy.assume_roles.arn
  role       = aws_iam_role.this.name
}

# Allow the runtime to assume roles in the /sym/ path in safelisted accounts
resource "aws_iam_policy" "assume_roles" {
  name = local.role_name
  path = "/sym/"

  description = "Base permissions for the Sym runtime"
  policy = jsonencode({
    Statement = [{
      Action   = "sts:AssumeRole"
      Effect   = "Allow"
      Resource = local.target_resources
    }]
    Version = "2012-10-17"
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "extra_policy_attachments" {
  for_each = var.policy_arns

  policy_arn = each.value
  role       = aws_iam_role.this.name
}

locals {
  aws_secrets_mgr_count         = contains(var.addons, "aws/secretsmgr") ? 1 : 0
  aws_kinesis_firehose_count    = contains(var.addons, "aws/kinesis-firehose") ? 1 : 0
  aws_kinesis_data_stream_count = contains(var.addons, "aws/kinesis-data-stream") ? 1 : 0
}

locals {
  secrets_mgr_defaults = {
    "tag_name"  = "SymEnv",
    "tag_value" = var.environment
  }
  secrets_mgr_addons = lookup(var.addon_params, "aws/secretsmgr", {})
  secrets_mgr_vars   = merge(local.secrets_mgr_defaults, local.secrets_mgr_addons)
}

# aws/secretsmgr addon ########################################################
module "aws_secretsmgr" {
  count = local.aws_secrets_mgr_count

  source  = "symopsio/secretsmgr-addon/aws"
  version = ">= 1.0.0"

  environment = local.secrets_mgr_vars["tag_value"]
  tag_name    = local.secrets_mgr_vars["tag_name"]
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "aws_secretsmgr_attach" {
  count = local.aws_secrets_mgr_count

  policy_arn = module.aws_secretsmgr[0].policy_arn
  role       = aws_iam_role.this.name
}

# aws/kinesis-firehose addon ##################################################

module "aws_kinesis_firehose" {
  count = local.aws_kinesis_firehose_count

  source  = "symopsio/kinesis-firehose-addon/aws"
  version = ">= 1.0.0"

  environment = var.environment
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "aws_kinesis_firehose_attach" {
  count = local.aws_kinesis_firehose_count

  policy_arn = module.aws_kinesis_firehose[0].policy_arn
  role       = aws_iam_role.this.name
}

# aws/kinesis-data-stream addon ###############################################

module "aws_kinesis_data_stream" {
  count = local.aws_kinesis_data_stream_count

  source  = "symopsio/kinesis-data-stream-addon/aws"
  version = ">= 1.0.0"

  environment = var.environment
  tags        = var.tags
  stream_arns = var.addon_params["aws/kinesis-data-stream"]["stream_arns"]
}

resource "aws_iam_role_policy_attachment" "aws_kinesis_data_stream_attach" {
  count = local.aws_kinesis_data_stream_count

  policy_arn = module.aws_kinesis_data_stream[0].policy_arn
  role       = aws_iam_role.this.name
}
