# Auto-scaling K8s Nodes

Cette partie automatise la scalabilité d'un cluster Kubernetes en utilisant l'**AWS Auto Scaling Group**. Il permet d'ajuster dynamiquement le nombre de workers en fonction de règles fixées.

## Architecture du Système

L'infrastructure repose sur trois piliers interdépendants :

### 1. Launch Template
Le **Launch Template** est la base de chaque nouvelle instance. Il définit les caractéristiques techniques suivantes :

| Composant | Configuration |
| :--- | :--- |
| **Image Source (AMI)** | AMI pré-configurée |
| **Type d'instance** | `t3.medium` |
| **Sécurité** | Clés SSH privées & Security Groups spécifiques au cluster |
| **Monitoring** | **Detailed Monitoring** (Précision à 1 minute) |
| **Nommage** | Préfixe automatique : `mas32-stage-k8s-node` |

### 2. Auto Scaling Group
L'**ASG** gère le cycle de vie et la santé des instances.
* **Flotte Dynamique :** Maintient le nombre d'instances entre `min_size` et `max_size`.
* **Santé :** Utilise un `health_check_grace_period` (ex: 30s) pour laisser le worker s'initialiser avant de valider son état.
* **Cooldown :** Période de blocage après une action de scaling (ajout ou suppression). L'ASG ignore les nouvelles alertes pendant ce laps de temps pour éviter de lancer trop d'instances avant que la précédente n'ait eu le temps d'absorber la charge.

### 3. Les Règles de Scaling (Simple Scaling)
Le cluster s'adapte selon les seuils CloudWatch suivants :

| Métrique | Seuil | Action | Source du Signal |
| :--- | :--- | :--- | :--- |
| **NetworkIn (Haut)** | > 100 MB | **+1 Instance** | Master K8s Node |
| **CPU (Haut)** | >= 70% | **+1 Instance** | Moyenne de l'ASG |
| **CPU (Bas)** | <= 30% | **-1 Instance** | Moyenne de l'ASG |

---

## Déploiement

### Prérequis
* **Terraform** & **AWS CLI** configurés.
* Une **AMI Worker** prête à l'emploi.
* Cluster k8s fonctionnel.

### Procédure
1. **Configuration :** Créez votre fichier `terraform.tfvars` à partir du template d'exemple `terraform.tfvars.example`.
2. **Initialisation :**
```bash
   terraform init -upgrade
```
3. **Application :**
```bash
   terraform plan -out k8s.tfplan
   terraform apply k8s.tfplan
```

---

## Validation du déploiement

Une fois déployé, vous devez valider que les alarmes déclenchent bien les actions de scaling.

### Test 1 : Saturation réseau (Master Node)
Ce test vérifie le scaling basé sur la consommation de ressources réseau du master.

**Commande (Exécuter sur le Master) :**
```bash
# Téléchargement d'un fichier massif vers /dev/null pour saturer la bande passante
wget -O /dev/null http://speedtest.tele2.net/100GB.zip

# Observation des ressources
nload <NETWORK_INTERFACE>
```

**Résultat attendu :**
* **Durant la saturation :**
    1.  **Metrics :** Pic visible sur la métrique `NetworkIn` du Master dans CloudWatch.
    2.  **Alarme :** L'alarme `Master-Network-High` passe en état `ALARM` après 2 périodes de 1 minute.
    3.  **Scaling :** L'ASG crée une nouvelle instance worker.
* **Après la saturation (Arrêt du wget) :**
    1.  **Metrics :** Le trafic réseau redescend à son niveau normal.
    2.  **Alarme :** L'alarme repasse en état `OK`.
    3.  **Alarme :** L'alarme `Master-Network-Low` passe en état `ALARM`.
    4.  **Scaling :** L'instance supplémentaire est retirée.

---

### Test 2 : Charge CPU (Worker Nodes)
Ce test vérifie le scaling basé sur la consommation de ressources CPU des workers.

**Commande (Exécuter sur un Worker existant) :**
```bash
sudo apt update && sudo apt install -y stress cpulimit

# Simule une charge CPU à 80% (au-dessus du seuil de 70%)
stress --cpu 2 --timeout 600s & sleep 2 && sudo cpulimit -l 80 -p $(pgrep -n stress)

# Observation des ressources
htop
```

**Résultat attendu :**
* **Durant la saturation :**
    1.  **Metrics :** La moyenne `CPUUtilization` de l'Auto Scaling Group dépasse 70%.
    2.  **Alarme :** L'alarme `High-CPU-Alarm` se déclenche.
    3.  **Scaling :** Une nouvelle instance worker est ajoutée à la flotte.
* **Après la saturation (Arrêt du stress) :**
    1.  **Metrics :** Le CPU redescend sous le seuil de 30%.
    2.  **Alarme :** L'alarme `Low-CPU-Alarm` se déclenche.
    3.  **Scaling :** L'ASG réduit sa taille jusqu'à atteindre `min_size`.

---

## Maintenance et Suppression

* **Mise à jour :** Toute modification du Launch Template créera une nouvelle version. L'ASG utilisera la dernière version disponible pour tout les déploiements.
* **Nettoyage :** 
```bash
  terraform destroy
```
> **Note importante :** Les instances créées par l'ASG ainsi que toutes les autres configurations seront détruites. Le nœud pré-existant le sera aussi si vous ne le détachez pas manuellement via la console avant d'exécuter le `destroy`.

---