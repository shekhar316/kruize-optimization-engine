# Security Documentation

## Secret Management Approach (Strongly Recommended)

### Current Implementation

**Secretless Submission:**
- Database credentials are NOT included in the submission
- Secrets must be pre-provisioned before deployment
- Reference file: `../../../pre-deployment-secrets.yaml` (outside submission folder)

### Recommended Production Approach

For production deployments, we **strongly recommend** using enterprise secret management solutions:

#### Option 1: External Secrets Operator (Recommended)
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: sccat-kruize-db-credentials
  namespace: openshift-tuning
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: sccat-kruize-db-credentials
    creationPolicy: Owner
  data:
  - secretKey: POSTGRES_PASSWORD
    remoteRef:
      key: kruize/database
      property: password
  - secretKey: POSTGRES_USER
    remoteRef:
      key: kruize/database
      property: username
  - secretKey: POSTGRES_DB
    remoteRef:
      key: kruize/database
      property: database
```

**Benefits:**
- Centralized secret management
- Automatic rotation support
- Audit logging
- Integration with HashiCorp Vault, AWS Secrets Manager, Azure Key Vault, etc.

#### Option 2: Sealed Secrets
```bash
# Encrypt secrets for Git storage
kubeseal --format=yaml < pre-deployment-secrets.yaml > sealed-secrets.yaml

# Safe to commit sealed-secrets.yaml to Git
# Only the cluster can decrypt it
```

**Benefits:**
- GitOps-friendly
- Encrypted at rest in Git
- Declarative secret management

#### Option 3: IBM Cloud Secrets Manager
For IBM Cloud deployments:
```yaml
apiVersion: ibmcloud.ibm.com/v1
kind: Secret
metadata:
  name: sccat-kruize-db-credentials
  namespace: openshift-tuning
spec:
  secretsManagerRef:
    name: my-secrets-manager
  secretName: kruize-database-credentials
```

### Secret Rotation Strategy

**Recommended rotation schedule:**
- Database passwords: Every 90 days
- API keys: Every 180 days
- Certificates: Before expiration

**Rotation process:**
1. Update secret in secret management system
2. External Secrets Operator automatically syncs
3. Restart database pods to pick up new credentials
4. Verify connectivity

### Security Best Practices

1. **Never commit secrets to Git**
   - Use `.gitignore` for secret files
   - Scan commits with tools like `git-secrets`

2. **Use strong passwords**
   - Minimum 16 characters
   - Mix of uppercase, lowercase, numbers, symbols
   - Generate with: `openssl rand -base64 32`

3. **Limit secret access**
   - Use RBAC to restrict who can read secrets
   - Audit secret access regularly

4. **Encrypt secrets at rest**
   - Enable Kubernetes secret encryption
   - Use encrypted storage backends

---

## CVE Mitigation Strategy (Recommended)

### Current Status

**Base Images:**
- All images built on Red Hat Universal Base Image (UBI) minimal
- UBI provides enterprise-grade security and regular updates
- Images: operator, postgres, autotune, optimizer, kruize-ui

### CVE Monitoring & Remediation

#### 1. Continuous Scanning

**Tools in use:**
- **Syft**: SBOM generation for all images
- **Grype**: CVE scanning against generated SBOMs
- **Trivy**: Additional vulnerability scanning

**Scan frequency:**
- Pre-deployment: Before pushing images
- Runtime: Weekly automated scans
- On-demand: After security advisories

#### 2. SBOM Generation

**Current implementation:**
```bash
# Generate SBOMs for all images
cd submission/services/sccat-kruize-optimization-engine/v1
./generate-sboms.sh

# Output: SBOMs in SPDX format for each image
# - kruize-operator-sbom.json
# - postgres-sbom.json
# - autotune-sbom.json
# - optimizer-sbom.json
# - kruize-ui-sbom.json
```

**SBOM benefits:**
- Complete software bill of materials
- Dependency tracking
- License compliance
- Vulnerability correlation

#### 3. Vulnerability Response Process

**Severity levels and response times:**

| Severity | Response Time | Action |
|----------|--------------|--------|
| Critical | 24 hours | Immediate patch, emergency release |
| High | 7 days | Prioritized fix, scheduled release |
| Medium | 30 days | Regular maintenance cycle |
| Low | 90 days | Backlog, next major release |

**Response workflow:**
1. **Detection**: Automated scan identifies CVE
2. **Assessment**: Evaluate impact and exploitability
3. **Remediation**: 
   - Update base image to patched UBI version
   - Update vulnerable dependencies
   - Rebuild and test images
4. **Deployment**: Push updated images to registry
5. **Notification**: Alert users via release notes

#### 4. Base Image Update Strategy

**Red Hat UBI updates:**
- Monitor Red Hat security advisories
- Subscribe to RHSA (Red Hat Security Advisory) notifications
- Rebuild images within 48 hours of UBI security updates

**Update process:**
```bash
# 1. Pull latest UBI minimal
podman pull registry.access.redhat.com/ubi9/ubi-minimal:latest

# 2. Rebuild all images
./build-all-images.sh

# 3. Scan for vulnerabilities
./scan-images.sh

# 4. Push to registry if clean
./push-images.sh
```

#### 5. Dependency Management

**Go dependencies (operator):**
```bash
# Regular updates
go get -u ./...
go mod tidy
go mod verify

# Security audit
go list -json -m all | nancy sleuth
```

**Python dependencies (optimizer, metering):**
```bash
# Security audit
pip-audit
safety check

# Update dependencies
pip install --upgrade -r requirements.txt
```

**Node.js dependencies (UI):**
```bash
# Security audit
npm audit
npm audit fix

# Update dependencies
npm update
```

#### 6. Runtime Security

**Pod Security Standards:**
- Enforced: `restricted` profile
- All containers run as non-root
- No privilege escalation
- Capabilities dropped
- Read-only root filesystem where possible

**Network Policies:**
```yaml
# Limit database access to only Kruize components
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: sccat-kruize-db-policy
  namespace: openshift-tuning
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: sccat-kruize-db
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app.kubernetes.io/part-of: sccat-kruize-optimization
    ports:
    - protocol: TCP
      port: 5432
```

#### 7. Compliance & Reporting

**Regular security reports:**
- Weekly: Automated CVE scan results
- Monthly: Dependency update summary
- Quarterly: Security posture review
- Annually: Comprehensive security audit

**Compliance standards:**
- CIS Kubernetes Benchmark
- NIST Cybersecurity Framework
- SOC 2 Type II (if applicable)

### Known Limitations (Demo Environment)

**For Catalogathon demo purposes:**
- Secrets use example values (must be changed for production)
- Certificate management not fully automated
- Some dependencies may have low-severity CVEs (non-exploitable in our context)

**Production recommendations:**
- Implement full secret rotation automation
- Use cert-manager for certificate lifecycle
- Establish formal vulnerability management program
- Conduct regular penetration testing

---

## Contact & Support

For security concerns or to report vulnerabilities:
- Email: security@kruize.io (example)
- Security advisories: Check release notes
- CVE database: Monitor Kruize GitHub security tab

**Responsible Disclosure:**
We follow a 90-day disclosure policy for security vulnerabilities.