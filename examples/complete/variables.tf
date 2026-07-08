variable "enable_flexible_federated_credentials" {
  description = <<-DESC
    Whether to create the flexible federated identity credential. Off by default because it is a
    Microsoft Entra preview feature and the live self-test should not depend on a preview toggle.
  DESC
  type        = bool
  default     = false
}

variable "grant_admin_consent" {
  description = <<-DESC
    Whether to actually grant tenant-wide admin consent for the requested Microsoft Graph
    permissions (app role assignments and delegated grants). Left false by default: granting
    consent needs elevated Graph permissions (AppRoleAssignment.ReadWrite.All,
    Directory.ReadWrite.All) that a plain Application.ReadWrite CI principal does not hold, so the
    self-test requests the permissions without consenting. Set true when running as a principal
    that can consent.
  DESC
  type        = bool
  default     = false
}

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
