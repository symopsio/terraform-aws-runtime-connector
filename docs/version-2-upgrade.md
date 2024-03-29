---
subcategory: ""
page_title: "Runtime Connector Module Version 2 Upgrade Guide"
description: |-
  Runtime Connector Module Version 2 Upgrade Guide
---

# Runtime Connector Module Version 2 Upgrade Guide

Version 2.0.0 of the Runtime Connector Module is a major release and includes some changes that you will need to consider when upgrading. This guide is intended to help with that process.

Upgrade topics:

- [Runtime Connector Module Version 2 Upgrade Guide](#runtime-connector-module-version-2-upgrade-guide)
  - [Why are we doing this?](#why-are-we-doing-this)
  - [Module Version Configuration](#module-version-configuration)
  - [Removed Inputs: `addons` and `addon_params`](#removed-inputs-addons-and-addon_params)
    - [Refactoring the `aws/secretsmgr` Addon](#refactoring-the-awssecretsmgr-addon)
    - [Refactoring the `aws/kinesis-firehose` Addon](#refactoring-the-awskinesis-firehose-addon)
    - [Refactoring the `aws/kinesis-data-stream` Addon](#refactoring-the-awskinesis-data-stream-addon)
  - [Removed Input: `custom_external_id`](#removed-input-custom_external_id)
  - [Input `policy_arns` has been removed](#input-policy_arns-has-been-removed)
  - [Removed Output: `account_id`](#removed-output-account_id)
  - [Removed Output: `settings`](#removed-output-settings)
  - [New Output: `sym_integration`](#new-output-sym_integration)
  - [New Output: `sym_runtime`](#new-output-sym_runtime)

## Why are we doing this?

The easiest way to manage your Sym configuration is [via the CLI](https://docs.symops.com/docs/generating-sym-workflows). However, we understand that:
- Generated code cannot cover all use cases
- Some prefer to manage their Terraform manually
- Configuration should still be easy to understand

The changes made in this major release are intended to make usage of this module **consistent** across generated and manual configurations, while also **minimizing** the amount of Terraform code required to configure Sym manually. What this really means is that resources that have always depended on this module (like the `sym_integration` and `sym_runtime`) are now included, while functionality that is situational and may have its own set of configuration (access to AWS Secrets Manager or AWS Kinesis Firehose) has been removed in favor of explicit and separate module declarations.

## Module Version Configuration
Before upgrading to version 2.0.0 or later, it is recommended to upgrade to the most recent 1.X version of the module (version 1.0.6)
and ensure that your environment successfully runs `terraform plan` without unexpected changes.

It is recommended to use [version constraints when configuring Terraform providers](https://www.terraform.io/docs/configuration/providers.html#provider-versions).
If you are following that recommendation, update the version constraints in your Terraform configuration and run [`terraform init -upgrade`](https://www.terraform.io/docs/commands/init.html) to download the new version.

For example, given this previous configuration:

```terraform
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = "~> 1.0"

  environment = var.environment
}
```

An updated configuration would be:

```terraform
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = "~> 2.0"

  environment = var.environment
}
```

## Removed Inputs: `addons` and `addon_params`
The `addons` and `addon_params` inputs have been removed as of `runtime_connector` version 2.0.

Instead of passing in a list of addon module names, these modules should now be declared directly in your configuration. The addons should be refactored as follows:
- `aws/secretsmgr`: `symopsio/secretsmgr-addon/aws@1.1` ([View in Terraform registry](https://registry.terraform.io/modules/symopsio/secretsmgr-addon/aws/latest))
- `aws/kinesis-firehose`: `symopsio/kinesis-firehose-addon/aws@1.1` ([View in Terraform registry](https://registry.terraform.io/modules/symopsio/kinesis-firehose-addon/aws/latest))
- `aws/kinesis-data-stream`: `symopsio/kinesis-data-stream-addon/aws@1.1` ([View in Terraform registry](https://registry.terraform.io/modules/symopsio/kinesis-data-stream-addon/aws/latest))

### Refactoring the `aws/secretsmgr` Addon
If `aws/secretsmgr` is declared as an addon, update your configuration to add the `symopsio/secretsmgr-addon/aws` module explicitly.

For example, given this previous configuration:
```terraform
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = "~> 1.0"

  environment = var.environment

  addons = ["aws/secretsmgr"]
}
```

An updated configuration would be:

```terraform
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = "~> 2.0"

  environment = var.environment
}

module "secrets_manager_access" {
  source  = "symopsio/secretsmgr-addon/aws"
  version = "~> 1.1"

  environment   = var.environment
  iam_role_name = module.runtime_connector.sym_runtime_connector_role.name
}
```

Optionally, we recommend using [`moved` configuration blocks](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring#moved-block-syntax)
to migrate your Terraform state, instead of replacing the existing IAM policies with new ones:
```terraform
# Note: These `moved` statements require terraform >= 1.3.0 (https://github.com/hashicorp/terraform/releases/tag/v1.3.0)
# The following blocks may be removed after applying the updated configuration
moved {
  from = module.runtime_connector.module.aws_secretsmgr[0].aws_iam_policy.this
  to   = module.secrets_manager_access.aws_iam_policy.this
}

moved {
  from = module.runtime_connector.aws_iam_role_policy_attachment.aws_secretsmgr_attach[0]
  to   = module.secrets_manager_access.aws_iam_role_policy_attachment.attach_secrets_manager_access[0]
}
```

### Refactoring the `aws/kinesis-firehose` Addon
If `aws/kinesis-firehose` is declared as an addon, update your configuration to add the `symopsio/kinesis-firehose-addon/aws` module explicitly.

For example, given this previous configuration:
```terraform
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = "~> 1.0"

  environment = var.environment

  addons = ["aws/kinesis-firehose"]
}
```

An updated configuration would be:

```terraform
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = "~> 2.0"

  environment = var.environment
}

module "kinesis_firehose_access" {
  source  = "symopsio/kinesis-firehose-addon/aws"
  version = "~> 1.1"

  environment = var.environment
  iam_role_name = module.runtime_connector.sym_runtime_connector_role.name
}
```

Optionally, we recommend using [`moved` configuration blocks](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring#moved-block-syntax)
to migrate your Terraform state, instead of replacing the existing IAM policies with new ones:
```terraform
# Note: These `moved` statements require terraform >= 1.3.0 (https://github.com/hashicorp/terraform/releases/tag/v1.3.0)
# The following blocks may be removed after applying the updated configuration
moved {
  from = module.runtime_connector.module.aws_kinesis_firehose[0].aws_iam_policy.this
  to   = module.kinesis_firehose_access.aws_iam_policy.this
}

moved {
  from = module.runtime_connector.aws_iam_role_policy_attachment.aws_kinesis_firehose_attach[0]
  to   = module.kinesis_firehose_access.aws_iam_role_policy_attachment.at tach_firehose_access[0]
}
```

### Refactoring the `aws/kinesis-data-stream` Addon
If `aws/kinesis-data-stream` is declared as an addon, update your configuration to add the `symopsio/kinesis-data-stream-addon/aws` module explicitly.

For example, given this previous configuration:
```terraform
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = "~> 1.0"

  environment = var.environment

  addons       = ["aws/kinesis-data-stream"]
  addon_params = {
    "aws/kinesis-data-stream" = {
       "stream_arns" = ["arn:aws:kinesis:*:111122223333:stream/my-stream"]
    }
  }
}
```

An updated configuration would be:

```terraform
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = "~> 2.0"

  environment = var.environment
}

module "kinesis_data_stream_access" {
  source  = "symopsio/kinesis-data-stream-addon/aws"
  version = "~> 1.1"

  environment   = var.environment
  stream_arns   = ["arn:aws:kinesis:*:111122223333:stream/my-stream"]
  iam_role_name = module.runtime_connector.sym_runtime_connector_role.name
}
```

Optionally, we recommend using [`moved` configuration blocks](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring#moved-block-syntax)
to migrate your Terraform state, instead of replacing the existing IAM policies with new ones:
```terraform
# Note: These `moved` statements require terraform >= 1.3.0 (https://github.com/hashicorp/terraform/releases/tag/v1.3.0)
# The following blocks may be removed after applying the updated configuration
moved {
  from = module.runtime_connector.module.aws_kinesis_data_stream[0].aws_iam_policy.this
  to   = module.kinesis_data_stream_access.aws_iam_policy.this
}

moved {
  from = module.runtime_connector.aws_iam_role_policy_attachment.aws_kinesis_data_stream_attach[0]
  to   = module.kinesis_data_stream_access.aws_iam_role_policy_attachment.attach_datastream_access[0]
}
```

## Removed Input: `custom_external_id`
This input is no longer supported, and the `external_id` of the AWS IAM Role declared by this module will always be a random UUID.

## Input `policy_arns` has been removed
This input is no longer supported, and any additional AWS IAM Policies should be attached directly to the AWS IAM Role output by the module.

For example, given this previous configuration:
```terraform
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = "~> 1.0"

  environment = var.environment

  policy_arns = [aws_iam_policy.example.arn]
}
```

An updated configuration would be:

```terraform
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = "~> 2.0"

  environment = var.environment
}

resource "aws_iam_role_policy_attachment" "iam_policy_attachment_example" {
  policy_arn = aws_iam_policy.example.arn
  role       = module.runtime_connector.sym_runtime_connector_role.name
}
```

## Removed Output: `account_id`
The `account_id` output has been removed. You may still access this information with the following data block:
```terraform
data "aws_caller_identity" "current" {}
data.aws_caller_identity.current.account_id
```

## Removed Output: `settings`
The `settings` output has been superseded by the new `sym_integration` output.

## New Output: `sym_integration`
Version 2.0.0 of the `runtime_connector` module now outputs a `sym_integration.runtime_context` by default. We recommend
using this integration instead of declaring one explicitly.

For example, given this previous configuration:
```terraform
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = "~> 1.0"

  environment = var.environment
}

resource "sym_integration" "runtime_context" {
  type        = "permission_context"
  name        = "runtime-${var.environment}"
  external_id = module.runtime_connector.settings.account_id

  settings = module.runtime_connector.settings
}

resource "sym_secrets" "this" {
  type = "aws_secrets_manager"
  name = "${var.environment}-secrets"

  settings = {
    context_id = sym_integration.runtime_context.id
  }
}
```

An updated configuration would be:
```terraform
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = "~> 2.0"

  environment = var.environment
}

resource "sym_secrets" "this" {
  type = "aws_secrets_manager"
  name = "${var.environment}-secrets"

  settings = {
    context_id = module.runtime_connector.sym_integration.id
  }
}
```

We recommend using [`moved` configuration blocks](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring#moved-block-syntax)
to migrate your Terraform state, instead of destroying and recreating your existing `sym_integration.runtime_context`:
```terraform
# Note: This `moved` statement requires terraform >= 1.3.0 (https://github.com/hashicorp/terraform/releases/tag/v1.3.0)
# This block may be removed after applying the updated configuration
moved {
  from = sym_integration.runtime_context
  to   = module.runtime_connector.sym_integration.runtime_context
}
```
## New Output: `sym_runtime`
Version 2.0.0 of the `runtime_connector` module now outputs a `sym_runtime.this` by default. We recommend using this
resource instead of declaring one explicitly.

For example, given this previous configuration:
```terraform
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = "~> 1.0"

  environment = var.environment
}

resource "sym_integration" "runtime_context" {
  type        = "permission_context"
  name        = "runtime-${var.environment}"
  external_id = module.runtime_connector.settings.account_id


  settings = module.runtime_connector.settings
}

resource "sym_runtime" "this" {
  name       = var.environment
  context_id = sym_integration.runtime_context.id
}

resource "sym_environment" "this" {
  name       = var.environment
  runtime_id = sym_runtime.this.id
}
```

An updated configuration would be:
```terraform
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = "~> 2.0"

  environment = var.environment
}

resource "sym_environment" "this" {
  name       = var.environment
  runtime_id = module.runtime_connector.sym_runtime.id
}
```

We recommend using [`moved` configuration blocks](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring#moved-block-syntax)
to migrate your Terraform state, instead of destroying and recreating your existing `sym_runtime`:
```terraform
# Note: This `moved` statement requires terraform >= 1.3.0 (https://github.com/hashicorp/terraform/releases/tag/v1.3.0)
# This block may be removed after applying the updated configuration
moved {
  from = sym_runtime.this
  to   = module.runtime_connector.sym_runtime.this
}
```
