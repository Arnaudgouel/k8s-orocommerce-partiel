# Makefile pour OroCommerce Helm Chart
# Usage: make <target>

# Variables
NAMESPACE := orocommerce
RELEASE_NAME := orocommerce
CHART_PATH := charts/orocommerce

# Couleurs pour les messages
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

.PHONY: help install upgrade uninstall status logs pods services ingress clean-deps update-deps port-forward

# Afficher l'aide
help:
	@echo "$(GREEN)Commandes disponibles:$(NC)"
	@echo "  $(YELLOW)install$(NC)      - Installer OroCommerce (première fois)"
	@echo "  $(YELLOW)upgrade$(NC)      - Mettre à jour OroCommerce"
	@echo "  $(YELLOW)uninstall$(NC)    - Désinstaller OroCommerce"
	@echo "  $(YELLOW)status$(NC)       - Afficher le statut du release"
	@echo "  $(YELLOW)logs$(NC)         - Afficher les logs des pods"
	@echo "  $(YELLOW)pods$(NC)         - Lister les pods"
	@echo "  $(YELLOW)services$(NC)     - Lister les services"
	@echo "  $(YELLOW)ingress$(NC)      - Lister les ingress"
	@echo "  $(YELLOW)clean-deps$(NC)   - Nettoyer les dépendances"
	@echo "  $(YELLOW)update-deps$(NC)  - Mettre à jour les dépendances"
	@echo "  $(YELLOW)port-forward$(NC) - Faire un port-forward du webserver"
	@echo "  $(YELLOW)port-forward-ingress$(NC) - Faire un port-forward de l'Ingress (HTTPS)"
	@echo "  $(YELLOW)context$(NC)      - Définir le contexte avec namespace orocommerce"
	@echo "  $(YELLOW)diagnose$(NC)     - Diagnostiquer les problèmes"
	@echo "  $(YELLOW)logs-pod$(NC)     - Logs d'un pod spécifique (POD=nom-du-pod)"
	@echo "  $(YELLOW)logs-init$(NC)    - Logs du container init (POD=nom-du-pod)"
	@echo "  $(YELLOW)force-restart$(NC) - Forcer le redémarrage des pods"
	@echo "  $(YELLOW)clean-pvc$(NC)    - Nettoyer les PersistentVolumeClaims"
	@echo "  $(YELLOW)create-pvc$(NC)   - Créer les PersistentVolumeClaims manquants"
	@echo "  $(YELLOW)ssl-cert$(NC)     - Générer le certificat SSL"
	@echo "  $(YELLOW)ssl-delete$(NC)   - Supprimer le certificat SSL"
	@echo "  $(YELLOW)setup-helm-repos$(NC) - Installer tous les repositories Helm nécessaires"
	@echo "  $(YELLOW)install-monitoring$(NC) - Installer Prometheus et Grafana"
	@echo "  $(YELLOW)uninstall-monitoring$(NC) - Désinstaller Prometheus et Grafana"
	@echo "  $(YELLOW)monitoring-status$(NC) - Statut du monitoring"
	@echo "  $(YELLOW)monitoring-port-forward$(NC) - Port-forward pour accéder à Grafana"
	@echo "  $(YELLOW)expose-grafana$(NC) - Exposer Grafana via NodePort"
	@echo "  $(YELLOW)backup-db$(NC) - Créer un backup manuel de la base de données"
	@echo "  $(YELLOW)backup-status$(NC) - Vérifier le statut des backups"
	@echo "  $(YELLOW)backup-list$(NC) - Lister les backups disponibles"
	@echo "  $(YELLOW)backup-restore$(NC) - Restaurer depuis un backup (BACKUP_FILE=nom-du-fichier)"

# Installer OroCommerce (première fois)
install: context setup-helm-repos update-deps
	@echo "$(GREEN)Installation d'OroCommerce...$(NC)"
	helm install $(RELEASE_NAME) $(CHART_PATH) 

# Mettre à jour OroCommerce
upgrade: update-deps
	@echo "$(GREEN)Mise à jour d'OroCommerce...$(NC)"
	helm upgrade $(RELEASE_NAME) $(CHART_PATH) 

