variable "loc" {
  description = "Outfix: short Azure region code used in resource names (for example uks)."
  type        = string
  default     = "uks"
}

variable "short" {
  description = "Infix: short product code used in resource names."
  type        = string
  default     = "ldo"
}
