#!/usr/bin/env python3
"""
Markdown Template Generator

This script takes a JSON file and a markdown template file as input,
then generates a markdown file with the same name as the JSON file
but with a .md extension.

Usage:
    python generate_markdown.py <json_file> <template_file>

Example:
    python generate_markdown.py sonar.json sonar-template.md
"""

import json
import sys
import os
import re
from pathlib import Path
from typing import Any, Dict, List


def load_json_data(json_file: str) -> Dict[str, Any]:
    """Load JSON data from file."""
    try:
        with open(json_file, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: JSON file '{json_file}' not found.")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in '{json_file}': {e}")
        sys.exit(1)


def load_template(template_file: str) -> str:
    """Load markdown template from file."""
    try:
        with open(template_file, 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        print(f"Error: Template file '{template_file}' not found.")
        sys.exit(1)


def get_nested_value(data: Dict[str, Any], path: str) -> Any:
    """Get nested value from dictionary using dot notation."""
    # Remove leading dot if present and split
    if path.startswith('.'):
        path = path[1:]
    
    keys = path.split('.')
    current = data
    
    for key in keys:
        if isinstance(current, dict) and key in current:
            current = current[key]
        else:
            return None
    
    return current


def process_range_template(template: str, data: Dict[str, Any]) -> str:
    """Process range templates like {{ range .projectStatus.conditions }}...{{ end }}."""
    # Pattern to match range blocks - handle multiline content
    range_pattern = r'\{\{\s*range\s+([^}]+)\s*\}\}(.*?)\{\{\s*end\s*\}\}'
    
    def replace_range(match):
        path = match.group(1).strip()
        inner_template = match.group(2).strip()
        
        # Get the array to iterate over
        array_data = get_nested_value(data, path)
        if not isinstance(array_data, list):
            return match.group(0)  # Return original if not a list
        
        result = []
        for item in array_data:
            # Replace variables in the inner template
            item_result = inner_template
            for var_match in re.finditer(r'\{\{\s*\.([^}]+)\s*\}\}', item_result):
                var_path = var_match.group(1).strip()
                var_value = get_nested_value(item, var_path)
                if var_value is not None:
                    item_result = item_result.replace(var_match.group(0), str(var_value))
            
            result.append(item_result)
        
        return '\n'.join(result)
    
    # Process range templates first
    result = re.sub(range_pattern, replace_range, template, flags=re.DOTALL)
    
    # Then process any remaining simple variables
    def replace_var(match):
        path = match.group(1).strip()
        value = get_nested_value(data, path)
        if value is not None:
            return str(value)
        return match.group(0)  # Return original if not found
    
    result = re.sub(r'\{\{\s*\.([^}]+)\s*\}\}', replace_var, result)
    
    return result


def process_template(template: str, data: Dict[str, Any]) -> str:
    """Process the template and replace variables with data."""
    # Process range templates (which also handles simple variables)
    result = process_range_template(template, data)
    
    return result


def generate_output_filename(json_file: str) -> str:
    """Generate output filename based on JSON filename."""
    json_path = Path(json_file)
    return json_path.with_suffix('.md').name


def save_markdown(content: str, output_file: str):
    """Save the generated markdown content to file."""
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Successfully generated: {output_file}")
    except Exception as e:
        print(f"Error saving file '{output_file}': {e}")
        sys.exit(1)


def main():
    """Main function."""
    if len(sys.argv) != 3:
        print("Usage: python generate_markdown.py <json_file> <template_file>")
        print("Example: python generate_markdown.py sonar.json sonar-template.md")
        sys.exit(1)
    
    json_file = sys.argv[1]
    template_file = sys.argv[2]
    
    # Validate input files exist
    if not os.path.exists(json_file):
        print(f"Error: JSON file '{json_file}' does not exist.")
        sys.exit(1)
    
    if not os.path.exists(template_file):
        print(f"Error: Template file '{template_file}' does not exist.")
        sys.exit(1)
    
    # Load data and template
    print(f"Loading JSON data from: {json_file}")
    data = load_json_data(json_file)
    
    print(f"Loading template from: {template_file}")
    template = load_template(template_file)
    
    # Process template
    print("Processing template...")
    result = process_template(template, data)
    
    # Generate output filename
    output_file = generate_output_filename(json_file)
    
    # Save result
    save_markdown(result, output_file)


if __name__ == "__main__":
    main()
