variable "environment" {
  description = "The unique name of the environment in which you are deploying this Sym Runtime Role. (e.g. staging, or prod)"
  type        = string
}

variable "sym_account_id" {
  description = "The AWS account ID that can assume the Sym Runtime Role. Defaults to the Sym Production AWS account ID."
  type        = string
  default     = "803477428605"
}

variable "tags" {
  description = "Additional tags to apply to the AWS resources"
  type        = map(string)
  default     = {}
}

variable "account_id_safelist" {
  description = "List of additional AWS account IDs (beyond the current AWS account) that the Sym Runtime Role can assume roles in. (e.g. The SSO Management Account ID)"
  type        = list(string)
  default     = []
}
