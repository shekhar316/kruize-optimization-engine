#!/bin/bash

echo "📦 Generating SBOMs for Kruize container images..."
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

SBOM_DIR="$(dirname "$0")/sbom"
mkdir -p "$SBOM_DIR"

# Array of images to scan
declare -a IMAGES=(
    "quay.io/kruize/kruize-operator:0.0.5"
    "quay.io/kruize/autotune_operator:0.9"
    "quay.io/kruize/kruize-ui:0.1.0"
    "quay.io/kruize/kruize-optimizer:0.0.1"
    "quay.io/kruizehub/postgres:15.2"
)

# Generate SBOM for each image
for IMAGE in "${IMAGES[@]}"; do
    # Extract image name and tag for filename
    IMAGE_NAME=$(echo "$IMAGE" | sed 's|.*/||' | sed 's/:/-/')
    SBOM_FILE="$SBOM_DIR/${IMAGE_NAME}-sbom.json"
    
    echo "🔍 Scanning: $IMAGE"
    echo "   Output: $SBOM_FILE"
    
    syft "$IMAGE" -o cyclonedx-json > "$SBOM_FILE" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "   ✅ SBOM generated successfully"
    else
        echo "   ❌ Failed to generate SBOM"
    fi
    echo ""
done

echo "✅ SBOM generation complete!"
echo ""
echo "Generated files:"
ls -lh "$SBOM_DIR"/*.json

