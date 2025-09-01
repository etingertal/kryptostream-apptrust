#!/bin/bash

# Convert Cypress JSON report to Markdown
# Usage: ./convert-cypress-report.sh [input-file] [output-file]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONVERT_SCRIPT="$SCRIPT_DIR/convert-cypress-to-markdown.js"

# Default values
DEFAULT_INPUT="cypress/results/combined-report.json"
DEFAULT_OUTPUT="cypress-report.md"

# Parse arguments
INPUT_FILE="${1:-$DEFAULT_INPUT}"
OUTPUT_FILE="${2:-$DEFAULT_OUTPUT}"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "❌ Error: Input file '$INPUT_FILE' not found"
    echo ""
    echo "Usage: $0 [input-file] [output-file]"
    echo ""
    echo "Arguments:"
    echo "  input-file   Path to Cypress JSON report file (default: $DEFAULT_INPUT)"
    echo "  output-file  Path to output Markdown file (default: $DEFAULT_OUTPUT)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Convert cypress-results.json to cypress-report.md"
    echo "  $0 my-results.json                   # Convert my-results.json to my-results.md"
    echo "  $0 my-results.json my-report.md     # Convert my-results.json to my-report.md"
    exit 1
fi

# Check if Node.js script exists
if [ ! -f "$CONVERT_SCRIPT" ]; then
    echo "❌ Error: Conversion script not found: $CONVERT_SCRIPT"
    exit 1
fi

echo "🔄 Converting Cypress report..."
echo "   Input:  $INPUT_FILE"
echo "   Output: $OUTPUT_FILE"

# Run the conversion
if node "$CONVERT_SCRIPT" "$INPUT_FILE" "$OUTPUT_FILE"; then
    echo "✅ Conversion completed successfully!"
    echo "📄 Markdown report saved to: $OUTPUT_FILE"
    
    # Show file size
    if [ -f "$OUTPUT_FILE" ]; then
        SIZE=$(wc -c < "$OUTPUT_FILE")
        echo "📊 File size: ${SIZE} bytes"
    fi
else
    echo "❌ Conversion failed!"
    exit 1
fi
