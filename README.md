# Private Tor Network on Kubernetes

## Dependencies

- a kubernetes cluster (tested against 1.6)
- kubectl configured to point at the cluster + namespace at that cluster
- docker client/server available (we use a docker conatiner to generate the keys)

## Set up

- ./setup.sh 

## Use

Exposes a remote relay locally for use over SOCKS:

- ./use.sh
- curl --socks5 localhost:9050 https://github.com
- curl --socks5-hostname localhost:9050 $(./findhs.sh)

Point arm at a relay:

- ./use-arm.sh
- arm #password is "password"

## Sources

Based on [antitree/private-tor-network](https://github.com/antitree/private-tor-network)
