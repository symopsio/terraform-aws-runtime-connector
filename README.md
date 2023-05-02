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
| <a name="requirement_sym"></a> [sym](#requirement\_sym) | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_sym"></a> [sym](#provider\_sym) | >= 2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.assume_roles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.sym_runtime_connector_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.attach_assume_roles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [random_uuid.external_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) | resource |
| [sym_integration.runtime_context](https://registry.terraform.io/providers/symopsio/sym/latest/docs/resources/integration) | resource |
| [sym_runtime.this](https://registry.terraform.io/providers/symopsio/sym/latest/docs/resources/runtime) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | The unique name of the environment in which you are deploying this Sym Runtime Role. (e.g. staging, or prod) | `string` | n/a | yes |
| <a name="input_sym_account_id"></a> [sym\_account\_id](#input\_sym\_account\_id) | The AWS account ID that can assume the Sym Runtime Role. Defaults to the Sym Production AWS account ID. | `string` | `"803477428605"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to the AWS resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sym_integration"></a> [sym\_integration](#output\_sym\_integration) | A [sym\_integration](https://registry.terraform.io/providers/symopsio/sym/latest/docs/resources/integration) resource that tells the Sym Runtime which AWS Role to assume to perform actions in your AWS account. For example, this can be used in sym\_runtime and sym\_secrets resources. |
| <a name="output_sym_runtime"></a> [sym\_runtime](#output\_sym\_runtime) | A [sym\_runtime](https://registry.terraform.io/providers/symopsio/sym/latest/docs/resources/runtime) resource to be passed into your sym\_environment to enable the execution of AWS Strategies. |
| <a name="output_sym_runtime_connector_role"></a> [sym\_runtime\_connector\_role](#output\_sym\_runtime\_connector\_role) | An [aws\_iam\_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) resource. This AWS IAM Role will be assumed by the Sym Runtime to execute operations in your AWS account. |
<!-- END_TF_DOCS -->
