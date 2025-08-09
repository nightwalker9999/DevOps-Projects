variable "name" { type = string }
variable "dlq_name" { type = string }
variable "visibility_timeout_secs" { type = number }
variable "message_retention_secs"  { type = number }
variable "tags" { type = map(string) default = {} }
