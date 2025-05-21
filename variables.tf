#### General

variable "name" {
    description = "ej: uat-example"
    type        = string
}

variable "k3s_token" {
  type = string
}

#### Network

variable "vpc_id" {
    description = "vpc id"
    type    = string
}


variable "subnets_private_ids" {
    description = "subnets ids private"
    type        = list(string)
}

variable "subnets_public_ids" {
    description = "subnets ids public"
    type        = list(string)
}

#### Variables

variable "key_pair_name" {
    description = "ssh key pair name for nodes and master."
    type        = string
}

variable "ami_debian_id" {
    description = "ami debian for nodes and master"
    type        = string
    default     = "ami-06885bf4009501fc0"
}

variable "k3s_version" {
    description = "k3s version https://github.com/k3s-io/k3s/releases"
    type        = string
}

variable "tags_additional" {
  default     = {}
  description = "Additional resource tags"
  type        = map(string)
}

variable "k3s_iam_policies_extra_arns" {
    description = "list of extra arns policies"
    type        = list(string)
    default = []
}


#### Master

variable "master_instance_type" {
    description = "Size instance."
    type        = string
    default     = "t3a.micro"
}

variable "master_volume_size" {
    description = "Size volume GB."
    type        = string
    default     = "10"
}

variable "master_ip" {
    description = "ip master node"
    type        = string
}

variable "master_taint" {
    description = "evict pods on master"
    type        = bool
    default     = true
}

#### Nodes

variable "nodes_instance_type" {
    description = "Size instance."
    type        = string
    default     = "t3a.medium"
}

variable "nodes_volume_size" {
    description = "Size volume GB."
    type        = string
    default     = "10"
}

variable "nodes_autoscaling" {
  description = "Node autoscalling map values."
  type = map
  default = {
    "desired_capacity"  = "1"
    "min_size"          = "1"
    "max_size"          = "2"
  }
}

variable "suspended_processes_autoscalling" {
    description = "list of suspended process of autoscalling"
    type        = list(string)
    default = []
}

