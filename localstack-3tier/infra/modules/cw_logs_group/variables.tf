variable "name" {
  type        = string
  description = "Name of the CloudWatch Logs Group"
}

variable "retention_in_days" {
  type        = number
  description = "Number of days to retain logs"
  default     = 7
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the CloudWatch Logs Group"
  default     = {}
}
