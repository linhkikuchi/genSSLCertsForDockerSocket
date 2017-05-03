# genSSLCertsForDockerSocket
In order to protect docker socket with TLS, use this script to generate a self signed cert for docker host

Run the script 
`gencerts.sh 127.0.0.1,127.0.0.2,<docker-host-IP> <docker-host-name>`
