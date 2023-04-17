variable "env" {}
variable "subnet_ids" {}
variable "vpc_id" {}
variable "host_instance_type" {}
variable "bastion_cidr" {}
variable "component" {
    default = "rabbitmq"
}