#variable for region
variable "myregion" {
  default = "ap-south-1"
}

#variable for vpc cidr
variable "vpc-cidr" {
  default = "10.10.0.0/16"
}

#variable for sub-1-public cidr
variable "sub-1-public-cidr" {
  default = "10.10.1.0/24"
}

#variable for sub-2-public cidr
variable "sub-2-public-cidr" {
  default = "10.10.2.0/24"
}

#variable for sub-1-public-az
variable "sub-1-public-az" {
  default = "ap-south-1a"
}

#variable for sub-2-public-az
variable "sub-2-public-az" {
  default = "ap-south-1b"
}



