variable "name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_public_access_block" {
  type    = bool
  default = true
}

variable "enable_sse" {
  type    = bool
  default = true
}

variable "lifecycle_transition_days" {
  type    = number
  default = 30 # -> STANDARD_IA
}

variable "lifecycle_expiration_days" {
  type    = number
  default = 365 # expire after a year
}