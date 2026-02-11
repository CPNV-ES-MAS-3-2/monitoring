# besoins de monitoring
  -  monitoring des metriques AWS
    -  CPU
    -  RAM
    -  Disk
    -  Réseau
  -  infrastructure
    -  VPC
    -  metrique machine virtuelle
  -  Datawarehouse
    -  Etat du service base de données
# produit
##  prometheuse & grafana
  avantages :
    -  gratuit et open source
    -  native kuberetes (decouverte automatique de pods/noeud/services)
    -  pull performant pour avoir les métriques
    -  permet d'avoir des dashbord personalisé avec grafana
    -  utilisation standar avec k8
## AWS CloudWatch
  avantages :
    -  natif a AWS
    -  collecte de données centralisé a une seul console
  désavantages:
    -  propre a AWS
    -  besoins d'agent suplémentaire pour K8
## Datadog
  avantages
  -  bonne obérvabilité des métric et des logs
  -  beaucoup d'intégration dispo
  -  dashbord et mise en place des alertes très aboutis
  -  gestion centralisé
  désavantages:
  -  cout élevé
##  new Relic
  avantages:
  -  plateforme centralisé avec metric et log
  désvantages:
  -  payant
