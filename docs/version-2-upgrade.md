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
  - [Module Version Configuration](#module-version-configuration)
  - [Removed Inputs: `addons` and `addon_params`](#removed-inputs-addons-and-addonparams)
    - [Refactoring the `aws/secretsmgr` Addon](#refactoring-the-awssecretsmgr-addon) 
    - [Refactoring the `aws/kinesis-firehose` Addon](#refactoring-the-awskinesis-firehose-addon) 
    - [Refactoring the `aws/kinesis-data-stream` Addon](#refactoring-the-awskinesis-data-stream-addon) 
  - [Removed Input: `custom_external_id`](#removed-input-customexternalid)
  - [Removed Output: `account_id`](#removed-output-accountid)
  - [Removed Output: `settings`](#removed-output-settings)
  - [New output: `sym_integration`](#new-output-symintegration)
  - [New output: `sym_runtime`](#new-output-symruntime)

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

Optionally, we recommend using `moved` configuration blocks to migrate your Terraform state, instead of replacing the existing IAM policies with new ones:
```terraform
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

Optionally, we recommend using `moved` configuration blocks to migrate your Terraform state, instead of replacing the existing IAM policies with new ones:
```terraform
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

Optionally, we recommend using `moved` configuration blocks to migrate your Terraform state, instead of replacing the existing IAM policies with new ones:
```terraform
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
  version = "~> 1.0"

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

We recommend using `moved` configuration blocks to migrate your Terraform state, instead of destroying and recreating your existing `sym_integration.runtime_context`:
```terraform
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
  version = "~> 1.0"

  environment = var.environment  
}

resource "sym_environment" "this" {
  name       = var.environment
  runtime_id = module.runtime_connector.sym_runtime.id
}
```

We recommend using `moved` configuration blocks to migrate your Terraform state, instead of destroying and recreating your existing `sym_runtime`:
```terraform
# This block may be removed after applying the updated configuration
moved {  
  from = sym_runtime.this  
  to   = module.runtime_connector.sym_runtime.this  
}
```
