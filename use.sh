#!/bin/bash
set -ex

relay=$(kubectl get pods --selector=app=tor-relay -o name | sort -R | head -n 1)
relay=${relay:4}
kubectl port-forward $relay 9050:9050

