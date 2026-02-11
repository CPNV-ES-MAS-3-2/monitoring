# Besoins de monitoring
  -  monitoring des metriques AWS:
     CPU, RAM, Disk, Réseau
  -  infrastructure:
    VPC, metrique machine virtuelle
  -  Datawarehouse:
    Etat du service base de données
# Produit
##  Prometheuse & Grafana
  Avantages
  -   gratuit et open source
  -  native kuberetes (decouverte automatique de pods/noeud/services)
  -  pull performant pour avoir les métriques
  -  permet d'avoir des dashbord personalisé avec grafana
  -   utilisation standar avec k8
    
## AWS CloudWatch
  Avantages
  -   gratuit et open source
  -   natif a aws
  -   collecte de données centralisé a une seule console
  Désavantages
  -  propre a AWS
  -  besoins d'agent suplémentaire pour K8
## Datadog
  Avantages
  -  bonne obérvabilité des métric et des logs
  -  beaucoup d'intégration dispo
  -  dashbord et mise en place des alertes très aboutis
  -  gestion centralisé
  Désavantages:
  -  cout élevé
##  New Relic
  Avantages:
  -  plateforme centralisé avec metric et log
  Désvantages:
  -  payant
