# Private Tor Network on Kubernetes

## Dependencies

- kubectl configured to point at the cluster + namespace you want
- docker client/server available (we need to generate the keys 

## Set up

- ./setup.sh 

## Use

Exposes a remote relay locally for use over SOCKS:

- ./use.sh
- curl --socks5 localhost:9050 https://github.com
- curl --socks5-hostname localhost:9050 $(./findhs.hs)

Point arm at a relay:

- ./use-arm.sh
- arm #password is "password"

## Sources

Based on [antitree/private-tor-network](https://github.com/antitree/private-tor-network)
