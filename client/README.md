# Déploiement du service Grafana Alloy
Ce guide détaille le déploiement de **Grafana Alloy** sur un hôte Linux pour la collecte des métriques système et des télémétries de conteneurs.

## Installation du service Alloy
Exécutez les commandes suivantes pour configurer le dépôt officiel Grafana et installer l'agent :

``` Bash
# Ajout de la clé GPG et du dépôt officiel
sudo mkdir -p /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/grafana.asc https://apt.grafana.com/gpg-full.key
sudo chmod 644 /etc/apt/keyrings/grafana.asc

echo "deb [signed-by=/etc/apt/keyrings/grafana.asc] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

# Installation et activation du service
sudo apt update
sudo apt install alloy -y
sudo systemctl enable alloy
sudo systemctl start alloy
```

## Élévation des privilèges (Service Override)
Par défaut, Alloy s'exécute avec des permissions restreintes. Pour garantir l'accès aux métriques du noyau, nous configurons le service pour s'exécuter en tant qu'utilisateur **root**.

> L'exécution en root confère un accès privilégié au système. C'est une étape indispensable pour que l'agent puisse lire les fichiers de performance du processeur et du réseau.

``` Bash
sudo systemctl edit alloy.service
```

Insérez le bloc suivant :
```
[Service]
User=root
Group=root
```

Appliquez les changements :
``` Bash
sudo systemctl daemon-reload
sudo systemctl restart alloy
```

## Configuration du Monitoring Hôte 
``` Bash
sudo nano /etc/alloy/config.alloy
```

Insérez la configuration suivante :
```
// Collect
prometheus.exporter.unix "local_host" {
}

// Scrape
prometheus.scrape "metamonitoring" {
  targets    = prometheus.exporter.unix.local_host.targets
  forward_to = [prometheus.relabel.common_labels.receiver]
  scrape_interval = "15s"
  scrape_timeout  = "10s"
}

// Relabel
prometheus.relabel "common_labels" {
  forward_to = [prometheus.remote_write.local_prometheus.receiver]

  rule {
    target_label = "job"
    replacement  = "node_exporter"
  }

  rule {
    target_label = "instance"
    replacement  = sys.env("HOSTNAME")
  }
}

// Push
prometheus.remote_write "local_prometheus" {
  endpoint {
    url = "http://<MON_SRV_IP>/prometheus/api/v1/write"
  }
}
```

Appliquez les changements :
``` Bash
sudo systemctl restart alloy
```

## Monitoring Docker (Optionnel)
Si vous souhaitez surveiller des conteneurs docker, vous devez déployer cAdvisor et mettre à jour Alloy.

### Déploiement de cAdvisor
Lancez cAdvisor via Docker avec un accès privilégié :
``` Bash
docker run -d \
  --name=cadvisor \
  --restart=unless-stopped \
  --privileged=true \
  -p 8080:8080 \
  -v /:/rootfs:ro \
  -v /var/run:/var/run:ro \
  -v /sys:/sys:ro \
  -v /var/lib/docker/:/var/lib/docker:ro \
  -v /dev/disk/:/dev/disk:ro \
  --device=/dev/kmsg \
  gcr.io/cadvisor/cadvisor:v0.55.1
```

### Mise à jour d'Alloy pour Docker
``` Bash
sudo nano /etc/alloy/config.alloy
```

Insérez la configuration suivante :
```
// Collect
prometheus.exporter.unix "local_host" {}

// Scrape host
prometheus.scrape "metamonitoring" {
  targets    = prometheus.exporter.unix.local_host.targets
  forward_to = [prometheus.relabel.common_labels.receiver]
  scrape_interval = "15s"
}

// Scrape containers
prometheus.scrape "cadvisor" {
  targets = [{"__address__" = "localhost:8080"}]
  forward_to = [prometheus.relabel.common_labels.receiver]
  scrape_interval = "15s"
}

// Relabel
prometheus.relabel "common_labels" {
  forward_to = [prometheus.remote_write.local_prometheus.receiver]

  rule {
    target_label = "job"
    replacement  = "node_exporter"
  }

  rule {
    target_label = "instance"
    replacement  = sys.env("HOSTNAME")
  }
}

// Push
prometheus.remote_write "local_prometheus" {
  endpoint {
    url = "http://<MON_SRV_IP>/prometheus/api/v1/write"
  }
}
```
Appliquez les changements :
``` Bash
sudo systemctl restart alloy
```