# Désinstaller OroCommerce
uninstall:
	@echo "$(RED)Désinstallation d'OroCommerce...$(NC)"
	helm uninstall $(RELEASE_NAME) 
	make clean-pvc

# Afficher le statut du release
status:
	@echo "$(GREEN)Statut du release:$(NC)"
	helm status $(RELEASE_NAME) 

# Afficher les logs des pods
logs:
	@echo "$(GREEN)Logs des pods:$(NC)"
	@echo "$(YELLOW)Note: Certains pods peuvent être en cours d'initialisation$(NC)"
	kubectl logs  -l app.kubernetes.io/instance=$(RELEASE_NAME) --tail=50 --ignore-errors=true || echo "$(RED)Aucun log disponible pour les pods en cours d'initialisation$(NC)"

# Afficher les logs d'un pod spécifique
logs-pod:
	@echo "$(GREEN)Logs d'un pod spécifique:$(NC)"
	@echo "$(YELLOW)Usage: make logs-pod POD=nom-du-pod$(NC)"
	@if [ -z "$(POD)" ]; then \
		echo "$(RED)Spécifiez un pod avec POD=nom-du-pod$(NC)"; \
		echo "$(YELLOW)Exemple: make logs-pod POD=orocommerce-consumer-6b45cd86fb-znl7q$(NC)"; \
	else \
		kubectl logs  $(POD) --tail=50 --ignore-errors=true || echo "$(YELLOW)Pod en cours d'initialisation, pas de logs disponibles$(NC)"; \
	fi

# Afficher les logs du container init d'un pod
logs-init:
	@echo "$(GREEN)Logs du container init:$(NC)"
	@echo "$(YELLOW)Usage: make logs-init POD=nom-du-pod$(NC)"
	@if [ -z "$(POD)" ]; then \
		echo "$(RED)Spécifiez un pod avec POD=nom-du-pod$(NC)"; \
		echo "$(YELLOW)Exemple: make logs-init POD=orocommerce-consumer-6b45cd86fb-znl7q$(NC)"; \
	else \
		kubectl logs $(POD) -c init-container --tail=50 --ignore-errors=true || echo "$(YELLOW)Container init non disponible$(NC)"; \
	fi

# Lister les pods
pods:
	@echo "$(GREEN)Pods dans le namespace $(NAMESPACE):$(NC)"
	kubectl get pods

# Lister les services
services:
	@echo "$(GREEN)Services dans le namespace $(NAMESPACE):$(NC)"
	kubectl get services

# Lister les ingress
ingress:
	@echo "$(GREEN)Ingress dans le namespace $(NAMESPACE):$(NC)"
	kubectl get ingress

# Nettoyer les dépendances
clean-deps:
	@echo "$(YELLOW)Nettoyage des dépendances...$(NC)"
	cd $(CHART_PATH) && rm -rf charts/
	cd $(CHART_PATH) && helm dependency build

# Mettre à jour les dépendances
update-deps:
	@echo "$(YELLOW)Mise à jour des dépendances...$(NC)"
	cd $(CHART_PATH) && helm dependency update

# Faire un port-forward du webserver
port-forward:
	@echo "$(GREEN)Port-forward du webserver sur localhost:8080...$(NC)"
	@echo "$(YELLOW)Appuyez sur Ctrl+C pour arrêter$(NC)"
	kubectl port-forward svc/webserver-$(RELEASE_NAME) 8080:80

# Faire un port-forward de l'Ingress Controller (pour HTTPS)
port-forward-ingress:
	@echo "$(GREEN)Port-forward de l'Ingress Controller sur localhost:80 et 443...$(NC)"
	@echo "$(YELLOW)Appuyez sur Ctrl+C pour arrêter$(NC)"
	@echo "$(YELLOW)Note: Nécessite les privilèges sudo pour le port 443$(NC)"
	kubectl port-forward svc/ingress-nginx-controller -n ingress-nginx 8080:80 8443:443

