################
#### nodes #####
################

data "template_file" "k3s_node" {
  template = "${file("${path.module}/ec2_data/ec2_user_data_k3s_node.sh")}"
  vars = {
    MASTER_TOKEN = var.k3s_token
    MASTER_IP = aws_network_interface.k3s_master.private_ip
    K3S_VERSION  = var.k3s_version
  }
}

resource "aws_launch_template" "k3s_node" {
  name = "${var.name}-k3s-node"
  description = "${var.name}-k3s-node Launch Template"
  image_id = var.ami_debian_id 
  instance_type = var.nodes_instance_type
  iam_instance_profile {
      arn = aws_iam_instance_profile.k3s_instance_profile.arn
  }
  vpc_security_group_ids = [aws_security_group.k3s.id]
  key_name = var.key_pair_name
  user_data = base64encode(data.template_file.k3s_node.rendered)
  ebs_optimized = true
  update_default_version = true
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
          volume_size = var.nodes_volume_size
          delete_on_termination = true
          volume_type = "gp3" 
    }
  }
  monitoring {
    enabled = true
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.name}-k3s-node"
    }
  }
  tag_specifications {
    resource_type = "instance"
    tags = merge(
    var.tags_additional,
      {
        "kubernetes.io/cluster/${var.name}" = "owned"
      },
    )  
  }
}


resource "aws_autoscaling_group" "k3s_node" {
    name                      = "${var.name}-k3s-node"
    vpc_zone_identifier       = var.subnets_private_ids 
    launch_template {
        id      = aws_launch_template.k3s_node.id
        version = aws_launch_template.k3s_node.latest_version
    }
    desired_capacity          = var.nodes_autoscaling["desired_capacity"]
    min_size                  = var.nodes_autoscaling["min_size"]
    max_size                  = var.nodes_autoscaling["max_size"]
    health_check_grace_period = 300
    health_check_type         = "EC2"
    suspended_processes       = var.suspended_processes_autoscalling
    tag {
      key                 = "Name"
      value               = "${var.name}-k3s-node"
      propagate_at_launch = true
    }
    tag {
      key                 = "kubernetes.io/cluster/${var.name}"
      value               = "owned"
      propagate_at_launch = true
    }
    tag {
      key                 = "k8s.io/cluster-autoscaler/${var.name}"
      value               = "owned"
      propagate_at_launch = true
    }
    tag {
      key                 = "k8s.io/cluster-autoscaler/enabled"
      value               = "1"
      propagate_at_launch = true
    }
    dynamic "tag" {
    for_each = var.tags_additional
    content {
      key                 = tag.key
      propagate_at_launch = true
      value               = tag.value
    }
  }
}
