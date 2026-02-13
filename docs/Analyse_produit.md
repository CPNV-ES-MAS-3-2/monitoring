# Besoins de monitoring

- Monitoring des métriques AWS :\
    CPU, RAM, disque, réseau

- Infrastructure :\
    VPC, métriques des machines virtuelles

- Datawarehouse :\
    État du service de la base de données

------------------------------------------------------------------------

# Produits

## Prometheus & Grafana

### Avantages

- Gratuit et open source
- Natif Kubernetes (découverte automatique des pods / nœuds /
    services)
- Pull performant pour récupérer les métriques
- Permet d'avoir des dashboards personnalisés avec Grafana
- Utilisation standard avec K8s

------------------------------------------------------------------------

## AWS CloudWatch

### Avantages

- Gratuit (selon l'usage)
- Natif à AWS
- Collecte de données centralisée dans une seule console

### Désavantages

- Propre à AWS
- Besoin d'un agent supplémentaire pour Kubernetes

------------------------------------------------------------------------

## Datadog

### Avantages

- Bonne observabilité des métriques et des logs
- Beaucoup d'intégrations disponibles
- Dashboards et mise en place des alertes très aboutis
- Gestion centralisée

### Désavantages

- Coût élevé

------------------------------------------------------------------------

## New Relic

### Avantages

- Plateforme centralisée avec métriques et logs
- Intégrations nombreuses (cloud, bases de données, Kubernetes, etc.)
- Alerting avancé et configurable

### Désavantages

- Payant

------------------------------------------------------------------------

# Choix du produit

**Prometheus & Grafana**
## Comparatif des solutions de monitoring

## Tableau comparatif des solutions de monitoring

| Critère                              | Prometheus & Grafana | AWS CloudWatch        | Datadog               | New Relic             |
|---------------------------------------|----------------------|-----------------------|-----------------------|-----------------------|
| Métriques AWS (CPU, RAM, disque, réseau) |  Oui               |  Oui (natif AWS)    |  Oui                |  Oui                |
| Monitoring Infrastructure (VPC, VM)  |  Oui               |  Oui                |  Oui                |  Oui                |
| État base de données / Datawarehouse |  Oui               |  Oui                |  Oui                |  Oui                |
| Natif Kubernetes                     |  Oui (native)      |  Agent requis       |  Oui                |  Oui                |
| Découverte automatique K8s           |  Oui               |  Non                |  Oui                |  Oui                |
| Centralisation métriques & logs      |  Oui (avec stack)  |  Oui                |  Oui                |  Oui                |
| Dashboards personnalisés             |  Très flexible     |  Limité             |  Avancé             |  Avancé             |
| Alerting avancé                      |  Oui               |  Oui                |  Très avancé        |  Oui                |
| Multi-cloud                          |  Oui               |  AWS uniquement     |  Oui                |  Oui                |
| Open source                          |  Oui               |  Non                |  Non                |  Non                |
| Coût                                 |  Gratuit           |  Payant (usage)     |  Élevé              |  Payant             |
| Dépendance fournisseur               |  Non               |  AWS                |  Non                |  Non                |

Après comparatif des différents produits, on peut voir que trois solutions peuvent nous convenir : Prometheus & Grafana, Datadog et New Relic.
Ces trois solutions nous permettent de monitorer tous les critères que nous avions établis au début de ce document.

Cependant, Prometheus & Grafana se distingue par plusieurs avantages stratégiques pour notre contexte. Tout d’abord, la solution est open source et gratuite, ce qui permet de maîtriser les coûts tout en évitant une dépendance forte à un éditeur tiers. Contrairement à Datadog et New Relic, dont les coûts peuvent augmenter rapidement avec le volume de métriques et de logs, Prometheus offre une meilleure prévisibilité budgétaire.

Ensuite, Prometheus est nativement conçu pour Kubernetes, avec un mécanisme de découverte automatique des pods, nœuds et services. Cela correspond parfaitement à notre architecture et simplifie considérablement l’intégration et l’exploitation de la solution.

De plus, l’association avec Grafana permet de créer des dashboards entièrement personnalisés, adaptés précisément à nos besoins métiers et techniques. Cette flexibilité est un atout majeur pour le suivi des métriques AWS, de l’infrastructure (VPC, machines virtuelles) ainsi que de l’état du datawarehouse.

Enfin, Prometheus & Grafana constitue une solution multi-cloud et indépendante d’un fournisseur, ce qui nous garantit une plus grande liberté d’évolution de notre infrastructure à l’avenir.

Pour l’ensemble de ces raisons — maîtrise des coûts, intégration native Kubernetes, flexibilité et indépendance technologique — le choix de Prometheus & Grafana apparaît comme la solution la plus adaptée à nos besoins.
