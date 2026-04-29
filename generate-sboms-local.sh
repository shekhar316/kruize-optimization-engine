#!/bin/bash

echo "📦 Generating SBOMs for Kruize container images (with local pull)..."
echo ""

# Check if syft is installed
if ! command -v syft &> /dev/null; then
    echo "❌ Error: syft is not installed"
    echo ""
    echo "Please install syft:"
    echo "  macOS:   brew install syft"
    echo "  Linux:   curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin"
    echo "  Windows: Download from https://github.com/anchore/syft/releases"
    exit 1
fi

# Use podman for TLS verification control
if command -v podman &> /dev/null; then
    CONTAINER_CMD="podman"
else
    echo "❌ Error: podman is not installed"
    echo "Please install podman to pull images with --tls-verify=false"
    echo "  macOS:   brew install podman"
    echo "  Linux:   sudo apt-get install podman  # or yum install podman"
    exit 1
fi

echo "Using container runtime: $CONTAINER_CMD"
echo ""

SBOM_DIR="$(dirname "$0")/sbom"
mkdir -p "$SBOM_DIR"

# Array of images to scan (Catalogathon registry images)
declare -a IMAGES=(
    "dev-registry-quay-catalogathon-registry.apps.hthon-dev.svl.ibm.com/sccat-7aa7afd3-ca2a-43e2-81a8-8f5e22900927/kruize-operator:catalogathon"
    "dev-registry-quay-catalogathon-registry.apps.hthon-dev.svl.ibm.com/sccat-7aa7afd3-ca2a-43e2-81a8-8f5e22900927/postgres:catalogathon"
    "dev-registry-quay-catalogathon-registry.apps.hthon-dev.svl.ibm.com/sccat-7aa7afd3-ca2a-43e2-81a8-8f5e22900927/autotune:catalogathon"
    "dev-registry-quay-catalogathon-registry.apps.hthon-dev.svl.ibm.com/sccat-7aa7afd3-ca2a-43e2-81a8-8f5e22900927/kruize-ui:catalogathon"
    "dev-registry-quay-catalogathon-registry.apps.hthon-dev.svl.ibm.com/sccat-7aa7afd3-ca2a-43e2-81a8-8f5e22900927/optimizer:catalogathon"
)

# Generate SBOM for each image
for IMAGE in "${IMAGES[@]}"; do
    # Extract image name and tag for filename
    IMAGE_NAME=$(echo "$IMAGE" | sed 's|.*/||' | sed 's/:/-/')
    SBOM_FILE="$SBOM_DIR/${IMAGE_NAME}-sbom.json"
    
    echo "🔍 Processing: $IMAGE"
    echo "   Pulling image..."
    
    # Pull the image first (with TLS verification disabled for internal registry)
    $CONTAINER_CMD pull --tls-verify=false "$IMAGE" 2>&1 | grep -v "Trying to pull"
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Image pulled successfully"
        echo "   Generating SBOM..."
        
        # Generate SBOM from local image
        syft "$IMAGE" -o cyclonedx-json > "$SBOM_FILE" 2>/dev/null
        
        if [ $? -eq 0 ] && [ -s "$SBOM_FILE" ]; then
            FILE_SIZE=$(du -h "$SBOM_FILE" | cut -f1)
            echo "   ✅ SBOM generated successfully ($FILE_SIZE)"
        else
            echo "   ❌ Failed to generate SBOM"
        fi
    else
        echo "   ❌ Failed to pull image (check VPN connection)"
    fi
    echo ""
done

echo "✅ SBOM generation complete!"
echo ""
echo "Generated files:"
ls -lh "$SBOM_DIR"/*.json | grep -v " 0 "

