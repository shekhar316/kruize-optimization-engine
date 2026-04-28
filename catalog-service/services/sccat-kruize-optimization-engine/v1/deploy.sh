#!/bin/bash
set -e

NAMESPACE="openshift-tuning"

echo "🚀 Deploying Kruize to OpenShift..."
echo "Namespace: $NAMESPACE"
echo ""

# Deploy everything
echo "📦 Applying Kustomize manifests..."
oc apply -k manifests/

echo ""
echo "⏳ Waiting for pods to be ready..."
sleep 10

echo ""
echo "⏳ Waiting for all pods to be ready..."
sleep 20

echo ""
echo "📊 Current Status:"
oc get pods -n $NAMESPACE

echo ""
echo "✅ Deployment complete!"
echo ""
echo "To check status:"
echo "  oc get pods -n $NAMESPACE"
echo "  oc logs -l control-plane=kruize-operator -n $NAMESPACE"
echo "  oc get kruize -n $NAMESPACE"

