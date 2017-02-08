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
### 9. Create Deployment


make_da () {
	name=$1

	echo "making name $name"
	mkdir -p $name
	cd $name

	#Need service now because we need IP address for da_list AND Address conig
	name=$name envsubst < ../da-svc-template.yml > da-svc.yml
	kubectl -s http://192.168.122.254:8080 delete -f da-svc.yml
	kubectl -s http://192.168.122.254:8080 create -f da-svc.yml
	ip=$( kubectl -s http://192.168.122.254:8080 get -f da-svc.yml -o 'jsonpath={.spec.clusterIP}')


	#For --list-fignerpinrt
	cp ../torrc-base torrc

	sudo docker run -u $(id -u) --entrypoint=sh -v `pwd`:`pwd` --workdir=`pwd` -ti quay.io/andysmith/tor-relay:0.2.8.12 \
	-c "echo password | tor-gencert --create-identity-key --passphrase-fd o"

	sudo docker run -u $(id -u) -v `pwd`:`pwd` --workdir=`pwd` -ti quay.io/andysmith/tor-relay:0.2.8.12 \
	--list-fingerprint --orport 1 --dirserver "x 127.0.0.1:1 ffffffffffffffffffffffffffffffffffffffff" --datadirectory .

	echo -e "\nNickname $name" >> torrc
	echo -e "\nAddress $ip" >> torrc
	cat ../torrc-da-base >> torrc
	name=$name envsubst < ../da-template.yml > da.yml

	../da_fingerprint $ip >> ../da_list
	cd ..

}

make_relay() {
	cd relay
	cp ../torrc-base torrc
	cat ../da_list >> torrc

	kubectl -s http://192.168.122.254:8080 delete secret generic relay-torrc
	kubectl -s http://192.168.122.254:8080 create secret generic relay-torrc --from-file torrc

	kubectl -s http://192.168.122.254:8080 delete -f relay.yml
	kubectl -s http://192.168.122.254:8080 create -f relay.yml

	cd ..
}
	
	

##Hack until we bake it in
kubectl -s http://192.168.122.254:8080 delete configmap tor-entry
kubectl -s http://192.168.122.254:8080 create configmap tor-entry --from-file docker-entrypoint.sh

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
	kubectl -s http://192.168.122.254:8080 delete secret $name-id
	kubectl -s http://192.168.122.254:8080 delete secret $name-keys
	kubectl -s http://192.168.122.254:8080 delete secret $name-torrc
	kubectl -s http://192.168.122.254:8080 delete -f $name/da.yml

	kubectl -s http://192.168.122.254:8080 create secret generic $name-id --from-file $name #TODO: this picks up torrc+other shit
	kubectl -s http://192.168.122.254:8080 create secret generic $name-keys --from-file $name/keys
	kubectl -s http://192.168.122.254:8080 create secret generic $name-torrc --from-file $name/torrc
	kubectl -s http://192.168.122.254:8080 create -f $name/da.yml
done


make_relay
