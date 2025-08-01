# OroCommerce Kubernetes

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Helm Chart](https://img.shields.io/badge/Helm%20Chart-v0.1.0-blue.svg)](https://helm.sh/)

Déploiement d'OroCommerce sur Kubernetes avec Helm Charts.

## 🚀 **Installation rapide**

```bash
# Installer OroCommerce
make install

# Désinstaller OroCommerce
make uninstall
```

## 📋 **Prérequis**

- **Kubernetes** : Cluster fonctionnel (minikube, kind, ou cloud)
- **Helm** : Version 3.x installée
- **kubectl** : Configuré pour votre cluster
- **Make** : Pour utiliser les commandes simplifiées
- **Accès root** : Pour modifier le fichier `/etc/hosts`

### Vérification des prérequis

```bash
# Vérifier Kubernetes
kubectl cluster-info

# Vérifier Helm
helm version

# Vérifier Make
make --version
```

### Configuration du contexte Kubernetes

```bash
# Définir le namespace par défaut
make context

# Ou manuellement
kubectl config set-context --current --namespace=orocommerce
```

## 🏗️ **Architecture**

Ce projet déploie une application OroCommerce complète avec les composants suivants :

| Composant | Rôle | Port |
|-----------|------|-------|
| **Webserver** | Serveur web Nginx | 80 |
| **PHP-FPM** | Processeur PHP | 9000 |
| **Database** | PostgreSQL | 5432 |
| **Consumer** | Traitement des messages | - |
| **Cron** | Tâches planifiées | - |
| **Mail** | MailHog (SMTP/UI) | 1025/8025 |
| **WebSocket** | Communication temps réel | 8080 |

## 📦 **Installation**

### 0. **Configuration initiale**

```bash
# 1. Configurer le fichier hosts
echo "127.0.0.1 oro.demo" | sudo tee -a /etc/hosts

# 2. Définir le namespace par défaut
make context

# 3. Vérifier la configuration
kubectl config view --minify --output 'jsonpath={..namespace}'
```

### 1. **Installation complète**

```bash
# Installer OroCommerce
make install
make ssl-cert
```

Cette commande :
- Met à jour les dépendances Helm
- Installe tous les composants
- Configure les volumes persistants
- Démarre l'application

### 2. **Installation avec monitoring (recommandé)**

```bash
# Installer OroCommerce avec monitoring
make install
make ssl-cert
make install-monitoring
make expose-grafana
```

Cette installation inclut :
- OroCommerce complet
- Prometheus pour la collecte de métriques
- Grafana pour la visualisation
- Accès permanent à Grafana via NodePort

### 3. **Vérification de l'installation**

```bash
# Vérifier le statut
make status

# Lister les pods
make pods

# Vérifier les services
make services
```

### 4. **Accès à l'application**

```bash
# Port-forward du webserver
make port-forward-ingress
make port-forward-mail
```

#### **Configuration requise pour l'accès**

**Important** : Vous devez configurer votre fichier hosts pour accéder à l'application.

```bash
# Ajouter cette ligne dans /etc/hosts (Linux/Mac) ou C:\Windows\System32\drivers\etc\hosts (Windows)
127.0.0.1 oro.demo
```

#### **Accès à l'application**

Après avoir configuré le fichier hosts, accédez à :

**Méthode 1 : Port-forward Ingress (HTTPS recommandé)**
```bash
make port-forward-ingress
# Puis ouvrir https://oro.demo:8443
```

**Services disponibles :**
- **Application** : https://oro.demo:8443 (HTTPS) ou http://oro.demo:8080 (HTTP)
- **Interface MailHog** : http://oro.demo:8025

**Note** : L'application ne fonctionne pas avec `localhost`, utilisez obligatoirement `oro.demo`.

#### **Configuration HTTPS**

```bash
# Générer le certificat SSL
make ssl-cert

# Démarrer le port-forward Ingress pour HTTPS
make port-forward-ingress

# Accéder en HTTPS
# https://oro.demo:8443
```

## 🗑️ **Désinstallation**

```bash
# Désinstaller complètement
make uninstall
```

Cette commande :
- Supprime tous les composants Helm
- Nettoie les volumes persistants
- Supprime le namespace

## 🔧 **Commandes principales**

### **Gestion de l'application**

```bash
# Installation
make install          # Installer OroCommerce
make upgrade         # Mettre à jour l'application
make uninstall       # Désinstaller complètement

# Statut et monitoring
make status          # Statut du release Helm
make pods            # Lister les pods
make services        # Lister les services
make logs            # Logs des pods
make health          # Vérification de santé
```

### **Monitoring avec Prometheus et Grafana**

```bash
# Installation du monitoring
make install-monitoring      # Installer Prometheus et Grafana
make monitoring-status       # Statut du monitoring
make uninstall-monitoring   # Désinstaller le monitoring

# Accès à Grafana
make monitoring-port-forward # Port-forward Grafana (localhost:3000)
make expose-grafana         # Exposer Grafana via NodePort
```

### **Développement et debugging**

```bash
# Logs et diagnostic
make logs-pod POD=nom-du-pod    # Logs d'un pod spécifique
make logs-init POD=nom-du-pod   # Logs du container init
make diagnose                   # Diagnostic complet

# Redémarrage
make restart                    # Redémarrage normal
make force-restart             # Redémarrage forcé

# Port-forward
make port-forward              # Webserver sur oro.demo:8080 (HTTP)
make port-forward-ingress      # Ingress sur oro.demo (HTTPS)
```

### **Gestion des volumes**

```bash
# Volumes persistants
make clean-pvc                 # Supprimer tous les PVC
make create-pvc               # Recréer les PVC manquants

# Certificats SSL
make ssl-cert                 # Générer le certificat SSL
make ssl-delete               # Supprimer le certificat SSL
```

### **Dépendances Helm**

```bash
# Gestion des dépendances
make clean-deps               # Nettoyer les dépendances
make update-deps             # Mettre à jour les dépendances

# Repositories Helm
make setup-helm-repos        # Installer tous les repositories Helm nécessaires
```

## 📁 **Structure du projet**

```
orocommerce/
├── charts/                          # Charts Helm
│   ├── orocommerce/                # Chart principal
│   ├── webserver/                  # Serveur web Nginx
│   ├── php-fpm/                    # Processeur PHP
│   ├── database/                   # Base de données PostgreSQL
│   ├── consumer/                   # Traitement des messages
│   ├── cron/                       # Tâches planifiées
│   ├── mail/                       # Service mail (MailHog)
│   └── websocket/                  # WebSocket
├── scripts/                        # Scripts utilitaires
│   └── helm-deps.sh               # Gestion des dépendances
├── docs/                           # Documentation
├── docker-demo-master/            # Configuration Docker Compose
└── Makefile                       # Commandes simplifiées
```

## 🔍 **Monitoring et logs**

### **Monitoring avec Prometheus et Grafana**

Le projet inclut un système de monitoring complet avec Prometheus et Grafana pour surveiller tous les pods, services et métriques du cluster.

#### **Installation du monitoring**

```bash
# Installer Prometheus et Grafana
make install-monitoring

# Vérifier le statut
make monitoring-status

# Exposer Grafana via NodePort
make expose-grafana
```

#### **Accès à Grafana**

**Méthode 1 : Port-forward (recommandé pour le développement)**
```bash
make monitoring-port-forward
# Accès : http://localhost:3000 (admin/admin)
```

**Méthode 2 : NodePort (permanent)**
```bash
make expose-grafana
# Accès : http://192.168.49.2:31952 (admin/admin)
# L'IP et le port sont affichés par la commande
```

#### **Configuration Prometheus**

Prometheus est configuré pour collecter automatiquement :
- **Métriques des pods** : CPU, mémoire, réseau
- **Métriques des services** : Latence, disponibilité
- **Métriques Kubernetes** : État des nodes, namespaces
- **Métriques personnalisées** : Via ServiceMonitors et PodMonitors

**Configuration par défaut :**
- **Rétention** : 7 jours
- **Stockage** : 10Gi persistant
- **ServiceMonitors** : Activés pour tous les services
- **PodMonitors** : Activés pour tous les pods

#### **Dashboards recommandés**

Après la première connexion à Grafana :

1. **Ajouter Prometheus comme source de données**
   - URL : `http://prometheus-server.monitoring.svc.cluster.local:80`
   - Access : Server (default)

2. **Importer des dashboards populaires**
   - **Kubernetes Cluster Monitoring** : ID `315`
   - **Kubernetes Pods** : ID `6417`
   - **Node Exporter** : ID `1860`

#### **Gestion du monitoring**

```bash
# Statut du monitoring
make monitoring-status

# Désinstaller le monitoring
make uninstall-monitoring

# Réinstaller le monitoring
make install-monitoring
```

### **Logs en temps réel**

```bash
# Logs de tous les pods
make logs

# Logs d'un pod spécifique
make logs-pod POD=orocommerce-webserver-xxx

# Logs du container init
make logs-init POD=orocommerce-webserver-xxx
```

### **Configuration du contexte**

```bash
# Définir le namespace par défaut
make context

# Vérifier le contexte actuel
kubectl config current-context
kubectl config view --minify --output 'jsonpath={..namespace}'
```

### **Diagnostic**

```bash
# Diagnostic complet
make diagnose

# Vérification de santé
make health
```

## 🚨 **Troubleshooting**

### **Pods en erreur**

```bash
# Vérifier les événements
kubectl get events --sort-by='.lastTimestamp'

# Logs des pods en erreur
kubectl get pods | grep -v "Running"
```

### **Problèmes de volumes**

```bash
# Recréer les PVC
make create-pvc

# Vérifier les volumes
kubectl get pvc
```

### **Problèmes de réseau**

```bash
# Vérifier les services
make services

# Tester la connectivité
kubectl exec -it <pod> -- nc -zv <service> <port>

# Vérifier la configuration hosts
cat /etc/hosts | grep oro.demo
```

## 🔐 **Sécurité**

- **Namespaces** : Isolation par namespace `orocommerce`
- **RBAC** : ServiceAccounts avec permissions minimales
- **Images** : Images officielles OroCommerce
- **Volumes** : Volumes persistants sécurisés

## 📚 **Documentation**

- [Troubleshooting](docs/TROUBLESHOOTING.md)

## 🆘 **Support**

- **Issues** : [GitHub Issues](https://github.com/votre-repo/issues)
- **Documentation** : [Wiki](https://github.com/votre-repo/wiki)
- **Discussions** : [GitHub Discussions](https://github.com/votre-repo/discussions)

---

**Développé avec ❤️ pour OroCommerce** 