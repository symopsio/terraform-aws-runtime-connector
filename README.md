# runtime-connector

The `runtime-connector` module provisions the IAM role that a Sym Runtime uses to execute a Flow.

This `Connector` will provision a single IAM role for the Sym Runtime to use at execution time.

By default, the Runtime only has permissions to assume roles that have a path that begins with `/sym/`, and only within a provided safelist of AWS accounts. The Runtime always includes the current AWS account in the safelist.

The role created for the Runtime uses an [External ID](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_common-scenarios_third-party.html), a best practice for invoking cross-account roles. This module will generate an External ID for you, unless you configure the `custom_external_id` to override it.

```hcl
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = ">= 1.0.0"

  environment = "sandbox"
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_kinesis_data_stream"></a> [aws\_kinesis\_data\_stream](#module\_aws\_kinesis\_data\_stream) | symopsio/kinesis-data-stream-addon/aws | >= 1.0.0 |
| <a name="module_aws_kinesis_firehose"></a> [aws\_kinesis\_firehose](#module\_aws\_kinesis\_firehose) | symopsio/kinesis-firehose-addon/aws | >= 1.0.0 |
| <a name="module_aws_secretsmgr"></a> [aws\_secretsmgr](#module\_aws\_secretsmgr) | symopsio/secretsmgr-addon/aws | >= 1.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.assume_roles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.assume_roles_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.aws_kinesis_data_stream_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.aws_kinesis_firehose_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.aws_secretsmgr_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.extra_policy_attachments](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [random_uuid.external_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id_safelist"></a> [account\_id\_safelist](#input\_account\_id\_safelist) | List of addtional AWS account ids (beyond the current AWS account) that the runtime can assume roles in. | `list(string)` | `[]` | no |
| <a name="input_addon_params"></a> [addon\_params](#input\_addon\_params) | Additional parameters for selected addons | `map(map(any))` | `{}` | no |
| <a name="input_addons"></a> [addons](#input\_addons) | List of Sym addon permissions for the runtime connector role. Addons give the runtime permissions to work with other resources without assuming another AWS role. | `list(string)` | `[]` | no |
| <a name="input_custom_external_id"></a> [custom\_external\_id](#input\_custom\_external\_id) | The external ID to use for AWS assume role validation. If unspecified, the connector generates an external ID and the Sym platform ensures it is unique. | `string` | `""` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | An environment qualifier for the resources this module creates, to support a Terraform SDLC. | `string` | n/a | yes |
| <a name="input_policy_arns"></a> [policy\_arns](#input\_policy\_arns) | Map of logical identifiers to additional IAM Managed Policy ARNs to add to the runtime connector role. The identifiers are only used for managing Terraform state. | `map(string)` | `{}` | no |
| <a name="input_sym_account_ids"></a> [sym\_account\_ids](#input\_sym\_account\_ids) | List of account ids that can assume the runtime role. By default, only Sym production accounts can assume the runtime role. | `list(string)` | <pre>[<br>  "803477428605"<br>]</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | The AWS account ID for this connector |
| <a name="output_settings"></a> [settings](#output\_settings) | A map of settings to supply to a Sym Permission Context. |
<!-- END_TF_DOCS -->
