variable "environment_name" {
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
