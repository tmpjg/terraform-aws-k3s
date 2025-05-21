################
#### master #### 
################

data "template_file" "k3s_master" {
  template = "${file("${path.module}/ec2_data/ec2_user_data_k3s_master.sh")}"
  vars = {
    MASTER_TOKEN = var.k3s_token
    CLUSTER_NAME = "${var.name}"
    MASTER_TAINT = var.master_taint 
    K3S_VERSION  = var.k3s_version
  }
}

resource "aws_instance" "k3s_master" {
  ami = var.ami_debian_id
  instance_type = var.master_instance_type
  key_name = var.key_pair_name
  user_data = data.template_file.k3s_master.rendered
  iam_instance_profile = aws_iam_instance_profile.k3s_instance_profile.name
  disable_api_termination = true
  network_interface {
    network_interface_id = aws_network_interface.k3s_master.id
    device_index = 0
  }
  root_block_device {
    volume_type           = "gp3"
    volume_size           = "${var.master_volume_size}"
    delete_on_termination = "true"
    tags = {
      Name    = "${var.name}-k3s-master"
    }
  }
  tags = merge(
    var.tags_additional,
      {
        Name = "${var.name}-k3s-master"
        "kubernetes.io/cluster/${var.name}" = "owned"
      },
  )
}

resource "aws_network_interface" "k3s_master" {
  subnet_id = var.subnets_private_ids[0]
  source_dest_check = false
  private_ips = [var.master_ip]
  security_groups = [aws_security_group.k3s.id]

  tags = merge(
    var.tags_additional,
      {
        Name = "${var.name}-k3s-master"
      },
  )
}

