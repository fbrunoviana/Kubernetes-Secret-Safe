## Kubernetes Secret Safe

### Criando o cluster
cd 00-createCluster
./create-cluster.sh

### Instalando o vault
cd ../01-vault/
./deploy_vault.sh
./vault_integrate_cluster.sh

### Instalando o external secrect
cd ../02-external-secrets/
./install_external_secrets.sh

### Examples
Explore os exemplos de como usar, via volume e via env.