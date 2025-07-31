#!/bin/bash

# Script pour générer les certificats SSL pour OroCommerce
# Usage: ./scripts/generate-ssl-cert.sh

set -e

CERT_NAME="oro-demo-tls"
KEY_FILE="oro-demo.key"
CERT_FILE="oro-demo.crt"
HOST="oro.demo"
NAMESPACE="orocommerce"

echo "🔐 Génération des certificats SSL pour OroCommerce..."

# Vérifier si le secret existe déjà
if kubectl get secret $CERT_NAME -n $NAMESPACE >/dev/null 2>&1; then
    echo "⚠️  Le secret $CERT_NAME existe déjà dans le namespace $NAMESPACE"
    echo "📋 Pour le supprimer : kubectl delete secret $CERT_NAME -n $NAMESPACE"
    read -p "Voulez-vous le supprimer et recréer ? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl delete secret $CERT_NAME -n $NAMESPACE
    else
        echo "❌ Opération annulée"
        exit 1
    fi
fi

# Générer le certificat auto-signé
echo "📝 Génération du certificat auto-signé pour $HOST..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout $KEY_FILE \
    -out $CERT_FILE \
    -subj "/CN=$HOST/O=$HOST" \
    -addext "subjectAltName = DNS:$HOST"

# Créer le secret Kubernetes
echo "🔧 Création du secret Kubernetes..."
kubectl create secret tls $CERT_NAME \
    --key $KEY_FILE \
    --cert $CERT_FILE \
    -n $NAMESPACE

# Nettoyer les fichiers temporaires
rm -f $KEY_FILE $CERT_FILE

echo "✅ Certificat SSL créé avec succès !"
echo "📋 Secret créé : $CERT_NAME dans le namespace $NAMESPACE"
echo ""
echo "🌐 Vous pouvez maintenant accéder à :"
echo "   - HTTPS : https://oro.demo"
echo "   - HTTP sera automatiquement redirigé vers HTTPS"
echo ""
echo "⚠️  Note : Ce certificat est auto-signé, votre navigateur affichera un avertissement"
echo "   Pour un certificat valide en production, utilisez cert-manager avec Let's Encrypt" 