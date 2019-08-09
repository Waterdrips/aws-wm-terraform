variable "cluster-name" {
  default = "demo-ecs-terraform-cluster"
}

variable "region" {
  default = "eu-west-1"
}

variable "environment_name" {
  default = "demo"
}

variable "app_host_port" {
    default = "80"
}

variable "app_container_port" {
    default = "80"
}

variable "app_image" {
    default = "nginx"
}

variable "app_tag" {
  default = "latest"
}

variable "vpc_cidr_prefix" {
  default = "10.100"
}

variable "az_count" {
  default = "2"
}

variable "availability_zones" {
  default = {
    eu-west-1 = "eu-west-1a,eu-west-1b"
  }

}