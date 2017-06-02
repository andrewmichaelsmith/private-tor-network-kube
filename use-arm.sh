#!/bin/bash
set -ex

relay=$(kubectl get pods --selector=app=tor-relay -o name | sort -R | head -n 1)
relay=${relay:5}
kubectl port-forward $relay 9051:9051

