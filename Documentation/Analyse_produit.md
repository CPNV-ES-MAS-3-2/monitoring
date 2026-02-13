# Besoins de monitoring

-   Monitoring des métriques AWS :\
    CPU, RAM, disque, réseau

-   Infrastructure :\
    VPC, métriques des machines virtuelles

-   Datawarehouse :\
    État du service de la base de données

------------------------------------------------------------------------

# Produits

## Prometheus & Grafana

### Avantages

-   Gratuit et open source\
-   Natif Kubernetes (découverte automatique des pods / nœuds /
    services)\
-   Pull performant pour récupérer les métriques\
-   Permet d'avoir des dashboards personnalisés avec Grafana\
-   Utilisation standard avec K8s

------------------------------------------------------------------------

## AWS CloudWatch

### Avantages

-   Gratuit (selon l'usage)\
-   Natif à AWS\
-   Collecte de données centralisée dans une seule console

### Désavantages

-   Propre à AWS\
-   Besoin d'un agent supplémentaire pour Kubernetes

------------------------------------------------------------------------

## Datadog

### Avantages

-   Bonne observabilité des métriques et des logs\
-   Beaucoup d'intégrations disponibles\
-   Dashboards et mise en place des alertes très aboutis\
-   Gestion centralisée

### Désavantages

-   Coût élevé

------------------------------------------------------------------------

## New Relic

### Avantages

-   Plateforme centralisée avec métriques et logs

### Désavantages

-   Payant

------------------------------------------------------------------------

# Choix du produit

**Prometheus & Grafana**