port-forward-mail:
	@echo "$(GREEN)Port-forward du mailhog sur localhost:8025...$(NC)"
	@echo "$(YELLOW)Appuyez sur Ctrl+C pour arrêter$(NC)"
	kubectl port-forward svc/mail-ui 8025:8025

# Définir le contexte avec namespace orocommerce
context:
	@echo "$(GREEN)Définition du contexte avec namespace $(NAMESPACE)...$(NC)"
	kubectl create namespace $(NAMESPACE)
	kubectl create namespace monitoring
	kubectl config set-context --current --namespace=$(NAMESPACE)
	@echo "$(GREEN)Contexte défini sur le namespace $(NAMESPACE)$(NC)"

# Afficher les informations du cluster
info:
	@echo "$(GREEN)Informations du cluster:$(NC)"
	@echo "$(YELLOW)Namespace actuel:$(NC)"
	kubectl config view --minify --output 'jsonpath={..namespace}'
	@echo ""
	@echo "$(YELLOW)Contexte actuel:$(NC)"
	kubectl config current-context
	@echo ""
	@echo "$(YELLOW)Nodes du cluster:$(NC)"
	kubectl get nodes


# Redémarrer tous les pods
restart:
	@echo "$(YELLOW)Redémarrage des pods...$(NC)"
	kubectl rollout restart deployment

# Forcer le redémarrage des pods (suppression et recréation)
force-restart:
	@echo "$(RED)Forçage du redémarrage des pods...$(NC)"
	@echo "$(YELLOW)Attention: Cette opération supprime et recrée les pods$(NC)"
	kubectl delete pods --all --grace-period=0 --force

# Nettoyer les PVC et recréer
clean-pvc:
	@echo "$(RED)Nettoyage des PersistentVolumeClaims...$(NC)"
	@echo "$(YELLOW)Attention: Cette opération supprime toutes les données$(NC)"
	kubectl delete pvc --all
	@echo "$(GREEN)PersistentVolumeClaims supprimés$(NC)"

