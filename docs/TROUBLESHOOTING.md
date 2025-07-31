# Troubleshooting - Problèmes rencontrés et solutions

Ce document détaille tous les problèmes rencontrés lors de la mise en place de l'architecture Kubernetes OroCommerce et leurs solutions.

## 📋 **Table des matières**

1. [Problèmes de nommage et conventions](#problèmes-de-nommage)
2. [Problèmes de configuration SMTP](#problèmes-smtp)
3. [Problèmes de dépendances Helm](#problèmes-helm)
4. [Problèmes de configuration réseau](#problèmes-réseau)
5. [Problèmes de volumes persistants](#problèmes-volumes)
6. [Problèmes de services](#problèmes-services)

## 🏷️ **Problèmes de nommage et conventions**

### **Problème 1 : Incohérence des noms de services**

**Symptômes :**
- Erreurs de résolution DNS
- Services non trouvés
- Connexions échouées

**Cause :**
Les services Helm généraient des noms dynamiques (`mail-{release-name}`) mais la configuration OroCommerce cherchait des noms fixes (`mail`).

**Solution appliquée :**
```yaml
# charts/mail/templates/service.yaml
metadata:
  name: mail  # Nom fixe au lieu de {{ include "mail.fullname" . }}
```

**Résultat :**
- ✅ Service MailHog accessible sur `mail:1025`
- ✅ Configuration OroCommerce compatible
- ✅ Résolution DNS fonctionnelle



## 📧 **Problèmes de configuration SMTP**

### **Problème 3 : Erreur SMTP `[PROTO: INVALID]`**

**Symptômes :**
```
[PROTO: INVALID] Started session, switching to ESTABLISH state
[SMTP 10.244.0.1:34246] Sent 35 bytes: '220 mailhog.example ESMTP MailHog\r\n'
[SMTP 10.244.0.1:34246] Connection closed by remote host
```

**Cause :**
1. **Nom de service incohérent** : OroCommerce cherchait `mail:1025` mais le service s'appelait `mail-{release-name}`
2. **Protocole SMTP incorrect** : Le client n'envoyait pas les bonnes commandes SMTP

**Solutions appliquées :**

#### **Solution 1 : Nom de service fixe**
```yaml
# charts/mail/templates/service.yaml
metadata:
  name: mail  # Nom fixe
```

#### **Solution 2 : Configuration OroCommerce**
```yaml
# charts/orocommerce/templates/configmap.yaml
ORO_MAILER_DSN: "smtp://mail:1025"
```

#### **Solution 3 : Service UI séparé**
```yaml
# charts/mail/templates/ui-service.yaml
metadata:
  name: mail-ui  # Interface web séparée
```

**Résultat :**
- ✅ Service SMTP accessible
- ✅ Interface MailHog disponible
- ✅ Configuration OroCommerce compatible

## 📦 **Problèmes de dépendances Helm**

### **Problème 4 : Fichiers .tgz dans Git**

**Symptômes :**
- Repository volumineux
- Conflits de maintenance
- Incohérences entre source et package

**Cause :**
Les fichiers `.tgz` étaient commités dans Git alors qu'ils sont générés automatiquement.

**Solution appliquée :**

#### **1. Ajout au .gitignore**
```gitignore
# Helm chart packages
charts/*/charts/*.tgz
charts/*/charts/*.tar.gz
```

#### **2. Suppression du tracking Git**
```bash
git rm --cached charts/orocommerce/charts/*.tgz
```

#### **3. Script de gestion**
```bash
# scripts/helm-deps.sh
./scripts/helm-deps.sh update  # Régénère les .tgz
./scripts/helm-deps.sh clean   # Supprime les .tgz
```

**Résultat :**
- ✅ Repository plus léger
- ✅ Cohérence garantie
- ✅ Workflow de développement propre

### **Problème 5 : Structure des helpers incomplète**

**Symptômes :**
- Labels manquants
- Incohérences entre charts
- Erreurs de déploiement

**Cause :**
Certains charts n'avaient pas tous les helpers Helm standards.

**Solution appliquée :**
```yaml
# Structure complète pour tous les charts
{{- define "{component}.name" -}}
{component-name}
{{- end }}

{{- define "{component}.fullname" -}}
{{ include "{component}.name" . }}-{{ .Release.Name }}
{{- end }}

{{- define "{component}.labels" -}}
helm.sh/chart: {{ include "{component}.chart" . }}
{{ include "{component}.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "{component}.selectorLabels" -}}
app.kubernetes.io/name: {{ include "{component}.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

**Résultat :**
- ✅ Labels standards partout
- ✅ Cohérence entre charts
- ✅ Conformité Kubernetes

## 🌐 **Problèmes de configuration réseau**

### **Problème 6 : Accès à l'application**

**Symptômes :**
- Application non accessible sur `localhost:8080`
- Erreurs de connexion
- Configuration OroCommerce incorrecte

**Cause :**
OroCommerce est configuré pour fonctionner avec le domaine `oro.demo`, pas `localhost`.

**Solution appliquée :**

#### **1. Configuration du fichier hosts**
```bash
# /etc/hosts
127.0.0.1 oro.demo
```

#### **2. Documentation claire**
```markdown
# README.md
**Important** : Utilisez http://oro.demo:8080, pas localhost:8080
```

#### **3. Script de configuration**
```bash
# scripts/setup-hosts.sh
echo "127.0.0.1 oro.demo" | sudo tee -a /etc/hosts
```

**Résultat :**
- ✅ Application accessible sur `oro.demo:8080`
- ✅ Configuration automatique
- ✅ Documentation claire



## 💾 **Problèmes de volumes persistants**

### **Problème 8 : Labels non standards sur les PVC**

**Symptômes :**
- PVC non trouvés
- Erreurs de montage
- Incohérences de labels

**Cause :**
Les PVC utilisaient l'ancienne convention `app:` au lieu des labels standards Kubernetes.

**Solution appliquée :**
```yaml
# charts/database/templates/statefulset.yaml
metadata:
  labels:
    {{- include "database.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels:
      {{- include "database.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "database.selectorLabels" . | nindent 8 }}
```

**Résultat :**
- ✅ Labels standards
- ✅ Cohérence avec Kubernetes
- ✅ Meilleure organisation



## 🔧 **Problèmes de services**

### **Problème 10 : Services avec anciennes conventions**

**Symptômes :**
- Services non trouvés
- Erreurs de sélecteurs
- Incohérences de labels

**Cause :**
Les services utilisaient encore l'ancienne convention `app:`.

**Solution appliquée :**
```yaml
# charts/database/templates/service.yaml
metadata:
  labels:
    {{- include "database.labels" . | nindent 4 }}
spec:
  selector:
    {{- include "database.selectorLabels" . | nindent 4 }}
```

**Résultat :**
- ✅ Labels standards
- ✅ Sélecteurs cohérents
- ✅ Services fonctionnels

## 📊 **Résumé des corrections**

### **Corrections appliquées :**

| Problème | Solution | Impact |
|----------|----------|--------|
| Noms de services | Noms fixes | ✅ Résolution DNS |
| SMTP | Service `mail` fixe | ✅ Email fonctionnel |
| Dépendances Helm | .gitignore + scripts | ✅ Repository propre |
| Configuration réseau | Fichier hosts | ✅ Accès application |
| Labels | Standards Kubernetes | ✅ Cohérence |

### **Bonnes pratiques établies :**

1. **Nommage cohérent** : Noms descriptifs et fixes
2. **Labels standards** : Utilisation des conventions Kubernetes
3. **Gestion des dépendances** : Pas de .tgz dans Git
4. **Documentation** : Instructions claires et complètes
5. **Scripts d'automatisation** : Configuration facile

## 🚀 **Leçons apprises**

### **1. Importance des conventions**
- Les conventions Kubernetes sont cruciales
- La cohérence des noms évite les erreurs
- Les labels standards facilitent la gestion

### **2. Gestion des dépendances**
- Ne jamais commiter les fichiers générés
- Automatiser les tâches répétitives
- Documenter les workflows

### **3. Configuration réseau**
- Tester les accès dès le début
- Documenter les prérequis
- Fournir des scripts d'automatisation

### **4. Monitoring et debugging**
- Logs détaillés essentiels
- Commandes de diagnostic
- Documentation des problèmes courants

## 📚 **Références**

- [Kubernetes Label Conventions](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [OroCommerce Documentation](https://doc.oroinc.com/)

---

**Ce document sera mis à jour au fur et à mesure de la découverte de nouveaux problèmes et solutions.** 