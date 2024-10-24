#!/bin/bash
set -e
sleep 60

# Met à jour le système
sudo apt-get update -y && sudo apt-get upgrade -y && apt install curl

# Installe Docker
sudo apt-get install -y docker.io

# Vérifie que Docker est bien installé
docker --version

# Installe Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Vérifie que Docker Compose est bien installé
docker-compose --version

# Crée un fichier docker-compose.yml pour déployer Nginx / Teampass 
cat <<EOF > docker-compose.yml
version: "3"
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    container_name: npm
    ports:
      - '80:80'   # Public HTTP Port
      - '443:443' # Public HTTPS Port
      - '81:81'   # Admin Web Port
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt  
    networks:
      npm_network:
        ipv4_address: 172.22.0.10

  teampass-web:
    image: dormancygrace/teampass:latest
    restart: unless-stopped
    volumes:
      - ./teampass-html:/var/www/html
    depends_on:
      - db
    networks:
      npm_network:
        ipv4_address: 172.22.0.11
  
  db:
    restart: unless-stopped
    image: yobasystems/alpine-mariadb:latest
    environment:
      MYSQL_ROOT_PASSWORD: "P@ssword2022"
      MYSQL_DATABASE: teampass
      MYSQL_PASSWORD: "P@ssword2022"
      MYSQL_USER: teampass
    volumes:
      - ./teampass-db:/var/lib/mysql
    networks:
      npm_network:
        ipv4_address: 172.22.0.12

networks:
  npm_network:
    external: true
EOF

# Lancement du service avec Docker Compose
sudo docker-compose up -d

# Affiche l'état des conteneurs Docker
sudo docker ps