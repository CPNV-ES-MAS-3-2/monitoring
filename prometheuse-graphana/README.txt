
mkdir -p ~/prometheus
cd ~/prometheus
sudo nano docker-compose.yml
	**mettre contenus du docker-compose**
sudo nano prometheus.yml
	**metrte contenus de preometheus.yml**


sudo docker compose up -d

docker ps

---------------------

accès


http://IP_MACHINE:3000

user: admin
password: admin

-----------------------------

connecter prometheus a graphafa:

graphana: connections>data source add

choisir prmetheus

url: http://prometheus:9090

Save & Test
--------------------------------------

Ajouter un dashboard prêt à l’emploi

graphana>dashboard>new Dashboard

import a Dashboard

id: 1860
 dashboard officiel Node Exporter Full.



