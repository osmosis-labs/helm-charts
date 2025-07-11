#!/bin/bash
set -e

echo "🧪 Testing Helm Charts..."

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Please install Helm first."
    exit 1
fi

# Find all charts in the charts directory
CHARTS_DIR="charts"
if [ ! -d "$CHARTS_DIR" ]; then
    echo "❌ Charts directory not found: $CHARTS_DIR"
    exit 1
fi

FAILED_CHARTS=()
SUCCESS_COUNT=0

# Loop through all chart directories
for chart_dir in "$CHARTS_DIR"/*; do
    if [ -d "$chart_dir" ]; then
        chart_name=$(basename "$chart_dir")
        echo "🧪 Testing chart: $chart_name"
        
        # Template test (doesn't require cluster connection)
        echo "  📋 Running template test..."
        if helm template "$chart_name" "$chart_dir" > /dev/null; then
            echo "  ✅ Template test passed"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            echo "  ❌ Template test failed"
            FAILED_CHARTS+=("$chart_name")
        fi
        echo ""
    fi
done

# Print summary
echo "📊 Testing Summary:"
echo "   ✅ Passed: $SUCCESS_COUNT"
echo "   ❌ Failed: ${#FAILED_CHARTS[@]}"

if [ ${#FAILED_CHARTS[@]} -eq 0 ]; then
    echo "🎉 All charts passed testing!"
    exit 0
else
    echo "💥 The following charts failed testing:"
    for chart in "${FAILED_CHARTS[@]}"; do
        echo "   - $chart"
    done
    exit 1
fi 
