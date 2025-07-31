# Configuration HTTPS pour OroCommerce

Ce document explique comment configurer HTTPS pour OroCommerce avec des certificats SSL.

## 🎯 **Vue d'ensemble**

La configuration HTTPS utilise :
- **Ingress NGINX Controller** : Pour la terminaison TLS
- **Certificats SSL** : Auto-signés pour le développement
- **HSTS** : HTTP Strict Transport Security activé
- **Redirection automatique** : HTTP → HTTPS

## 📋 **Prérequis**

1. **Ingress NGINX Controller** installé dans le cluster
2. **OpenSSL** installé sur votre machine
3. **kubectl** configuré pour votre cluster

### Vérifier l'Ingress Controller

```bash
# Vérifier que l'Ingress Controller est installé
kubectl get pods -n ingress-nginx

# Vérifier les services Ingress
kubectl get svc -n ingress-nginx
```

## 🔐 **Configuration HTTPS**

### 1. **Générer le certificat SSL**

```bash
# Générer le certificat auto-signé
make ssl-cert
```

Cette commande :
- Génère un certificat auto-signé pour `oro.demo`
- Crée un secret Kubernetes `oro-demo-tls`
- Configure les bonnes permissions

### 2. **Déployer avec HTTPS**

```bash
# Installer/upgrader avec l'Ingress HTTPS
make upgrade
```

### 3. **Accéder à l'application**

```bash
# Configurer le fichier hosts (si pas déjà fait)
echo "127.0.0.1 oro.demo" | sudo tee -a /etc/hosts

# Accéder à l'application
# https://oro.demo
```

## ⚙️ **Configuration de l'Ingress**

### **Annotations utilisées**

```yaml
annotations:
  # Redirection HTTPS
  nginx.ingress.kubernetes.io/ssl-redirect: "true"
  nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
  
  # HSTS (HTTP Strict Transport Security)
  nginx.ingress.kubernetes.io/hsts: "true"
  nginx.ingress.kubernetes.io/hsts-max-age: "31536000"
  nginx.ingress.kubernetes.io/hsts-include-subdomains: "true"
  nginx.ingress.kubernetes.io/hsts-preload: "true"
  
  # Configuration OroCommerce
  nginx.ingress.kubernetes.io/proxy-body-size: "512m"
  nginx.ingress.kubernetes.io/proxy-connect-timeout: "180"
  nginx.ingress.kubernetes.io/proxy-send-timeout: "180"
  nginx.ingress.kubernetes.io/proxy-read-timeout: "180"
  nginx.ingress.kubernetes.io/proxy-buffer-size: "8k"
  nginx.ingress.kubernetes.io/proxy-buffers-number: "32"
```

### **Configuration TLS**

```yaml
spec:
  tls:
    - hosts:
        - oro.demo
      secretName: oro-demo-tls
```

## 🔍 **Vérification**

### **Vérifier l'Ingress**

```bash
# Vérifier l'Ingress
kubectl get ingress

# Détails de l'Ingress
kubectl describe ingress webserver-orocommerce-ingress
```

### **Vérifier le certificat**

```bash
# Vérifier le secret TLS
kubectl get secret oro-demo-tls

# Détails du certificat
kubectl describe secret oro-demo-tls
```

### **Tester la connexion**

```bash
# Tester HTTPS
curl -k https://oro.demo

# Vérifier les redirections
curl -I http://oro.demo
# Devrait rediriger vers HTTPS
```

## 🚨 **Dépannage**

### **Problème : Certificat non reconnu**

**Cause :** Certificat auto-signé
**Solution :** Acceptez l'exception dans votre navigateur

### **Problème : Erreur de certificat**

```bash
# Vérifier l'ordre des certificats
kubectl get secret oro-demo-tls -o yaml

# Régénérer le certificat
make ssl-delete
make ssl-cert
```

### **Problème : Ingress non accessible**

```bash
# Vérifier l'Ingress Controller
kubectl get pods -n ingress-nginx

# Vérifier les services
kubectl get svc -n ingress-nginx

# Logs de l'Ingress Controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

## 🔄 **Gestion des certificats**

### **Renouveler le certificat**

```bash
# Supprimer l'ancien
make ssl-delete

# Générer le nouveau
make ssl-cert

# Redéployer
make upgrade
```

### **Certificat en production**

Pour un certificat valide en production :

1. **Installer cert-manager**
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

2. **Configurer Let's Encrypt**
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

3. **Mettre à jour l'Ingress**
```yaml
annotations:
  cert-manager.io/issuer: "letsencrypt-prod"
```

## 📚 **Références**

- [Kubernetes Ingress NGINX TLS](https://kubernetes.github.io/ingress-nginx/user-guide/tls/)
- [cert-manager Documentation](https://cert-manager.io/docs/)
- [Let's Encrypt](https://letsencrypt.org/)

## ⚠️ **Notes importantes**

1. **Certificat auto-signé** : Votre navigateur affichera un avertissement
2. **Développement uniquement** : Pour la production, utilisez cert-manager
3. **HSTS** : Active la sécurité stricte HTTPS
4. **Redirection automatique** : HTTP → HTTPS forcé

---

**Configuration HTTPS prête pour le développement ! 🔒** 