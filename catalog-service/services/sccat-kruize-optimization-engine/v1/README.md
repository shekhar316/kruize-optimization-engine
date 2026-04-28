# Kruize Optimization Engine - Catalogathon Submission

## Overview

Kruize is an AI-powered Kubernetes optimization engine that provides intelligent resource recommendations to optimize application performance and reduce costs.

## Pre-Deployment Requirements

### ⚠️ IMPORTANT: Pre-Provision Secrets

**This submission is secretless and requires secrets to be pre-provisioned before deployment.**

Before deploying Kruize, you MUST create the required database credentials secret:

```bash
# Apply the pre-deployment secrets file (located outside submission folder)
kubectl apply -f ../../../pre-deployment-secrets.yaml
```

**What this creates:**
- Secret name: `sccat-kruize-db-credentials`
- Namespace: `openshift-tuning`
- Contains: PostgreSQL database credentials

**Security Note:**
- Update the secret values in `pre-deployment-secrets.yaml` before applying
- Never commit actual credentials to Git
- Use your organization's secret management system in production
- The provided values are examples for demo purposes only

## Deployment

### 1. Pre-provision Secrets (Required)
```bash
kubectl apply -f ../../../pre-deployment-secrets.yaml
```

### 2. Verify Secret Exists
```bash
kubectl get secret sccat-kruize-db-credentials -n openshift-tuning
```

### 3. Deploy Kruize
```bash
kubectl apply -k manifests/
```

## Architecture

### Components

1. **Kruize Operator** - Manages Kruize lifecycle
   - Resources: 0.5 CPU, 128Mi RAM
   - Rootless, non-privileged

2. **PostgreSQL Database** - Stores optimization data
   - Resources: 1 CPU, 2Gi RAM
   - Credentials from pre-provisioned secret
   - Persistent storage: 5Gi

3. **Autotune** - Core optimization engine
   - Resources: 0.7 CPU, 768Mi RAM
   - Analyzes workload metrics

4. **Optimizer** - Recommendation generator
   - Resources: 0.5 CPU, 512Mi RAM
   - Generates cost and performance recommendations

5. **Kruize UI** - Web interface
   - Resources: 0.2 CPU, 256Mi RAM
   - Modern React-based dashboard

**Total Resources:** 2.9 CPU, ~3.7Gi RAM (36% of 8 CPU limit)

## Security

- ✅ All containers run as non-root
- ✅ Security contexts: allowPrivilegeEscalation: false
- ✅ Capabilities dropped (ALL)
- ✅ Health probes configured
- ✅ Base images: Red Hat UBI minimal
- ✅ Secretless submission (secrets pre-provisioned)

**For detailed security documentation, see [SECURITY.md](./SECURITY.md):**
- Secret management best practices (External Secrets Operator, Sealed Secrets)
- CVE monitoring and remediation strategy
- SBOM generation and vulnerability scanning
- Dependency management and update procedures
- Runtime security and network policies

## Compliance

This submission meets all Catalogathon requirements:
- ✅ Naming: `sccat-kruize-optimization-engine` prefix
- ✅ GitOps: Broker-compatible structure with ApplicationSet
- ✅ Resources: All containers have limits, under 8 CPU
- ✅ Security: Rootless, least privilege, health checks
- ✅ Secrets: Pre-provisioned, not in submission
- ✅ Base Images: UBI minimal
- ✅ Manifests: Standard Kubernetes, declarative

## Support

For issues or questions, please refer to the main Kruize documentation.