# Recréer les PVC manquants
create-pvc:
	@echo "$(GREEN)Création des PersistentVolumeClaims manquants...$(NC)"
	@echo "apiVersion: v1" > /tmp/oro-pvc.yaml
	@echo "kind: PersistentVolumeClaim" >> /tmp/oro-pvc.yaml
	@echo "metadata:" >> /tmp/oro-pvc.yaml
	@echo "  name: oro-app-orocommerce" >> /tmp/oro-pvc.yaml
	@echo "  namespace: $(NAMESPACE)" >> /tmp/oro-pvc.yaml
	@echo "spec:" >> /tmp/oro-pvc.yaml
	@echo "  accessModes:" >> /tmp/oro-pvc.yaml
	@echo "    - ReadWriteOnce" >> /tmp/oro-pvc.yaml
	@echo "  resources:" >> /tmp/oro-pvc.yaml
	@echo "    requests:" >> /tmp/oro-pvc.yaml
	@echo "      storage: 10Gi" >> /tmp/oro-pvc.yaml
	@echo "---" >> /tmp/oro-pvc.yaml
	@echo "apiVersion: v1" >> /tmp/oro-pvc.yaml
	@echo "kind: PersistentVolumeClaim" >> /tmp/oro-pvc.yaml
	@echo "metadata:" >> /tmp/oro-pvc.yaml
	@echo "  name: cache-orocommerce" >> /tmp/oro-pvc.yaml
	@echo "  namespace: $(NAMESPACE)" >> /tmp/oro-pvc.yaml
	@echo "spec:" >> /tmp/oro-pvc.yaml
	@echo "  accessModes:" >> /tmp/oro-pvc.yaml
	@echo "    - ReadWriteOnce" >> /tmp/oro-pvc.yaml
	@echo "  resources:" >> /tmp/oro-pvc.yaml
	@echo "    requests:" >> /tmp/oro-pvc.yaml
	@echo "      storage: 5Gi" >> /tmp/oro-pvc.yaml
	@echo "---" >> /tmp/oro-pvc.yaml
	@echo "apiVersion: v1" >> /tmp/oro-pvc.yaml
	@echo "kind: PersistentVolumeClaim" >> /tmp/oro-pvc.yaml
	@echo "metadata:" >> /tmp/oro-pvc.yaml
	@echo "  name: maintenance-orocommerce" >> /tmp/oro-pvc.yaml
	@echo "  namespace: $(NAMESPACE)" >> /tmp/oro-pvc.yaml
	@echo "spec:" >> /tmp/oro-pvc.yaml
	@echo "  accessModes:" >> /tmp/oro-pvc.yaml
	@echo "    - ReadWriteOnce" >> /tmp/oro-pvc.yaml
	@echo "  resources:" >> /tmp/oro-pvc.yaml
	@echo "    requests:" >> /tmp/oro-pvc.yaml
	@echo "      storage: 1Gi" >> /tmp/oro-pvc.yaml
	@echo "---" >> /tmp/oro-pvc.yaml
	@echo "apiVersion: v1" >> /tmp/oro-pvc.yaml
	@echo "kind: PersistentVolumeClaim" >> /tmp/oro-pvc.yaml
	@echo "metadata:" >> /tmp/oro-pvc.yaml
	@echo "  name: public-storage-orocommerce" >> /tmp/oro-pvc.yaml
	@echo "  namespace: $(NAMESPACE)" >> /tmp/oro-pvc.yaml
	@echo "spec:" >> /tmp/oro-pvc.yaml
	@echo "  accessModes:" >> /tmp/oro-pvc.yaml
	@echo "    - ReadWriteOnce" >> /tmp/oro-pvc.yaml
	@echo "  resources:" >> /tmp/oro-pvc.yaml
	@echo "    requests:" >> /tmp/oro-pvc.yaml
	@echo "      storage: 20Gi" >> /tmp/oro-pvc.yaml
	@echo "---" >> /tmp/oro-pvc.yaml
	@echo "apiVersion: v1" >> /tmp/oro-pvc.yaml
	@echo "kind: PersistentVolumeClaim" >> /tmp/oro-pvc.yaml
	@echo "metadata:" >> /tmp/oro-pvc.yaml
	@echo "  name: private-storage-orocommerce" >> /tmp/oro-pvc.yaml
	@echo "  namespace: $(NAMESPACE)" >> /tmp/oro-pvc.yaml
	@echo "spec:" >> /tmp/oro-pvc.yaml
	@echo "  accessModes:" >> /tmp/oro-pvc.yaml
	@echo "    - ReadWriteOnce" >> /tmp/oro-pvc.yaml
	@echo "  resources:" >> /tmp/oro-pvc.yaml
	@echo "    requests:" >> /tmp/oro-pvc.yaml
	@echo "      storage: 10Gi" >> /tmp/oro-pvc.yaml
	kubectl apply -f /tmp/oro-pvc.yaml
	@rm /tmp/oro-pvc.yaml
	@echo "$(GREEN)PersistentVolumeClaims créés$(NC)"

# Générer le certificat SSL
ssl-cert:
	@echo "$(GREEN)Génération du certificat SSL...$(NC)"
	./scripts/generate-ssl-cert.sh

# Supprimer le certificat SSL
ssl-delete:
	@echo "$(RED)Suppression du certificat SSL...$(NC)"
	kubectl delete secret oro-demo-tls -n $(NAMESPACE) --ignore-not-found=true
	@echo "$(GREEN)Certificat SSL supprimé$(NC)"

