# Déploiement du Serveur de Monitoring (Prometheus & Grafana)

Ce guide détaille le déploiement du serveur de monitoring utilisant **Prometheus** pour la réception des données et **Grafana** pour la visualisation, avec un reverse-proxy **Nginx**.

## Prérequis
- Ubuntu 24.04 LTS
- Docker & Docker compose installé

## Déploiement automatisé
TODO

## Déploiement manuel
### Configuration de l'environnement
#### Monter le repertoire
``` Bash
sudo mkdir /mnt/monitoring
sudo mkfs.ext4 /dev/nvme1n1
sudo mount /dev/nvme1n1 /mnt/monitoring
cd /mnt/monitoring
```

#### Configurer la persistence du repertoire
``` Bash
## Recuperer uuid
sudo blkid /dev/nvme1n1
 
sudo nano /etc/fstab
## Ajouter dans le fstab :
UUID=<mnt_uuid> /mnt/monitoring ext4 defaults 0 2
```
#### Installation de Docker
``` Bash
## Télécharger le script
wget https://raw.githubusercontent.com/CPNV-ES-MAS-3-2/monitoring/develop/server/setup_docker.sh

## Configuration des droits d'éxecution
sudo chmod +x setup_docker.sh

## Execution du script
sudo bash setup_docker.sh
```

### Configuration du Reverse-Proxy Nginx
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

## Configuration du alerting
Créez le fichier de configuration pour gérer le routage des services via des sous-chemins.
``` Bash
nano configs/hook.json
```
Insérez la configuration suivante :
```
[
  {
    "id": "remediate-ssh",
    "execute-command": "/etc/webhook/restart_service.sh",
    "command-working-directory": "/etc/webhook",
    "pass-arguments-to-command": [
      { "source": "payload", "name": "commonLabels.service_name" },
      { "source": "payload", "name": "commonLabels.instance" }
    ]
  }
]
```
réez le fichier de configuration pour gérer le routage des services via des sous-chemins.
``` Bash
nano configs/alert_rules.yml
```
Insérez la configuration suivante :
```
groups:
- name: auto_remediation
  rules:
  - alert: ServiceDown
    # Surveille mariadb OU nginx. Retire le port dynamique.
    expr: node_systemd_unit_state{name=~"mariadb.service|proxysql.service", state="active"} == 0
    for: 1m
    labels:
      # Extrait le nom brut (ex: "mariadb") depuis "mariadb.service"
      service_name: "{{ $labels.name | reReplaceAll \"\\\\.service\" \"\" }}"
    annotations:
      summary: "Relance auto de {{ $labels.name }} sur l'hôte {{ $labels.instance }}"
```
réez le fichier de configuration pour gérer le routage des services via des sous-chemins.
``` Bash
nano configs/alertmanager.yml
```
Insérez la configuration suivante :
```
route:
  receiver: 'webhook-remediator'
  group_wait: 10s
  group_interval: 1m
  repeat_interval: 10m

receivers:
- name: 'webhook-remediator'
  webhook_configs:
  - url: 'http://webhook:9000/hooks/remediate-ssh'
    send_resolved: false
```
réez le fichier de configuration pour gérer le routage des services via des sous-chemins.
``` Bash
nano configs/restart_service.sh
```
Insérez la configuration suivante :
```
#!/bin/sh
SERVICE=$1
RAW_INSTANCE=$2
USER="admin"

# Transformation magique : ip-10-0-3-8 -> 10.0.3.8
# On remplace les tirets par des points et on enlève le préfixe "ip-"
IP=$(echo "$RAW_INSTANCE" | cut -d':' -f1 | sed 's/ip-//' | tr '-' '.')

echo "[$(date)] Tentative sur $IP pour $SERVICE" >> /tmp/webhook.log

ssh -i /etc/webhook/id_rsa_webhook -o StrictHostKeyChecking=no "$USER@$IP" >

```
## Configuration du service Mimir
Créez le fichier de configuration pour gérer le routage des services via des sous-chemins.
``` Bash
nano configs/mimir.yml
```
Insérez la configuration suivante :
```
target: all
multitenancy_enabled: false

ingester:
  ring:
    replication_factor: 1
    kvstore:
      store: inmemory

distributor:
  ring:
    kvstore:
      store: inmemory

store_gateway:
  sharding_ring:
    kvstore:
      store: inmemory

compactor:
  sharding_ring:
    kvstore:
      store: inmemory
```
## Configuration du prometheus
Créez le fichier de configuration pour gérer le routage des services via des sous-chemins.
``` Bash
nano configs/prometheus.yml
```
Insérez la configuration suivante :
```
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

remote_write:
  - url: http://mimir:8080/api/v1/push
    headers:
      X-Scope-OrgID: anonymous
```
## Déploiement des Services (Docker Compose)
``` Bash
nano compose.yml
```

