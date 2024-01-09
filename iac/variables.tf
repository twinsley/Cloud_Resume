variable "resource_group_name" {
  default = "rg"
}
variable "storage_account_name" {
  default = "st"
}
variable "vnet_prefix" {
  default = "vnet"
}
variable "project_name" {
  default = "twcus0cloudresume1"
}
variable "region" {
  default = "centralus"
}
variable "resource_tags" {
  description = "Tags to set for all resources"
  type        = map(string)
  default = {
    Environment = "Prod"
    Team        = "DevOps"
    Project     = "Cloud Resume Challenge"
  }
}