# Add Kruize - AI-Powered Kubernetes Optimization Service

## 📋 Overview

Kruize provides intelligent, AI-powered resource optimization recommendations for Kubernetes workloads. It analyzes historical performance data and uses machine learning to generate cost-effective resource configurations while maintaining application performance.

## 🎯 Service Details

**Service Name**: Kruize  
**Version**: v1  
**Category**: Performance Optimization / Cost Management  
**Deployment Method**: Kustomize + Operator

## 🚀 Key Features

- **Automated Resource Recommendations**: ML-based analysis of CPU/memory usage patterns
- **Cost Optimization**: Identifies over-provisioned resources to reduce cloud costs
- **Performance Profiling**: Tracks application performance metrics over time
- **Multi-Cluster Support**: Centralized optimization across multiple Kubernetes clusters
- **Web UI**: Interactive dashboard for visualization and analysis
- **API-First Design**: RESTful API for programmatic access

## 📦 Components

| Component | Version | Purpose |
|-----------|---------|---------|
| Kruize Operator | 0.0.5 | Lifecycle management and reconciliation |
| Autotune | 0.9 | Core optimization engine |
| Optimizer | 0.0.1 | ML-based recommendation generator |
| UI | 0.1.0 | Web interface for visualization |
| PostgreSQL | 15.2 | Metrics and recommendations storage |

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Kruize Operator                       │
│              (Manages Lifecycle)                         │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
   ┌────▼───┐   ┌───▼────┐  ┌───▼─────┐
   │Autotune│   │Optimizer│  │   UI    │
   │(Core)  │   │  (ML)   │  │(Web UI) │
   └────┬───┘   └───┬────┘  └─────────┘
        │           │
        └─────┬─────┘
              │
        ┌─────▼──────┐
        │ PostgreSQL │
        │  (Metrics) │
        └────────────┘
```

## 📁 Files Included

```
services/kruize/v1/
├── catalog/
│   ├── catalog.yaml          # Service metadata
│   └── schema.json           # 10 configurable parameters
├── manifests/                # Complete Kustomize deployment
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   ├── kruize-crd.yaml
│   ├── operator-*.yaml       # Operator deployment & RBAC
│   ├── database-*.yaml       # PostgreSQL StatefulSet
│   ├── kruize-*.yaml         # Kruize CR & ConfigMaps
│   └── metering-configmap.yaml
├── sbom/                     # CycloneDX SBOMs for all images
├── deploy.sh                 # Automated deployment script
├── fix-security-contexts.sh  # OpenShift security compliance
├── generate-sboms.sh         # SBOM generation helper
└── README.md                 # Complete documentation

application-sets/
└── kruize-kustomize.yaml     # ArgoCD ApplicationSet
```

## ✅ Testing Completed

### Deployment Testing
- ✅ Fresh deployment from scratch
- ✅ All 5 pods reach Running state
- ✅ Operator successfully reconciles Kruize CR
- ✅ Database operational with persistent storage
- ✅ API endpoints responding
- ✅ UI accessible via OpenShift route
- ✅ Cleanup and redeploy tested successfully

### Security & Compliance
- ✅ OpenShift restricted SCC compliance
- ✅ Security contexts properly configured
- ✅ Non-root containers
- ✅ Read-only root filesystems where applicable
- ✅ Capabilities dropped
- ✅ Seccomp profiles set to RuntimeDefault

### RBAC & Permissions
- ✅ ClusterRole with comprehensive permissions (370+ lines)
- ✅ Namespace-scoped Role for operator
- ✅ ServiceAccounts properly configured
- ✅ Leader election permissions included

## 🔧 Known Issues & Solutions

### Issue 1: Operator-Generated Deployment Security Context
**Problem**: The operator creates the kruize deployment without proper security contexts, causing pod creation failures in OpenShift restricted namespaces.

**Solution**: Automated patch script (`fix-security-contexts.sh`) that runs post-deployment to add required security contexts. This is integrated into the main `deploy.sh` script.

### Issue 2: Database Service Selector Mismatch
**Problem**: Operator creates service with `app: kruize-db` selector, but our StatefulSet used `app.kubernetes.io/name: kruize-db`.

**Solution**: Added both labels to StatefulSet pods for compatibility.

## 📊 Configuration Parameters

The service exposes 10 configurable parameters via `schema.json`:

1. **cluster_type**: Target cluster type (openshift/minikube/kind)
2. **namespace**: Deployment namespace
3. **autotune_image**: Autotune container image
4. **autotune_ui_image**: UI container image  
5. **optimizer_image**: Optimizer container image
6. **log_level**: Logging verbosity
7. **prometheus_url**: Metrics source URL
8. **db_storage_size**: Database PVC size
9. **db_storage_class**: Storage class for database
10. **enable_metering**: Toggle metering integration

## 🔐 Security Considerations

- All images from trusted Quay.io repositories
- SBOMs provided for supply chain security
- Secrets managed via Kubernetes Secrets
- Database credentials configurable
- Network policies can be applied
- RBAC follows principle of least privilege

## 📈 Resource Requirements

**Minimum**:
- CPU: 2.5 cores total
- Memory: 3GB total
- Storage: 500Mi for database

**Recommended**:
- CPU: 4 cores total
- Memory: 5GB total  
- Storage: 2Gi for database

## 🎓 Use Cases

1. **Cost Optimization**: Identify and eliminate resource waste
2. **Right-Sizing**: Automatically adjust resource requests/limits
3. **Performance Tuning**: Optimize for specific performance goals
4. **Capacity Planning**: Predict future resource needs
5. **Multi-Tenant Optimization**: Optimize across multiple namespaces

## 📚 Documentation

- **README.md**: Complete deployment and usage guide
- **SUBMISSION_STEPS.md**: Detailed submission process
- **catalog.yaml**: Service metadata and capabilities
- **schema.json**: Parameter definitions and validation

## 🔗 References

- **Kruize GitHub**: https://github.com/kruize/autotune
- **Kruize Operator**: https://github.com/kruize/kruize-operator
- **Documentation**: https://kruize.github.io/autotune/

## 🧪 Deployment Instructions

### Quick Deploy
```bash
oc apply -k services/kruize/v1/manifests/
```

### With ArgoCD
```bash
oc apply -f application-sets/kruize-kustomize.yaml
```

### Verify Deployment
```bash
oc get pods -n openshift-tuning
oc get routes -n openshift-tuning
```

## 📸 Screenshots

(Screenshots will be attached to PR showing):
1. All pods running
2. Routes available
3. UI homepage
4. API health check
5. Kruize CR status

## ✨ Submission Checklist

- [x] Service metadata complete (catalog.yaml)
- [x] Parameter schema defined (schema.json)
- [x] Kustomize manifests tested
- [x] SBOMs generated for all images
- [x] README documentation complete
- [x] ApplicationSet created
- [x] Deployment tested end-to-end
- [x] Security compliance verified
- [x] All pods running successfully

## 👥 Contributors

Submitted for IBM Sovereign Core Catalogathon

---

**Note**: This service has been thoroughly tested on OpenShift 4.14+ and is ready for production use in sovereign cloud environments.