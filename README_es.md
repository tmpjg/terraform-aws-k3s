# AWS K3s Terraform Module

A k3s "scalable" simple implementation on AWS EC2 with Terraform. 

## Requirements

### AWS Load Balancer Controller

Para que `aws_load_balancer_controller` funcione correctamente es necesario que las subnets estén tagueadas de la siguiente manera: 

**Subnets públicas**

```hcl
tags = {
    "Name" = "${var.environment}-${var.name}-public-${each.key}"
    "kubernetes.io/cluster/<CLUSTER_NAME>" = "shared" # tag elb eks
    "kubernetes.io/role/elb" = "1" # tag elb eks
}
```

**Subnets privadas**

```hcl
tags = {
    "Name" = "${var.environment}-${var.name}-private-${each.key}"
    "kubernetes.io/cluster/<CLUSTER_NAME>" = "shared" # tag elb eks
    "kubernetes.io/role/internal-elb" = "1" # tag elb eks
}
```

## Uso

```hcl
module "aws-k3s-<nombre>" {
  source = "tmpjg/k3s/aws"
  version = ""~> 1.0.0"

  name                      = "${var.environment}-${var.name}" # ${name}-k3s-master ${name}-k3s-node
  key_pair_name             = "sandbox"
  subnets_public_ids        = [aws_subnet.public["1a"].id,aws_subnet.public["1b"].id]
  subnets_private_ids       = [aws_subnet.private["1a"].id,aws_subnet.private["1b"].id]
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
  vpc_id                    = aws_vpc.main.id
  k3s_token                 = <CAMBIAR>
  k3s_version               = "v1.28.4+k3s1" # https://github.com/k3s-io/k3s/releases
  tags_additional           = {
    "tag_1" = "value1"
    "tag_2" = "value2"
  }
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

| Clave                        | Ejemplo                                                                 | Descripción |
|------------------------------|-------------------------------------------------------------------------|-------------|
| `name`                       | "${var.environment}-${var.name}"                                        | Nombre del cluster (y prefijo)|
| `key_pair_name`              | "dev-key-ssh"                                                           | Nombre de la llave ssh en AWS con la que se podra acceder a las instancias|
| `master_instance_type`       | "t3a.micro"                                                             | Tamaño de instancia Master |
| `master_volume_size`         | "10"                                                                    | Volumen del master (gb)|
| `master_ip`                  | "33.0.11.33"                                                            | IP del master (se utilizará la primer subnet de `subnets_private_ids`) |
| `master_taint`               | true/false                                                              | Activar/Desactivar Taint en master para evitar que se desplieguen pods en este. |
| `subnets_private_ids`        | ["subnet-01234567890abcdef","subnet-01234567890abcdef"]                 | IDs de subnets privadas para el cluster. |
| `subnets_public_ids`         | ["subnet-012345aa890abcdef","subnet-0123456aa90abcdef"]                 | IDs de subnets públicas para el cluster. |
| `nodes_instance_type`        | "t3a.medium"                                                            | Tamaño de los nodos (instancia).|
| `nodes_volume_size`          | "20"                                                                    | Volumen de los nodos (gb). |
| `nodes_autoscaling`          | `{ desired_capacity" = "1", "min_size" = "1", "max_size" = "2" }`       | Configuración del autoscaling de los nodos. |
| `vpc_id`                     | "vpc-01234567890abcdef"                                                 | ID de VPC del cluster |
| `k3s_token`                  | "Ex4mPL3"                                                               | Token interno que utiliza k3s para conectar nodos con el master.|
| `k3s_version`                | "v1.27.5+k3s1"                                                          | Versión de k3s a utilizar ([releases](https://github.com/k3s-io/k3s/releases)). |
| `tags_additional`            | {env=test, name=app, example=value}                                     | Tags adicionales para todos los recursos (map). |
| `k3s_iam_policy_extra`       | data.template_file.k3s_iam_policy_extra.rendered                        | JSON con IAM policy extra para el cluster |
| `suspended_processes_autoscalling` | ["Launch", "Terminate", ..., "InstanceRefresh"]                   | Suspender procesos de autoscalado ([referencia](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#suspended_processes)) |
