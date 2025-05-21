#!/bin/bash

# hostname
export HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/local-hostname)
sudo hostnamectl set-hostname $HOSTNAME

#####################
######## K3S ########
#####################

#k3s master
sudo curl -sfL https://get.k3s.io | K3S_TOKEN=${MASTER_TOKEN} INSTALL_K3S_VERSION=${K3S_VERSION} sh -s - server \
    --disable-cloud-controller \
    --disable servicelb \
    --disable traefik \
    --node-name="$(hostname -f)" \
    --write-kubeconfig-mode=644 \
    --kubelet-arg="cloud-provider=external" \
    --kubelet-arg="provider-id=aws:///$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)/$(curl -s http://169.254.169.254/latest/meta-data/instance-id)" 


# Espera a que K3s esté completamente instalado antes de continuar
while [ ! -f /etc/rancher/k3s/k3s.yaml ]; do sleep 1; done
return=1
while [ $return != 0 ]; do
  sleep 2
  kubectl get nodes $(hostname -f) 2>&1 >/dev/null
  return=$?
done


# no usar master para pods 

if [ ${MASTER_TAINT} = true ]; then
    kubectl taint node $(hostname -f) node-role.kubernetes.io/master:NoSchedule
  else
    echo "No taint"
fi



########################
##### install helm #####
########################

sudo curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
sudo chmod 700 get_helm.sh
sudo ./get_helm.sh

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

##############################################
######## AWS CLOUD CONTROLLER MANAGER ########
##############################################

helm upgrade --install aws-cloud-controller-manager \
	https://github.com/kubernetes/cloud-provider-aws/releases/download/helm-chart-aws-cloud-controller-manager-0.0.7/aws-cloud-controller-manager-0.0.7.tgz \
	--namespace kube-system \
	--set hostNetworking=true \
	--set-string nodeSelector."node-role\.kubernetes\.io/master"=true \
	--set-string nodeSelector."node-role\.kubernetes\.io/control-plane"=true \
	--set args[0]="--v=2" \
    --set args[1]="--cloud-provider=aws" \
    --set args[2]="--configure-cloud-routes=false"


########################################
######## install ebs csi driver ########
########################################

helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update
helm upgrade --install aws-ebs-csi-driver \
    --namespace kube-system \
    aws-ebs-csi-driver/aws-ebs-csi-driver

## storage class gp3

cat <<EOF >> storage-class.yaml 
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
parameters:
  fsType: ext4
  type: gp3
  tagSpecification_1: "pvc_namespace={{ .PVCNamespace }}"
  tagSpecification_2: "pvc_name={{ .PVCName }}"
  tagSpecification_3: "pv_name={{ .PVName }}"
  tagSpecification_4: "cluster-name=${CLUSTER_NAME}"
  tagSpecification_5: "Name=${CLUSTER_NAME}-{{ .PVCName }}-{{ .PVName }}"
provisioner: kubernetes.io/aws-ebs
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowedTopologies:
- matchLabelExpressions:
  - key: failure-domain.beta.kubernetes.io/zone
    values:
    - us-east-1a
    - us-east-1b
EOF

kubectl apply -f storage-class.yaml

########################################
######## install aws lb manager ########
########################################

helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=${CLUSTER_NAME}

##################################
######## cron autoscaling ########
##################################

sudo echo "*/5 * * * * root for i in \$(kubectl get nodes | grep NotReady | awk {'print \$1'}); do kubectl delete node \$i; done" >> /etc/crontab

#### Banner

sudo cat <<EOT >> /etc/update-motd.d/90-banner-custom
#!/bin/sh
cat << EOF
############################
######## K3S MASTER ########
############################

#### path cert Kubernets

- /etc/rancher/k3s/k3s.yaml 

#### taint master (no pods on master)

kubectl taint node $(hostname -f) node-role.kubernetes.io/master:NoSchedule

EOF

EOT

sudo chmod 755 /etc/update-motd.d/90-banner-custom
