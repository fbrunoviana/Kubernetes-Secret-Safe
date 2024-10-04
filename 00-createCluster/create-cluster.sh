#!/bin/bash
set -euo pipefail

# Constants
KUBERNETES_VERSION="${KUBERNETES_VERSION:-1.30}"
KIND_VERSION="0.22.0"
KIND_BINARY_URL="https://github.com/kubernetes-sigs/kind/releases/download/v${KIND_VERSION}/kind-linux-amd64"
KUBECTL_URL="https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
HELM_SCRIPT_URL="https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3"

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    tput setaf "$color"
    echo -e "\n*******************************************************************************************************************"
    echo -e "$message"
    echo -e "*******************************************************************************************************************"
    tput sgr0
}

# Function to install a binary
install_binary() {
    local name=$1
    local url=$2
    local dest=$3

    print_message 5 "Installing $name"
    curl -sSLo "./$name" "$url"
    chmod +x "./$name"
    sudo mv "./$name" "$dest"
    print_message 3 "$name installation complete"
}

# Install KinD
if ! command -v kind &> /dev/null; then
    install_binary "kind" "$KIND_BINARY_URL" "/usr/bin/kind"
fi

# Install kubectl
if ! command -v kubectl &> /dev/null; then
    install_binary "kubectl" "$KUBECTL_URL" "/usr/local/bin/kubectl"
fi

# Install Helm3 and jq
print_message 5 "Installing Helm3 and jq"
curl -sSL "$HELM_SCRIPT_URL" | bash
sudo apt update && sudo apt install -y snapd
sudo snap install jq --classic

# Create KinD cluster
print_message 5 "Creating KinD Cluster using cluster01-kind.yaml configuration - Using the v${KUBERNETES_VERSION}.0 Image"

KIND_IMAGE=""
case "$KUBERNETES_VERSION" in
    "1.30") KIND_IMAGE="kindest/node:v1.30.0@sha256:047357ac0cfea04663786a612ba1eaba9702bef25227a794b52890dd8bcd692e" ;;
    "1.29") KIND_IMAGE="kindest/node:v1.29.2@sha256:51a1434a5397193442f0be2a297b488b6c919ce8a3931be0ce822606ea5ca245" ;;
    "1.28") KIND_IMAGE="kindest/node:v1.28.0@sha256:b7a4cad12c197af3ba43202d3efe03246b3f0793f162afb40a33c923952d5b31" ;;
    *) echo "Unsupported Kubernetes version: $KUBERNETES_VERSION" && exit 1 ;;
esac

kind create cluster --name cluster01 --config cluster01-kind.yaml --image "$KIND_IMAGE"

# Configure cluster
print_message 5 "Configuring cluster"
kubectl label node cluster01-worker ingress-ready=true

print_message 5 "Installing Calico"
kubectl create -f calico/tigera-operator.yaml
kubectl create -f calico/custom-resources.yaml

print_message 5 "Installing NGINX Ingress Controller"
kubectl create -f nginx-ingress/nginx-deploy.yaml

# Print cluster information
HOST_IP=$(hostname -I | cut -f1 -d' ')
print_message 7 "Cluster Creation Complete. Please see the summary below for key information:"
echo -e "Your Kind Cluster Information:\n"
echo -e "Ingress Domain: $HOST_IP.nip.io\n"
echo -e "Ingress rules will need to use the IP address of your Linux Host in the Domain name\n"
echo -e "Example:  You have a web server you want to expose using a host called ordering."
echo -e "          Your ingress rule would use the hostname: ordering.$HOST_IP.nip.io"