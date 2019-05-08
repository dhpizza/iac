
variable "prefix" {}
variable "azs" {
  type = "list"
  default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}
variable "instance_count" {
  default = 3
}
