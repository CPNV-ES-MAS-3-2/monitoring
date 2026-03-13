# Déploiement du Serveur de Monitoring (Prometheus & Grafana)

Ce guide détaille le déploiement du serveur de monitoring utilisant **Prometheus** pour la réception des données et **Grafana** pour la visualisation, avec un reverse-proxy **Nginx**.

## Configuration de l'environnement
### Monter le repertoire
``` Bash
sudo mkdir /mnt/monitoring
sudo mkfs.ext4 /dev/nvme1n1
sudo mount /dev/nvme1n1 /mnt/monitoring
cd /mnt/monitoring
```

### Configurer la persistence du repertoire
``` Bash
## Recuperer uuid
sudo blkid /dev/nvme1n1
 
sudo nano /etc/fstab
## Ajouter dans le fstab :
UUID=<mnt_uuid> /mnt/monitoring ext4 defaults 0 2
```

### Installation de Docker
``` Bash
## Télécharger le script
wget https://raw.githubusercontent.com/CPNV-ES-MAS-3-2/monitoring/develop/server/setup_docker.sh

## Configuration des droits d'éxecution
sudo chmod +x setup_docker.sh

## Execution du script
sudo bash setup_docker.sh
```

## Configuration du Reverse-Proxy Nginx
Créez le fichier de configuration pour gérer le routage des services via des sous-chemins.
``` Bash
mkdir -p configs
nano configs/nginx.conf
```
Insérez la configuration suivante :
```
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

upstream grafana {
    server grafana:3000;
}

upstream prometheus {
    server prometheus:9090;
}

server {
    listen 80;
    client_max_body_size 10M;

    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
    }

    # ====== Grafana ======
    location /grafana/ {
        proxy_set_header Host $host;
        proxy_pass http://grafana;
    }

    location /grafana/api/live/ {
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $host;
        proxy_pass http://grafana;
    }

    # ====== Prometheus ======
    location /prometheus/ {
        proxy_set_header Host $host;
        proxy_pass http://prometheus/;
    }
}
```

## Déploiement des Services (Docker Compose)
``` Bash
nano compose.yml
```

``` yaml
services:
  nginx:
    image: nginx:latest
    container_name: nginx-proxy
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./configs/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - grafana
      - prometheus

  prometheus:
    image: prom/prometheus:latest
    restart: unless-stopped
    container_name: prometheus
    command:
      - --config.file=/etc/prometheus/prometheus.yml
      - --web.enable-remote-write-receiver
      - --web.external-url=http://localhost/prometheus/
      - --web.route-prefix=/
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana:latest
    restart: unless-stopped
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SERVER_DOMAIN=localhost
      - GF_SERVER_ROOT_URL=%(protocol)s://%(domain)s:%(http_port)s/grafana/
      - GF_SERVER_SERVE_FROM_SUB_PATH=true
    depends_on:
      - prometheus
```

Lancement de la stack :
``` Bash
docker compose up -d
```
Une fois les services démarrés, accédez à Grafana via http://<IP_SERVEUR>/grafana/.

## Configuration de la data source
Il faut annoncer à Grafana la source de données prometheus :
> Connections > Data sources > Add new data source > Prometheus

- **Connection :** http://prometheus:9090

Puis sauvegardez et testé tout en bas

## Configuration des Tableaux de Bord (Grafana)
### Importation des Dashboards

> Dashboards > New > New dashboard
Utilisez les IDs officiels pour importer les visualisations :
1. Node Exporter Full (Hôte)
  - **ID :** 1860
  - **Usage :** Métriques système de la machine distante
2. cAdvisor Exporter (Containers)
  - **ID :** 14282
  - **Usage :** État de santé des conteneurs Docker
  - **Data source :** Prometheus
3. MySQL Exporter Quickstart and Dashboard (MariaDB)
  - **ID :** 14057
  - **Usage** État de santé des base de donnée MariaDB

#### Correction de la variable Prometheus pour la dashboard CAdvisor Exporter
Pour le dashboard 14282, une modification manuelle est nécessaire pour lier les données :
> Dashboard Settings (Top right) > Variables > New Variable

Configurez la variable comme suit :
| Paramètre | Valeur |
| :--- | :--- |
| Variable Type | Datasource |
| Name | DS_PROMETHEUS |
| Data Source options Type | Prometheus |

#### Monitoring MariaDB
grafana>dashboard>new dashboard
source prometheus
query: 
```
node_systemd_unit_state{name="mariadb.service", state="active"}
```
mettre la visualisation en stat
sous value mapping on ajoute 2 value mapping:
| valeur | texte | couleur |
| :--- | :--- | :--- |
| 1 | online | vert |
| 0 | offline | rouge |

mettre le type de query en **Instant** dans les options
