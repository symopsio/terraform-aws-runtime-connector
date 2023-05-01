output "sym_runtime_connector_role_arn" {
  description = "The ARN of the AWS IAM Role that the Sym Runtime will assume to execute operations in your AWS account."
  value       = aws_iam_role.sym_runtime_connector_role.arn
}

output "sym_runtime_connector_role_name" {
  description = "The name of the AWS IAM Role to be assumed by the Sym Runtime to execute operations in your AWS account."
  value       = aws_iam_role.sym_runtime_connector_role.name
}

output "sym_runtime_connector_role_external_id" {
  description = "The STS External ID that must be provided by Sym when the Sym Runtime assumes the AWS IAM Role."
  value       = random_uuid.external_id.result
}

output "sym_integration_runtime_context_id" {
  description = "The ID of an Integration that tells the Sym Runtime which AWS Role to assume to perform actions in your AWS account. For example, this can be used in sym_runtime and sym_secrets resources."
  value       = sym_integration.runtime_context.id
}

output "sym_runtime_id" {
  description = "The ID of a sym_runtime resource to be passed into your sym_environment to enable the execution of AWS Strategies."
  value       = sym_runtime.this.id
}
