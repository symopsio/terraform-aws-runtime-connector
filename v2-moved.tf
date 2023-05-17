moved {
  from = aws_iam_role.this
  to   = aws_iam_role.sym_runtime_connector_role
}

moved {
  from = aws_iam_role_policy_attachment.assume_roles_attach
  to   = aws_iam_role_policy_attachment.attach_assume_roles
}
