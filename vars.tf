variable "env" {}
variable "subnet_ids" {}
variable "vpc_id" {}
variable "bastion_cidr" {}
variable "allow_cidr" {}
variable "component" {
    default = "rabbitmq"
}