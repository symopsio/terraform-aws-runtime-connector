output "sym_runtime_connector_role" {
  description = "An [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) resource. This AWS IAM Role will be assumed by the Sym Runtime to execute operations in your AWS account."
  value = aws_iam_role.sym_runtime_connector_role
}

output "sym_integration" {
  description = "A [sym_integration](https://registry.terraform.io/providers/symopsio/sym/latest/docs/resources/integration) resource that tells the Sym Runtime which AWS Role to assume to perform actions in your AWS account. For example, this can be used in sym_runtime and sym_secrets resources."
  value       = sym_integration.runtime_context
}

output "sym_runtime" {
  description = "A [sym_runtime](https://registry.terraform.io/providers/symopsio/sym/latest/docs/resources/runtime) resource to be passed into your sym_environment to enable the execution of AWS Strategies."
  value       = sym_runtime.this
}
