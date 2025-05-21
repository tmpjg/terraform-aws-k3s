########################
#### security group ####
########################

resource "aws_security_group" "k3s" {
  name = "${var.name}-k3s"
  description = "Security group for k3s"
  vpc_id = var.vpc_id

  ingress = [
    {
      description = "Allow all k3s"
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = true
    }
  ]
  
  egress = [
    {
      description = "Default egress"
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = true
    }
  ]
  
  tags = merge(
    var.tags_additional,
      {
        "kubernetes.io/cluster/${var.name}" = "owned"
      },
    )
  
  lifecycle {
    ignore_changes = [ ingress,egress ]
  }
}


