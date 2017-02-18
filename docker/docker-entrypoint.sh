case ${1} in
	DA)
		mkdir -p /root/.tor/keys
		ln -s /id/authority_certificate /root/.tor/keys/authority_certificate
		ln -s /id/authority_identity_key /root/.tor/keys/authority_identity_key
		ln -s /id/authority_signing_key /root/.tor/keys/authority_signing_key
		ln -s /id/fingerprint /root/.tor/fingerprint
		ln -s /keys/ed25519_master_id_public_key /root/.tor/keys/ed25519_master_id_public_key
		ln -s /keys/ed25519_master_id_secret_key /root/.tor/keys/ed25519_master_id_secret_key
		ln -s /keys/ed25519_signing_cert /root/.tor/keys/ed25519_signing_cert
		ln -s /keys/ed25519_signing_secret_key /root/.tor/keys/ed25519_signing_secret_key
		ln -s /keys/secret_id_key /root/.tor/keys/secret_id_key
		ln -s /keys/secret_onion_key /root/.tor/keys/secret_onion_key
		ln -s /keys/secret_onion_key_ntor /root/.tor/keys/secret_onion_key_ntor
		;;
	RELAY)
		ip=$(ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
		echo -e "\nAddress $ip" >> /etc/tor/torrc
		;;
	HS)
		ip=$(ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
		echo -e "\nAddress $ip" >> /etc/tor/torrc
		echo -e "\nHiddenServiceDir /root/.tor/hs/" >> /etc/tor/torrc
		echo -e "\nHiddenServicePort 80 127.0.0.1:80" >> /etc/tor/torrc
		;;
	*)
		echo "Unexpected arg to $0"
		exit 1
		;;
esac		
exec tor
