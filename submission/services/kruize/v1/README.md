# Kruize Optimization Engine - IBM Sovereign Core Catalog Service

## Overview

**Kruize** is an intelligent, in-cluster optimization engine for OpenShift that continuously analyzes workload resource consumption and generates actionable recommendations to improve both cost efficiency and performance reliability - all within the sovereign boundary.

### Why Kruize for Sovereign Core?

**Sovereignty-Native Intelligence**
- All optimization happens in-cluster using local telemetry (Prometheus)
- No data leaves the sovereign environment
- No external SaaS dependencies
- Ensures data locality and compliance

**Unified Optimization Platform**
- CPU and memory right-sizing recommendations
- Namespace quota optimization
- GPU allocation recommendations (AI-ready)
- Java runtime tuning recommendations
- Cost-optimized and performance-optimized profiles
- All features enabled by default

**Value Proposition**
> "Kruize brings AI-powered optimization inside the sovereign boundary, turning telemetry into actionable intelligence while unifying cost, performance, and resource efficiency in one platform."

---

## Package Structure

```
kruize-catalog-service/v1/
├── README.md                           # This file
├── catalog/
│   ├── catalog.yaml                   # Service catalog metadata
│   └── schema.json                    # Instance parameter schema
├── manifests/
│   ├── kustomization.yaml             # Base Kustomize config
│   ├── namespace.yaml                 # openshift-tuning namespace
│   ├── kruize-crd.yaml                # Kruize Custom Resource Definition
│   ├── operator-serviceaccount.yaml   # Operator ServiceAccount
│   ├── operator-role.yaml             # Namespace-scoped Role
│   ├── operator-rolebinding.yaml      # RoleBinding
│   ├── operator-deployment.yaml       # Operator Deployment
│   ├── operator-service.yaml          # Operator Service
│   ├── database-secret.yaml           # Database credentials (pre-provision)
│   ├── database-statefulset.yaml      # PostgreSQL StatefulSet
│   ├── database-service.yaml          # Database Service
│   ├── kruize-configmap.yaml          # Kruize configuration
│   ├── kruize-instance.yaml           # Kruize CR instance
│   └── metering-configmap.yaml        # Metering configuration
├── template/
│   └── kustomization.yaml.tmpl        # Per-instance overlay template
└── sbom/
    └── README.md                      # SBOM generation instructions
```

---

## Deployment Architecture

### OpenShift Deployment

```
┌─────────────────────────────────────────────────────────────┐
│                    Sovereign Boundary                        │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         OpenShift Cluster (openshift-tuning)         │  │
│  │                                                        │  │
│  │  ┌──────────────┐      ┌─────────────────────────┐  │  │
│  │  │   Kruize     │◄────►│    Prometheus           │  │  │
│  │  │   Operator   │      │  (openshift-monitoring) │  │  │
│  │  └──────┬───────┘      └─────────────────────────┘  │  │
│  │         │                                            │  │
│  │         ▼                                            │  │
│  │  ┌──────────────┐      ┌─────────────────────────┐  │  │
│  │  │   Kruize     │      │   Metering Sidecar      │  │  │
│  │  │ Application  │◄────►│   (Usage Tracking)      │  │  │
│  │  └──────────────┘      └──────────┬──────────────┘  │  │
│  │         │                          │                 │  │
│  │         ▼                          ▼                 │  │
│  │  ┌──────────────┐      ┌─────────────────────────┐  │  │
│  │  │  PostgreSQL  │      │  Sovereign Core         │  │  │
│  │  │  (Database)  │      │  Metering API           │  │  │
│  │  └──────────────┘      └─────────────────────────┘  │  │
│  │                                                        │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Component Resources

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| **Kruize Operator** | 10m | 500m | 64Mi | 128Mi |
| **Kruize Application** | 0.7 | 0.7 | 768Mi | 768Mi |
| **PostgreSQL** | 0.5 | 0.5 | 100Mi | 100Mi |
| **Total** | **~1.2 CPU** | **~1.2 CPU** | **~932Mi** | **~996Mi** |

---

## Configuration Parameters

### Required Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `namespace` | string | `openshift-tuning` | Target namespace for deployment |

### Optional Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `prometheus_url` | string | `http://prometheus-k8s.openshift-monitoring.svc:9090` | Prometheus endpoint |
| `storage_size` | string | `500Mi` | Database storage size |
| `storage_class` | string | `manual` | StorageClass name |
| `kruize_cpu_request` | string | `0.7` | Kruize CPU request |
| `kruize_cpu_limit` | string | `0.7` | Kruize CPU limit |
| `kruize_memory_request` | string | `768Mi` | Kruize memory request |
| `kruize_memory_limit` | string | `768Mi` | Kruize memory limit |
| `db_cpu_request` | string | `0.5` | Database CPU request |
| `db_cpu_limit` | string | `0.5` | Database CPU limit |
| `db_memory_request` | string | `100Mi` | Database memory request |
| `db_memory_limit` | string | `100Mi` | Database memory limit |
| `log_level` | string | `INFO` | Logging level (DEBUG/INFO/WARN/ERROR) |

