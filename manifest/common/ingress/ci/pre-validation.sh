#!/bin/sh

kubectl apply -f https://raw.githubusercontent.com/cert-manager/cert-manager/refs/heads/master/deploy/crds/crd-certificates.yaml
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik-helm-chart/refs/heads/master/traefik/crds/traefik.io_ingressroutes.yaml