``` yaml
services:
  mimir:
    image: grafana/mimir:2.10.1
    container_name: mimir
    user: "root"
    restart: unless-stopped
    command: ["-config.file=/etc/mimir.yml"]
    volumes:
      - ./configs/mimir.yml:/etc/mimir.yml:ro
      - mimir_data:/tmp/mimir

  nginx:
    image: nginx:latest
    container_name: nginx-proxy
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./configs/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - mimir

  prometheus:
    image: prom/prometheus:latest
    restart: unless-stopped
    container_name: prometheus
    command:
      - --config.file=/etc/prometheus/prometheus.yml
      - --web.enable-remote-write-receiver
      - --web.external-url=http://localhost/prometheus/
      - --web.route-prefix=/
    volumes:
      - ./configs/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./configs/alert_rules.yml:/etc/prometheus/alert_rules.yml:ro
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana:latest
    restart: unless-stopped
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SERVER_DOMAIN=stage.etl.cld.education
      - GF_SERVER_ROOT_URL=https://stage.etl.cld.education/grafana/
      - GF_SERVER_SERVE_FROM_SUB_PATH=true
      - GF_SECURITY_CSRF_ADDITIONAL_ORIGINS=https://stage.etl.cld.education
      - GF_SECURITY_CSRF_TRUSTED_ORIGINS=*
      - GF_SESSION_COOKIE_SECURE=true
      - GF_SESSION_COOKIE_SAMESITE=none
    depends_on:
      - prometheus

  # --- GESTION DES ALERTES ---
  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    restart: unless-stopped
    volumes:
      - ./configs/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'

  # --- AUTOMATISATION (REMEDIATION) ---
  webhook:
    image: almir/webhook
    container_name: webhook
    restart: unless-stopped
    user: root
    volumes:
      - ./configs/hooks.json:/etc/webhook/hooks.json:ro
      - ./configs/restart_service.sh:/etc/webhook/restart_service.sh:ro
      - ./configs/id_rsa_webhook:/etc/webhook/id_rsa_webhook:ro
    # CORRECTION CRUCIALE : On installe SSH au démarrage
    entrypoint: >
      sh -c "apk add --no-cache openssh-client &&
      /usr/local/bin/webhook -verbose -hooks=/etc/webhook/hooks.json -hotreload"

volumes:
  mimir_data:
```

Lancement de la stack :
``` Bash
docker compose up -d
```
Une fois les services démarrés, accédez à Grafana via http://<IP_SERVEUR>/grafana/.

## Configuration des data sources
### prometheus
Il faut annoncer à Grafana la source de données prometheus :
> Connections > Data sources > Add new data source > Prometheus

- **Connection :** http://prometheus:9090

Puis sauvegardez et testé tout en bas
### Mimir
> Connections > Data sources > Add new data source > Prometheus

| Paramètre | Valeur |
| :--- | :--- |
| Nom | Mimir |
| connection | http://mimir:8080/prometheus |

on ajoute aussi un nouvau http header

| Paramètre | Valeur |
| :--- | :--- |
| Header | X-Scope-OrgID |
| Value | anonymous |

Puis sauvegardez et testé tout en bas

### Configuration des Tableaux de Bord (Grafana)
#### Importation des Dashboards

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

##### Correction de la variable Prometheus pour la dashboard CAdvisor Exporter
Pour le dashboard 14282, une modification manuelle est nécessaire pour lier les données :
> Dashboard Settings (Top right) > Variables > New Variable

Configurez la variable comme suit :
| Paramètre | Valeur |
| :--- | :--- |
| Variable Type | Datasource |
| Name | DS_PROMETHEUS |
| Data Source options Type | Prometheus |

##### Monitoring MariaDB
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
