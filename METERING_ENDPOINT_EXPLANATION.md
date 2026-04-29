# Metering Endpoint Explanation

## Question: How did we get the metering endpoint URL?

The metering endpoint `http://sovereign-core-metering.sovereign-core.svc.cluster.local:8080/api/v1/metering` is the **standard IBM Sovereign Core platform metering service endpoint**.

## Source Documentation

This endpoint is documented in the Catalogathon Guide:
- **File**: `catalogathon-guide-main/reference/reference-metering.md`
- **Section**: "Metering API"

## Endpoint Details

### Full Endpoint Structure
```
http://sovereign-core-metering.sovereign-core.svc.cluster.local:8080/api/v1/metering
```

### Breakdown:
- **Protocol**: `http://` (internal cluster communication)
- **Service Name**: `sovereign-core-metering`
- **Namespace**: `sovereign-core`
- **Cluster Domain**: `svc.cluster.local`
- **Port**: `8080`
- **API Path**: `/api/v1/metering`

## How It Works

### 1. Platform Service
The Sovereign Core platform provides a centralized metering service that:
- Runs in the `sovereign-core` namespace
- Accepts usage data from all catalog services
- Tracks resource consumption for billing and compliance
- Provides APIs for submitting and retrieving metering data

### 2. Service Discovery
Kubernetes DNS automatically resolves the service name:
```
sovereign-core-metering.sovereign-core.svc.cluster.local
```

This allows any pod in the cluster to reach the metering service using this FQDN.

### 3. API Endpoints

The metering service provides these key endpoints:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/metering/resources/{resource_id}/usage` | POST | Submit usage data for a service instance |
| `/api/v1/metering/usage/crns/{crn_encoded}` | GET | Retrieve usage data by CRN |
| `/api/v1/metering/usage/transactions/{transaction_id}` | GET | Fetch transaction details |

## Integration in Kruize

### Configuration Location
The endpoint is configured in:
```
kruize-optimization-engine/catalog-service/services/sccat-kruize-optimization-engine/v1/manifests/metering-configmap.yaml
```

### ConfigMap Content
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: sccat-kruize-metering-config
  namespace: openshift-tuning
data:
  metering_enabled: "true"
  metering_endpoint: "http://sovereign-core-metering.sovereign-core.svc.cluster.local:8080/api/v1/metering"
  metering_interval: "300"  # Submit every 5 minutes
```

### How Kruize Uses It

1. **Metering Sidecar**: A Python-based sidecar container runs alongside Kruize components
2. **Data Collection**: Collects metrics like:
   - Recommendations generated
   - Workloads monitored
   - CPU/memory savings
   - Instance uptime
3. **Submission**: Posts usage data to the metering endpoint every 5 minutes
4. **Authentication**: Uses Product Metering API token (generated during onboarding)

## Authentication Requirements

### Prerequisites
Before submitting metering data, you need:

1. **Product Registration**: Register your product with Sovereign Core
2. **Metering API Key**: Generate a product-specific metering API key
3. **Token Exchange**: Exchange API key for a bearer token
4. **Product ID Match**: Token's `productId` must match your registration

### Token Usage
```bash
curl --request POST \
  --url http://sovereign-core-metering.sovereign-core.svc.cluster.local:8080/api/v1/metering/resources/$INSTANCE_ID-subscription/usage \
  --header "Authorization: Bearer $PRODUCT_METERING_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "crn": "crn:v1:ibm-sc:private:kruize:...",
    "meteringPlan": "metered",
    "start": 1773878400000,
    "end": 1773882000000,
    "measured_usage": [{
      "quantity": 100.0,
      "measure": "recommendations_generated",
      "meteringModel": "cumulative"
    }]
  }'
```

## Metering Data Requirements

### Time Constraints
- ⚠️ **24-Hour Window**: Can only submit data for periods within last 24 hours
- Data older than 24 hours will be rejected

### Instance-Level Granularity
- ⚠️ **Per-Instance**: All submissions must be at instance level
- No account-level or product-level aggregation
- Each service instance reports its own usage

### Data Format
```json
{
  "crn": "crn:v1:ibm-sc:private:product:region:account:instance::",
  "meteringPlan": "metered",
  "start": 1773878400000,  // Unix timestamp in milliseconds
  "end": 1773882000000,
  "measured_usage": [
    {
      "quantity": 100.0,
      "measure": "metric_id",
      "meteringModel": "cumulative"  // or "delta"
    }
  ]
}
```

## Metering Models

### Cumulative
- Reports total accumulated value since instance start
- Example: Total API calls = 1000, 1100, 1200...
- Platform calculates delta between submissions

### Delta
- Reports incremental change since last submission
- Example: New API calls = 100, 100, 100...
- Platform sums deltas for total

## Testing Metering Integration

### Local Testing
For local development, you can use the dummy metering endpoint:
```
http://localhost:8080/api/v1/metering
```

Provided by: `catalogathon-meteringproxy` project

### Production Testing
1. Deploy to Sovereign Core cluster
2. Verify metering service is accessible
3. Submit test data
4. Retrieve via transaction ID or CRN
5. Monitor submission success rates

## Troubleshooting

### Common Issues

| Error | Cause | Solution |
|-------|-------|----------|
| 401 Unauthorized | Invalid/expired token | Regenerate from API key |
| 403 Forbidden | Product ID mismatch | Verify token productId matches registration |
| 400 Bad Request | Malformed CRN or payload | Validate CRN format and structure |
| 404 Not Found | Service not reachable | Check namespace and service name |

### Verification Steps
```bash
# 1. Check service exists
kubectl get svc -n sovereign-core sovereign-core-metering

# 2. Test connectivity from pod
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://sovereign-core-metering.sovereign-core.svc.cluster.local:8080/health

# 3. Verify DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  nslookup sovereign-core-metering.sovereign-core.svc.cluster.local
```

## References

- **Catalogathon Guide**: `catalogathon-guide-main/metering.md`
- **API Reference**: `catalogathon-guide-main/reference/reference-metering.md`
- **API Keys**: `catalogathon-guide-main/reference/reference-apikeys.md`
- **Metering Proxy**: `https://github.ibm.com/SovereignCore/catalogathon-meteringproxy`

## Summary

The metering endpoint is **not something we invented** - it's the **standard platform service** provided by IBM Sovereign Core. All catalog services use this same endpoint to report usage data. The endpoint is:

1. **Platform-provided**: Deployed by Sovereign Core infrastructure
2. **Standardized**: Same endpoint for all services
3. **Documented**: In official Catalogathon guide
4. **Required**: For Tier 3 compliance (metering integration)

Our job is to **integrate with it**, not create it.