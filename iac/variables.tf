variable "resource_group_name" {
  default = "rgtwcus0cloudresume1"
}
variable "region" {
  default = "centralus"
}
variable "resource_tags" {
  description = "Tags to set for all resources"
  type        = map(string)
  default = {
    Environment = "Terraform Getting Started"
    Team        = "DevOps"
  }
}