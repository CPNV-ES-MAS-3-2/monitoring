# Déploiement du service Grafana Alloy
Ce guide détaille le déploiement de **Grafana Alloy** sur Kubernetes pour la collecte des métriques API, système (worker & master), POD et conteneurs.
Nous avons décidé de déployer Grafana Alloy en tant que DaemonSet pour garantir que chaque nœud du cluster soit surveillé de manière uniforme. Cette approche permet à l'agent de collecter des métriques à la fois au niveau du système et des conteneurs, offrant ainsi une visibilité complète sur les performances du cluster.

## Préparation de l'environnement
### Installation de helm
``` Bash
sudo snap install helm --classic
```
### Installation de KSM (kube-state-metrics)
``` Bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install kube-state-metrics prometheus-community/kube-state-metrics --namespace monitoring --create-namespace
```

### Installation de Metrics Server
``` Bash
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update

helm upgrade --install metrics-server metrics-server/metrics-server --namespace monitoring --set args={--kubelet-insecure-tls}
```

## Préparation du fichier de configuration de l'agent
Exécutez les commandes suivantes pour créer le fichier de configuration de l'agent Alloy :

``` bash
sudo nano values.yml
```

``` yml
alloy:
  clustering:
    enabled: true

  configMap:
    create: true
    content: |
      // CLUSTER DISCOVERY
      discovery.kubernetes "nodes" {
        role = "node"
      }

      discovery.kubernetes "apiserver" {
        role = "endpoints"
      }

      discovery.kubernetes "ksm" {
        role = "endpoints"
      }

      discovery.relabel "api_filter" {
        targets = discovery.kubernetes.apiserver.targets
        rule {
          source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_service_name", "__meta_kubernetes_endpoint_port_name"]
          action = "keep"
          regex = "default;kubernetes;https"
        }
      }

      discovery.relabel "ksm_filter" {
        targets = discovery.kubernetes.ksm.targets
        rule {
          source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_service_name", "__meta_kubernetes_endpoint_port_name"]
          action = "keep"
          regex = "monitoring;kube-state-metrics;http"
        }
      }

      // SCRAPING
      //// HOST & POD METRICS
      prometheus.scrape "kubelet" {
        targets = discovery.kubernetes.nodes.targets
        scheme  = "https"
        scrape_interval = "10s"
        tls_config {
          ca_file = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
          insecure_skip_verify = true
        }
        bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"
        forward_to = [prometheus.remote_write.external_server.receiver]
      }

      prometheus.scrape "kube_state_metrics" {
        targets    = discovery.relabel.ksm_filter.output
        scrape_interval = "10s"
        forward_to = [prometheus.remote_write.external_server.receiver]
      }

      //// CONTAINER METRICS
      prometheus.scrape "cadvisor" {
        targets    = discovery.kubernetes.nodes.targets
        scheme     = "https"
        metrics_path = "/metrics/cadvisor"
        scrape_interval = "10s"
        tls_config {
          ca_file = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
          insecure_skip_verify = true
        }
        bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"
        forward_to = [prometheus.remote_write.external_server.receiver]
      }

      //// API
      prometheus.scrape "apiserver" {
        targets    = discovery.relabel.api_filter.output
        scheme     = "https"
        scrape_interval = "10s"
        tls_config {
          ca_file = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
          insecure_skip_verify = true
        }
        bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"
        forward_to = [prometheus.remote_write.external_server.receiver]
      }

      // Push
      prometheus.remote_write "external_server" {
        endpoint {
          url = "http://<MON_SRV_IP>/prometheus/api/v1/write"
        }
      }

rbac:
  create: true

controller:
  type: 'daemonset'

service:
  enabled: true
```
## Installation du service Alloy
Exécutez les commandes suivantes pour installer helm et installer l'agent :

``` Bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install & Start Alloy pods on the cluster as DaemonSet
helm upgrade --install alloy grafana/alloy --namespace monitoring -f values.yml
```

# Validation du monitoring
## Host
**Prometheus**
```
kubelet_node_name
```
**K8s**
```
kubectl get nodes
```

## API Health Check
**Prometheus**
```
up{job="prometheus.scrape.apiserver"}
```
**K8S**
```
kubectl get --raw /healthz
```

## PODs
**Prometheus**
```
count by (namespace) (kube_pod_info)
```
**K8S**
```
kubectl get pods -A --no-headers | awk '{print $1}' | uniq -c
```

## Conteneurs
**Prometheus**
```
sum(container_memory_working_set_bytes{pod="etl-stack", container!="", container!="POD"}) / 1024 / 1024  
```
**K8S**
```
kubectl top pod etl-stack
```