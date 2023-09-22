variable "region" {
  type    = string
  default = "eu-west-3"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "subnet1_cidr" {
  type    = string
  default = "10.20.1.0/24"
}

variable "subnet2_cidr" {
  type    = string
  default = "10.20.2.0/24"
}

variable "subnet3_cidr" {
  type    = string
  default = "10.20.3.0/24"
}

variable "subnet4_cidr" {
  type    = string
  default = "10.20.4.0/24"
}

variable "az1" {
  type    = string
  default = "us-west-3a"
}

variable "az2" {
  type    = string
  default = "us-west-3b"
}

variable "ami" {
  type    = string
  default = "ami-04a7352d22a23c770"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "db_instance_type" {
  type    = string
  default = "db.t3.micro"
}
