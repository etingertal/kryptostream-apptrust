#!/bin/bash

# Convert Surefire XML test reports to JSON format
# Usage: ./convert-test-reports.sh [input_dir] [output_file]

set -e

# Default values
INPUT_DIR="${1:-target/surefire-reports}"
OUTPUT_FILE="${2:-test-evidence.json}"
REPOSITORY="${REPOSITORY:-unknown}"
COMMIT_SHA="${COMMIT_SHA:-unknown}"
BRANCH="${BRANCH:-unknown}"
TRIGGERED_BY="${TRIGGERED_BY:-unknown}"

echo "🔍 Converting test reports from XML to JSON..."
echo "📁 Input directory: $INPUT_DIR"
echo "📄 Output file: $OUTPUT_FILE"

# Function to escape JSON strings
escape_json() {
    echo "$1" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/\n/\\n/g' | sed 's/\r/\\r/g' | sed 's/\t/\\t/g'
}

# Function to extract XML attribute value
extract_xml_attr() {
    local file="$1"
    local attr="$2"
    local default="$3"
    
    if command -v xmllint >/dev/null 2>&1; then
        xmllint --xpath "string(/testsuite/@$attr)" "$file" 2>/dev/null || echo "$default"
    else
        grep -o "$attr=\"[^\"]*\"" "$file" | cut -d'"' -f2 || echo "$default"
    fi
}

# Function to extract test case details
extract_test_cases() {
    local file="$1"
    local class_name="$2"
    
    if command -v xmllint >/dev/null 2>&1; then
        # Extract test cases using xmllint
        xmllint --xpath "//testcase" "$file" 2>/dev/null | while read -r line; do
            if [[ $line =~ name=\"([^\"]+)\" ]]; then
                test_name="${BASH_REMATCH[1]}"
                # Extract status (passed/failed/skipped)
                if [[ $line =~ \<failure ]]; then
                    status="failed"
                elif [[ $line =~ \<skipped ]]; then
                    status="skipped"
                else
                    status="passed"
                fi
                echo "{\"class\":\"$class_name\",\"name\":\"$test_name\",\"status\":\"$status\"}"
            fi
        done
    else
        # Fallback to grep for test cases
        grep -o 'name="[^"]*"' "$file" | cut -d'"' -f2 | while read -r test_name; do
            echo "{\"class\":\"$class_name\",\"name\":\"$test_name\",\"status\":\"passed\"}"
        done
    fi
}

# Initialize JSON structure
cat > "$OUTPUT_FILE" << EOF
{
  "test_summary": {
    "total_tests": 0,
    "passed_tests": 0,
    "failed_tests": 0,
    "skipped_tests": 0,
    "test_duration": 0,
    "success_rate": 0
  },
  "test_details": [],
  "test_cases": []
}
EOF

# Check if input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "⚠️ Input directory '$INPUT_DIR' not found"
    echo "📄 Created empty test evidence JSON: $OUTPUT_FILE"
    exit 0
fi

# Find all XML files
xml_files=$(find "$INPUT_DIR" -name "*.xml" -type f)

if [ -z "$xml_files" ]; then
    echo "⚠️ No XML test reports found in '$INPUT_DIR'"
    echo "📄 Created empty test evidence JSON: $OUTPUT_FILE"
    exit 0
fi

# Initialize counters
total_tests=0
passed_tests=0
failed_tests=0
skipped_tests=0
total_duration=0
test_details_json=""
test_cases_json=""

# Process each XML file
echo "📊 Processing XML test reports..."
for xml_file in $xml_files; do
    echo "  📄 Processing: $(basename "$xml_file")"
    
    # Extract test class name
    class_name=$(basename "$xml_file" .xml)
    
    # Extract test statistics
    tests=$(extract_xml_attr "$xml_file" "tests" "0")
    failures=$(extract_xml_attr "$xml_file" "failures" "0")
    skipped=$(extract_xml_attr "$xml_file" "skipped" "0")
    time=$(extract_xml_attr "$xml_file" "time" "0")
    
    # Calculate passed tests
    passed=$((tests - failures - skipped))
    
    # Update totals
    total_tests=$((total_tests + tests))
    passed_tests=$((passed_tests + passed))
    failed_tests=$((failed_tests + failures))
    skipped_tests=$((skipped_tests + skipped))
    
    # Add duration (handle floating point)
    if command -v bc >/dev/null 2>&1; then
        total_duration=$(echo "$total_duration + $time" | bc -l 2>/dev/null || echo "$total_duration")
    else
        # Simple integer addition fallback
        total_duration=$((total_duration + ${time%.*}))
    fi
    
    # Add test class details to JSON
    if [ -n "$test_details_json" ]; then
        test_details_json="$test_details_json,"
    fi
    test_details_json="$test_details_json
    {
      \"class_name\": \"$(escape_json "$class_name")\",
      \"tests\": $tests,
      \"passed\": $passed,
      \"failed\": $failures,
      \"skipped\": $skipped,
      \"duration\": $time
    }"
    
    # Extract individual test cases
    test_cases=$(extract_test_cases "$xml_file" "$class_name")
    if [ -n "$test_cases" ]; then
        while IFS= read -r test_case; do
            if [ -n "$test_cases_json" ]; then
                test_cases_json="$test_cases_json,"
            fi
            test_cases_json="$test_cases_json
      $test_case"
        done <<< "$test_cases"
    fi
done

# Calculate success rate
if [ $total_tests -gt 0 ]; then
    if command -v bc >/dev/null 2>&1; then
        success_rate=$(echo "scale=2; $passed_tests * 100 / $total_tests" | bc -l 2>/dev/null || echo "0")
    else
        success_rate=$((passed_tests * 100 / total_tests))
    fi
else
    success_rate=0
fi

# Create final JSON file
cat > "$OUTPUT_FILE" << EOF
{
  "test_summary": {
    "total_tests": $total_tests,
    "passed_tests": $passed_tests,
    "failed_tests": $failed_tests,
    "skipped_tests": $skipped_tests,
    "test_duration": $total_duration,
    "success_rate": $success_rate
  },
  "test_details": [$test_details_json
  ],
  "test_cases": [$test_cases_json
  ]
}
EOF

echo "✅ Test evidence JSON created successfully: $OUTPUT_FILE"
echo "📊 Test Summary:"
echo "   Total Tests: $total_tests"
echo "   Passed: $passed_tests"
echo "   Failed: $failed_tests"
echo "   Skipped: $skipped_tests"
echo "   Success Rate: ${success_rate}%"
echo "   Duration: ${total_duration}s"

# Display file size
file_size=$(wc -c < "$OUTPUT_FILE")
echo "📄 File size: ${file_size} bytes"
