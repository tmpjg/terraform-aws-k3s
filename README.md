
# AWS K3s Terraform Module

A simple and scalable k3s implementation on AWS EC2 using Terraform.

The nodes are deployed on private subnets.

## Requirements

### AWS Load Balancer Controller

For the `aws_load_balancer_controller` to work correctly, subnets must be tagged as follows:

**Public Subnets**

```hcl
tags = {
    "Name" = "subnet-public"
    "kubernetes.io/cluster/<CLUSTER_NAME>" = "shared" # tag elb eks
    "kubernetes.io/role/elb" = "1" # tag elb eks
}
```

**Private Subnets**

```hcl
tags = {
    "Name" = "subnet-private"
    "kubernetes.io/cluster/<CLUSTER_NAME>" = "shared" # tag elb eks
    "kubernetes.io/role/internal-elb" = "1" # tag elb eks
}
```

## Usage

```hcl
module "aws-k3s" {
  source = "tmpjg/k3s/aws"
  version = "~> 1.0.0"
  name                      = "<CLUSTER_NAME>" # ${name}-k3s-master ${name}-k3s-node
  key_pair_name             = "<SSH_KEY_NAME>"
  subnets_public_ids        = [<AWS_SUBNET_PUBLIC_ID_1>,<AWS_SUBNET_PUBLIC_ID_2>]
  subnets_private_ids       = [<AWS_SUBNET_PRIVATE_ID_1>,<AWS_SUBNET_PRIVATE_ID_2>]
  master_instance_type      = "t3a.small"
  master_volume_size        = "10"
  master_ip                 = "33.0.11.33"
  master_taint              = true
  nodes_instance_type       = "t3a.medium"
  nodes_volume_size         = "30"
  nodes_autoscaling         = {
    "desired_capacity" = "2",
    "min_size"         = "1",
    "max_size"         = "2"
  }
  vpc_id                    = "<AWS_VPC_ID>"
  k3s_token                 = "<RANDOM_TOKEN>"
  k3s_version               = "<K3S_VERSION>" 
  #tags_additional           = {
  #  "tag_1" = "value1"
  #  "tag_2" = "value2"
  #}
  #k3s_iam_policies_extra_arns = [""]
  #suspended_processes_autoscalling = ["Launch", "Terminate", "HealthCheck", "ReplaceUnhealthy", "AZRebalance", "AlarmNotification", "ScheduledActions", "AddToLoadBalancer", "InstanceRefresh"]
}

#data "template_file" "k3s_iam_policy_extra" {
#  template = "${file("${path.module}/k3s_iam_policy_extra.tpl")}"
#  vars = {
#    TEST = "teest"
#  }
```

## Variables

| Key                          | Example                                                                 | Description |
|------------------------------|-------------------------------------------------------------------------|-------------|
| `name`                       | "example_name"                                                          | Cluster name (and prefix) |
| `key_pair_name`              | "ssh_key_name"                                                          | AWS SSH key name used to access instances |
| `master_instance_type`       | "t3a.micro"                                                             | Master instance type |
| `master_volume_size`         | "10"                                                                    | Master volume size (GB) |
| `master_ip`                  | "33.0.11.33"                                                            | Master IP (uses the first subnet from `subnets_private_ids`) |
| `master_taint`               | true/false                                                              | Enable/Disable Taint on master to prevent pod scheduling |
| `subnets_private_ids`        | ["subnet-01234567890abcdef","subnet-01234567890abcdef"]                 | Private subnet IDs for the cluster |
| `subnets_public_ids`         | ["subnet-012345aa890abcdef","subnet-0123456aa90abcdef"]                 | Public subnet IDs for the cluster |
| `nodes_instance_type`        | "t3a.medium"                                                            | Node instance type |
| `nodes_volume_size`          | "20"                                                                    | Node volume size (GB) |
| `nodes_autoscaling`          | `{ desired_capacity" = "1", "min_size" = "1", "max_size" = "2" }`       | Node autoscaling configuration |
| `vpc_id`                     | "vpc-01234567890abcdef"                                                 | Cluster VPC ID |
| `k3s_token`                  | "change_me_example_token"                                               | Internal token used by k3s to connect nodes with the master |
| `k3s_version`                | "v1.27.5+k3s1"                                                          | k3s version to use ([releases](https://github.com/k3s-io/k3s/releases)) |
| `tags_additional`            | {env=test, name=app, example=value}                                     | Additional tags for all resources (map) |
| `k3s_iam_policy_extra`       | data.template_file.k3s_iam_policy_extra.rendered                        | JSON with extra IAM policy for the cluster |
| `suspended_processes_autoscalling` | ["Launch", "Terminate", ..., "InstanceRefresh"]                   | Suspend autoscaling processes ([reference](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#suspended_processes)) |