# Installer tous les repositories Helm nécessaires
setup-helm-repos:
	@echo "$(GREEN)Installation des repositories Helm...$(NC)"
	@echo "$(YELLOW)Ajout du repository: bitnami - Charts Bitnami (MySQL, Redis, etc.)$(NC)"
	helm repo add bitnami https://charts.bitnami.com/bitnami 2>/dev/null || echo "$(YELLOW)⚠️  Repository bitnami existe déjà$(NC)"
	@echo "$(YELLOW)Ajout du repository: prometheus-community - Prometheus, Grafana, AlertManager$(NC)"
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || echo "$(YELLOW)⚠️  Repository prometheus-community existe déjà$(NC)"
	@echo "$(YELLOW)Ajout du repository: ingress-nginx - Ingress Controller NGINX$(NC)"
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>/dev/null || echo "$(YELLOW)⚠️  Repository ingress-nginx existe déjà$(NC)"
	@echo "$(YELLOW)Ajout du repository: jetstack - Cert-Manager pour SSL/TLS$(NC)"
	helm repo add jetstack https://charts.jetstack.io 2>/dev/null || echo "$(YELLOW)⚠️  Repository jetstack existe déjà$(NC)"
	@echo "$(YELLOW)Ajout du repository: elastic - Elasticsearch, Kibana, Logstash$(NC)"
	helm repo add elastic https://helm.elastic.co 2>/dev/null || echo "$(YELLOW)⚠️  Repository elastic existe déjà$(NC)"
	@echo "$(YELLOW)Ajout du repository: jaegertracing - Jaeger pour le tracing$(NC)"
	helm repo add jaegertracing https://jaegertracing.github.io/helm-charts 2>/dev/null || echo "$(YELLOW)⚠️  Repository jaegertracing existe déjà$(NC)"
	@echo "$(YELLOW)Ajout du repository: grafana - Grafana pour les dashboards$(NC)"
	helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || echo "$(YELLOW)⚠️  Repository grafana existe déjà$(NC)"
	@echo "$(YELLOW)Mise à jour de tous les repositories...$(NC)"
	helm repo update
	

# Installer Prometheus et Grafana pour le monitoring
install-monitoring: setup-helm-repos
	@echo "$(GREEN)Installation de Prometheus et Grafana...$(NC)"
	@echo "$(YELLOW)Création du namespace monitoring...$(NC)"
	kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
	@echo "$(YELLOW)Vérification de Prometheus...$(NC)"
	@if helm list -n monitoring | grep -q prometheus; then \
		echo "$(YELLOW)⚠️  Prometheus est déjà installé, mise à jour...$(NC)"; \
		helm upgrade prometheus prometheus-community/prometheus \
			--namespace monitoring \
			--set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
			--set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
			--set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false \
			--set prometheus.prometheusSpec.probeSelectorNilUsesHelmValues=false \
			--set prometheus.prometheusSpec.retention=7d \
			--set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=10Gi; \
	else \
		echo "$(YELLOW)Installation de Prometheus...$(NC)"; \
		helm install prometheus prometheus-community/prometheus \
			--namespace monitoring \
			--set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
			--set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
			--set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false \
			--set prometheus.prometheusSpec.probeSelectorNilUsesHelmValues=false \
			--set prometheus.prometheusSpec.retention=7d \
			--set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=10Gi; \
	fi
	@echo "$(YELLOW)Vérification de Grafana...$(NC)"
	@if helm list -n monitoring | grep -q grafana; then \
		echo "$(YELLOW)⚠️  Grafana est déjà installé, mise à jour...$(NC)"; \
		helm upgrade grafana grafana/grafana \
			--namespace monitoring \
			--set persistence.enabled=true \
			--set persistence.size=5Gi \
			--set adminPassword=admin \
			--set service.type=ClusterIP; \
	else \
		echo "$(YELLOW)Installation de Grafana...$(NC)"; \
		helm install grafana grafana/grafana \
			--namespace monitoring \
			--set persistence.enabled=true \
			--set persistence.size=5Gi \
			--set adminPassword=admin \
			--set service.type=ClusterIP; \
	fi
	@echo "$(GREEN)✅ Monitoring installé avec succès !$(NC)"
	@echo "$(YELLOW)Pour accéder à Grafana: make monitoring-port-forward$(NC)"
	@echo "$(YELLOW)Pour voir le statut: make monitoring-status$(NC)"

# Désinstaller Prometheus et Grafana
uninstall-monitoring:
	@echo "$(RED)Désinstallation de Prometheus et Grafana...$(NC)"
	helm uninstall grafana -n monitoring --ignore-not-found=true
	helm uninstall prometheus -n monitoring --ignore-not-found=true
	kubectl delete namespace monitoring --ignore-not-found=true
	@echo "$(GREEN)✅ Monitoring désinstallé$(NC)"