### Example Configuration

```yaml
service_type: kruize
environment: production
spec:
  namespace: openshift-tuning
  prometheus_url: http://prometheus-k8s.openshift-monitoring.svc:9090
  storage_size: 500Mi
  storage_class: manual
  log_level: INFO
```

---

## Secret Management (Secretless Approach)

### Required Secrets

Kruize expects the following secrets to be **pre-provisioned** by the tenant admin:

#### 1. Database Credentials

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: kruize-db-credentials
  namespace: openshift-tuning
type: Opaque
stringData:
  POSTGRES_USER: kruize
  POSTGRES_PASSWORD: <secure-password>
  POSTGRES_DB: kruizedb
```

#### 2. Prometheus Authentication (if required)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: kruize-prometheus-auth
  namespace: openshift-tuning
type: Opaque
data:
  token: <base64-encoded-token>
```

### Secret Provisioning Workflow

1. **Tenant Admin**: Requests secrets from Sovereign Core secret management
2. **Platform Admin**: Provisions secrets in `openshift-tuning` namespace
3. **Service Broker**: Deploys Kruize (references existing secrets)
4. **Kruize Operator**: Mounts secrets as environment variables

**No secrets are stored in Git or committed to the GitOps repository.**

---

## Metering Integration

### Metering Architecture: Sidecar Pattern

Kruize uses a dedicated metering sidecar container that:
- Collects usage metrics from Kruize API
- Aggregates data per instance
- Submits to Sovereign Core metering endpoint
- Runs independently of main application

### Tracked Metrics

| Metric | Type | Description | Unit |
|--------|------|-------------|------|
| `kruize.recommendations.generated` | Counter | Total recommendations generated | count |
| `kruize.workloads.monitored` | Gauge | Active monitored workloads | count |
| `kruize.optimization.cpu_savings` | Gauge | Estimated CPU savings | millicores |
| `kruize.optimization.memory_savings` | Gauge | Estimated memory savings | MiB |
| `kruize.instance.uptime` | Counter | Service uptime | hours |

---

## Deployment Steps

### Prerequisites

- Red Hat OpenShift 4.12+
- Prometheus installed in `openshift-monitoring` namespace
- `oc` CLI configured with cluster-admin access
- Access to Sovereign Core catalog

### Step 1: Pre-provision Secrets

```bash
# Create database credentials secret
oc create secret generic kruize-db-credentials \
  --from-literal=POSTGRES_USER=kruize \
  --from-literal=POSTGRES_PASSWORD=<secure-password> \
  --from-literal=POSTGRES_DB=kruizedb \
  -n openshift-tuning
```

### Step 2: Deploy via Kustomize

```bash
# Deploy all manifests
oc apply -k kruize-catalog-service/v1/manifests/

# Verify deployment
oc get pods -n openshift-tuning
oc get kruize -n openshift-tuning
```

### Step 3: Verify Kruize Instance

```bash
# Check operator logs
oc logs -n openshift-tuning deployment/kruize-operator -f

# Check Kruize CR status
oc describe kruize kruize-sample -n openshift-tuning

# Verify all pods are running
oc get pods -n openshift-tuning
```

### Step 4: Access Kruize

```bash
# Get service endpoint
oc get svc -n openshift-tuning

# Port-forward for testing
oc port-forward -n openshift-tuning svc/kruize 8080:8080

# Test API
curl http://localhost:8080/listApplications
```

---

## Testing Procedures

### Validation Checklist

