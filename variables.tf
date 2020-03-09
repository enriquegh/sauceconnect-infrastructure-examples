variable "region" {
  default = "us-west-2"
}

variable "amis" {
  type = map(string)
  default = {
    "us-east-1" = "ami-07ebfd5b3428b6f4d"
    "us-west-2" = "ami-0d1cd67c26f5fca19"
  }
}

variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
}