# Statut du monitoring
monitoring-status:
	@echo "$(GREEN)Statut du monitoring:$(NC)"
	@echo "$(YELLOW)Pods du namespace monitoring:$(NC)"
	kubectl get pods -n monitoring
	@echo ""
	@echo "$(YELLOW)Services du namespace monitoring:$(NC)"
	kubectl get services -n monitoring
	@echo ""
	@echo "$(YELLOW)Grafana credentials:$(NC)"
	@echo "  Username: admin"
	@echo "  Password: admin"
	@echo ""
	@echo "$(YELLOW)Pour accéder à Grafana:$(NC)"
	@echo "  make monitoring-port-forward"

# Port-forward pour accéder à Grafana
monitoring-port-forward:
	@echo "$(GREEN)Port-forward pour Grafana sur localhost:3000...$(NC)"
	@echo "$(YELLOW)Appuyez sur Ctrl+C pour arrêter$(NC)"
	@echo "$(YELLOW)Accès: http://localhost:3000 (admin/admin)$(NC)"
	kubectl port-forward svc/grafana -n monitoring 3000:80

# Exposer Grafana via NodePort
expose-grafana:
	@echo "$(GREEN)Exposition de Grafana via NodePort...$(NC)"
	@echo "$(YELLOW)Création du service NodePort pour Grafana...$(NC)"
	kubectl patch svc grafana -n monitoring -p '{"spec":{"type":"NodePort"}}' --dry-run=client -o yaml | kubectl apply -f -
	@echo "$(GREEN)✅ Grafana exposé via NodePort$(NC)"
	@echo "$(YELLOW)Récupération du port NodePort et de l'IP...$(NC)"
	@NODEPORT=$$(kubectl get svc grafana -n monitoring -o jsonpath='{.spec.ports[0].nodePort}'); \
	MINIKUBE_IP=$$(minikube ip); \
	echo "$(GREEN)Grafana accessible sur:$(NC)"; \
	echo "$(YELLOW)  Local: http://localhost:$$NODEPORT$(NC)"; \
	echo "$(YELLOW)  Minikube: http://$$MINIKUBE_IP:$$NODEPORT$(NC)"; \
	echo "$(YELLOW)  Credentials: admin/admin$(NC)"
	@echo "$(YELLOW)Services du namespace monitoring:$(NC)"
	kubectl get svc -n monitoring

# Installer le système de backup
install-backup:
	@echo "$(GREEN)Installation du système de backup PostgreSQL...$(NC)"
	@echo "$(YELLOW)Création du PVC pour les backups...$(NC)"
	kubectl apply -f k8s/backup/backup-storage-pvc.yaml
	@echo "$(YELLOW)Création du CronJob pour les backups automatiques...$(NC)"
	kubectl apply -f k8s/backup/postgres-backup-cronjob.yaml
	@echo "$(GREEN)✅ Système de backup installé$(NC)"
	@echo "$(YELLOW)Backups automatiques programmés tous les jours à 2h du matin$(NC)"

# Créer un backup manuel
backup-db:
	@echo "$(GREEN)Création d'un backup manuel de la base de données...$(NC)"
	@echo "$(YELLOW)Suppression de l'ancien job manuel s'il existe...$(NC)"
	kubectl delete job manual-postgres-backup -n $(NAMESPACE) --ignore-not-found=true
	@echo "$(YELLOW)Création du job de backup manuel...$(NC)"
	kubectl apply -f k8s/backup/manual-backup-job.yaml
	@echo "$(GREEN)✅ Job de backup créé$(NC)"
	@echo "$(YELLOW)Suivi du job en cours...$(NC)"
	kubectl wait --for=condition=complete job/manual-postgres-backup -n $(NAMESPACE) --timeout=300s
	@echo "$(GREEN)✅ Backup terminé$(NC)"
	@echo "$(YELLOW)Logs du backup:$(NC)"
	kubectl logs job/manual-postgres-backup -n $(NAMESPACE)

