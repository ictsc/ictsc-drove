#!/bin/sh

if kubectl config get-contexts | grep argocd-repo-server >/dev/null; then
  echo "Context 'argocd-repo-server' already exists. Skipping user creation."
  exit 0
fi

openssl genrsa -out argocd-repo-server.key 2048
openssl req -new -key argocd-repo-server.key -out argocd-repo-server.csr -subj "/CN=argocd-repo-server"

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: argocd-repo-server-csr
spec:
  request: $(cat argocd-repo-server.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF
kubectl certificate approve argocd-repo-server-csr

kubectl get csr argocd-repo-server-csr -o jsonpath='{.status.certificate}' | base64 -d >argocd-repo-server.crt

kubectl config set-credentials argocd-repo-server --client-certificate=argocd-repo-server.crt --client-key=argocd-repo-server.key --embed-certs=true
kubectl config set-context argocd-repo-server --user=argocd-repo-server --cluster="$(kubectl config view --minify | yq ".clusters[0].name")"

kubectl apply -f cluster-role.yaml
kubectl apply -f cluster-role-binding.yaml
