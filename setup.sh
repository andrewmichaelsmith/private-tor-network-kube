#!/bin/bash
set -x

### For da1, da2, da3
###
### 1. Create identify certs
### 2. Create keys
### 3. Create Deployment template
### 4. Create Service template
### 5. Create Service
### 6. Using certs (1), keys (2) and Service IP (5) add to da_list
### 7. Add da_list to torrc for EACH da
### 8. Create ConfigMaps for certs (1), keys (2), torrc (7)
### 9. Create da1, da2, da3 Deployment
### 10. Using da_list create torrc for relays
### 11. Create relay (1 deployment, scaled to multiple instances)
### 12. Create relay/hidden service


make_da () {
	name=$1
	mkdir -p $name
	cd $name

	#Need service now because we need IP address for da_list AND Address conig
	name=$name envsubst < ../da-svc-template.yml > da-svc.yml
	kubectl delete -f da-svc.yml
	kubectl create -f da-svc.yml
	ip=$( kubectl get -f da-svc.yml -o 'jsonpath={.spec.clusterIP}')


	#For --list-fignerpinrt
	cp ../torrc-base torrc

	sudo docker run -u $(id -u) --entrypoint=sh -v `pwd`:`pwd` --workdir=`pwd` -ti quay.io/andysmith/private-tor:latest \
	-c "echo password | tor-gencert --create-identity-key --passphrase-fd o"

	sudo docker run -u $(id -u) --entrypoint=tor -v `pwd`:`pwd` --workdir=`pwd` -ti quay.io/andysmith/private-tor:latest \
	--list-fingerprint --orport 1 --dirserver "x 127.0.0.1:1 ffffffffffffffffffffffffffffffffffffffff" --datadirectory .

	echo -e "\nNickname $name" >> torrc
	echo -e "\nAddress $ip" >> torrc
	cat ../torrc-da-base >> torrc
	name=$name envsubst < ../da-template.yml > da.yml

	../da_fingerprint $ip >> ../da_list
	cd ..

}

make_relay() {
	mkdir -p relay
	cd relay
	cp ../torrc-base torrc
	cat ../da_list >> torrc

	kubectl delete secret relay-torrc
	kubectl create secret generic relay-torrc --from-file torrc

	kubectl delete -f ../relay.yml
	kubectl create -f ../relay.yml

	cd ..
}

make_hs() {
	mkdir -p hs
	cd hs
	cp ../torrc-base torrc
	cat ../da_list >> torrc

	kubectl delete secret hs-torrc
	kubectl create secret generic hs-torrc --from-file torrc

	kubectl delete -f ../hs.yml
	kubectl create -f ../hs.yml

	cd ..
}


rm da_list

make_da da1
make_da da2
make_da da3


cat da_list >> da1/torrc
cat da_list >> da2/torrc
cat da_list >> da3/torrc

for name in da1 da2 da3
do
	#secrets cuz configmaps don't do binary
	kubectl delete secret $name-id
	kubectl delete secret $name-keys
	kubectl delete secret $name-torrc
	kubectl delete -f $name/da.yml

	kubectl create secret generic $name-id --from-file $name #TODO: this picks up torrc+other shit
	kubectl create secret generic $name-keys --from-file $name/keys
	kubectl create secret generic $name-torrc --from-file $name/torrc
	kubectl create -f $name/da.yml
done


make_relay

make_hs