# Vérifier le statut des backups
backup-status:
	@echo "$(GREEN)Statut du système de backup:$(NC)"
	@echo "$(YELLOW)CronJob:$(NC)"
	kubectl get cronjob postgres-backup -n $(NAMESPACE)
	@echo ""
	@echo "$(YELLOW)Jobs récents:$(NC)"
	kubectl get jobs -n $(NAMESPACE) -l app=postgres-backup
	@echo ""
	@echo "$(YELLOW)PVC de backup:$(NC)"
	kubectl get pvc backup-storage-pvc -n $(NAMESPACE)

# Lister les backups disponibles
backup-list:
	@echo "$(GREEN)Backups disponibles:$(NC)"
	@echo "$(YELLOW)Création d'un pod temporaire pour lister les backups...$(NC)"
	kubectl run backup-lister --image=busybox --rm -it --restart=Never -n $(NAMESPACE) \
		--overrides='{"spec":{"volumes":[{"name":"backup-storage","persistentVolumeClaim":{"claimName":"backup-storage-pvc"}}],"containers":[{"name":"backup-lister","image":"busybox","command":["sh","-c","ls -la /backup-storage/"],"volumeMounts":[{"name":"backup-storage","mountPath":"/backup-storage"}]}]}}'

# Restaurer depuis un backup
backup-restore:
	@echo "$(GREEN)Restauration depuis un backup...$(NC)"
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "$(RED)Spécifiez un fichier de backup avec BACKUP_FILE=nom-du-fichier$(NC)"; \
		echo "$(YELLOW)Exemple: make backup-restore BACKUP_FILE=orocommerce_backup_20250101_000000.sql.gz$(NC)"; \
		echo "$(YELLOW)Utilisez 'make backup-list' pour voir les backups disponibles$(NC)"; \
	else \
		echo "$(YELLOW)Restauration depuis: $(BACKUP_FILE)$(NC)"; \
		echo "$(YELLOW)Modification du fichier de restauration...$(NC)"; \
		sed -i "s/orocommerce_backup_20250101_000000.sql.gz/$(BACKUP_FILE)/g" k8s/backup/restore-job.yaml; \
		echo "$(YELLOW)Création du job de restauration...$(NC)"; \
		kubectl apply -f k8s/backup/restore-job.yaml; \
		echo "$(GREEN)✅ Job de restauration créé$(NC)"; \
		echo "$(YELLOW)Suivi de la restauration...$(NC)"; \
		kubectl wait --for=condition=complete job/postgres-restore -n $(NAMESPACE) --timeout=300s; \
		echo "$(GREEN)✅ Restauration terminée$(NC)"; \
		echo "$(YELLOW)Logs de la restauration:$(NC)"; \
		kubectl logs job/postgres-restore -n $(NAMESPACE); \
	fi

# Vérifier la santé des pods
health:
	@echo "$(GREEN)Vérification de la santé des pods...$(NC)"
	kubectl get pods -o wide
	@echo ""
	@echo "$(YELLOW)Événements récents:$(NC)"
	kubectl get events --sort-by='.lastTimestamp'
	@echo ""
	@echo "$(YELLOW)Pods avec problèmes:$(NC)"
	kubectl get pods --field-selector=status.phase!=Running

# Diagnostiquer les problèmes
diagnose:
	@echo "$(GREEN)Diagnostic des problèmes...$(NC)"
	@echo "$(YELLOW)1. Vérification des images:$(NC)"
	kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[*].image}{"\n"}{end}'
	@echo ""
	@echo "$(YELLOW)2. Événements d'erreur:$(NC)"
	kubectl get events --field-selector=type=Warning --sort-by='.lastTimestamp' | head -10
	@echo ""
	@echo "$(YELLOW)3. Pods avec problèmes:$(NC)"
	kubectl get pods | grep -v "Running\|Completed"
	@echo ""
	@echo "$(YELLOW)4. Événements des pods en erreur:$(NC)"
	for pod in $$(kubectl get pods --no-headers | grep -v "Running\|Completed" | awk '{print $$1}'); do \
		echo "$(GREEN)Pod: $$pod$(NC)"; \
		kubectl describe pod $$pod | grep -A 10 "Events:" || true; \
		echo ""; \
	done 