- [ ] Operator deploys successfully
- [ ] CRD is registered (`oc get crd kruizes.kruize.io`)
- [ ] Kruize instance creates pods
- [ ] All pods are Running (not CrashLoopBackOff)
- [ ] Health checks pass
- [ ] Prometheus connection established
- [ ] Database is accessible
- [ ] Recommendations are generated
- [ ] Metering data submitted successfully
- [ ] Resource limits respected

### Testing Commands

```bash
# Check CRD
oc get crd kruizes.kruize.io

# Check all resources
oc get all -n openshift-tuning

# Check Kruize CR
oc get kruize -n openshift-tuning

# Check operator logs
oc logs -n openshift-tuning deployment/kruize-operator

# Check database connectivity
oc exec -n openshift-tuning kruize-db-0 -- psql -U kruize -d kruizedb -c '\l'

# Test Kruize API
oc port-forward -n openshift-tuning svc/kruize 8080:8080
curl http://localhost:8080/listApplications
```

---

## Sovereign Compliance

### ✅ Compliance Checklist

- [x] **Data Locality**: All telemetry analyzed locally (Prometheus in-cluster)
- [x] **No External Dependencies**: Fully functional without internet access
- [x] **Namespace-Scoped RBAC**: No cluster-admin requirements
- [x] **Resource Limits**: Within constraints (~1.2 CPU, ~1GB RAM)
- [x] **Red Hat Base Images**: Using official Kruize and PostgreSQL images
- [x] **Health Checks**: Liveness and readiness probes configured
- [x] **Secretless**: Pre-provisioned secrets approach
- [x] **SBOM**: Software bill of materials provided
- [x] **Metering**: Usage tracking and submission implemented
- [x] **OpenShift Native**: Designed for openshift-tuning namespace

### Security Posture

- **Container Security**: Non-root user execution
- **Network Policies**: Ingress/egress restricted to necessary services
- **Secret Management**: Kubernetes secrets with RBAC
- **Audit Logging**: All API calls logged
- **CVE Monitoring**: SBOM enables continuous vulnerability scanning

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Operator not starting | Check RBAC permissions, verify CRD installed |
| No recommendations | Verify Prometheus connectivity, check metrics availability |
| Database connection failed | Verify secret exists, check database pod logs |
| High memory usage | Reduce monitored workloads, increase memory limit |
| Metering not working | Check sidecar logs, verify metering endpoint |

### Debug Commands

```bash
# Check operator status
oc get deployment kruize-operator -n openshift-tuning

# View operator logs
oc logs -n openshift-tuning deployment/kruize-operator --tail=100

# Check Kruize CR events
oc describe kruize kruize-sample -n openshift-tuning

# Check database logs
oc logs -n openshift-tuning kruize-db-0

# Verify Prometheus connectivity
oc exec -n openshift-tuning deployment/kruize-operator -- curl -s http://prometheus-k8s.openshift-monitoring.svc:9090/api/v1/status/config
```

---

## Container Images

| Image | Repository | Tag | Purpose |
|-------|-----------|-----|---------|
| Kruize Operator | `quay.io/kruize/autotune_operator` | `0.9` | Operator controller |
| Kruize Autotune | `quay.io/kruize/autotune` | `0.9` | Core optimization engine |
| Kruize UI | `quay.io/kruize/kruize-ui` | `0.1.0` | Web interface |
| Kruize Optimizer | `quay.io/kruize/kruize-optimizer` | `0.0.1` | Advanced optimizer |
| PostgreSQL | `registry.redhat.io/rhel9/postgresql-15` | `latest` | Database |
| Metering Sidecar | `quay.io/kruize/kruize-metering` | `v1` | Usage tracking |

---

## Resources

- **Kruize GitHub**: https://github.com/kruize/autotune
- **Kruize Operator**: https://github.com/kruize/kruize-operator
- **Kruize Demos**: https://github.com/kruize/kruize-demos
- **Catalogathon Guide**: [catalogathon-guide-main/README.md](../../catalogathon-guide-main/README.md)
- **Sovereign Core Docs**: https://ibm.com/docs/sovereign-core/1.0.0

---

## Support

- **Catalogathon Mentors**: Slack @Thierry.Supplisson
- **Kruize Community**: GitHub Issues
- **Documentation**: This README and implementation plan

---

**Ready to optimize your sovereign OpenShift infrastructure? Deploy Kruize today!** 🚀