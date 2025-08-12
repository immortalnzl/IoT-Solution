# IoT-Solutions

Client-template-mqtt v0.1 is a repo for building a client from scratch automatically. The docker stack includes: 
Telegraf
InfuxDB
Grafana
mqtt(maybe not required)

Prereq - 
Docker
Docker Compose
Docker engine.


This is a work in progress. 

1. Clone repo into VM/CT
2. chmod +x client-template.sh
3. ./client-template.sh

This will ask for the clients name then auto generate a token, then run the docker compose.

TO-DO
Authentication (0Auth) whichever has best apis for genratration of login 2fa
Tailscale? this is more for the gateway not really for the software stack.
Front end/Login
reporting

