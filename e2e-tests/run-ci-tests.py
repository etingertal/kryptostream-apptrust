#!/usr/bin/env python3
"""
CI Test Runner for E2E Tests
This script runs the E2E tests in a CI environment and generates JSON reports.
"""

import os
import sys
import time
import requests
import json
import subprocess
from datetime import datetime

def wait_for_service(url, service_name, max_retries=30, delay=2):
    """Wait for a service to be ready"""
    print(f"⏳ Waiting for {service_name} at {url}...")
    
    for i in range(max_retries):
        try:
            response = requests.get(url, timeout=5)
            if response.status_code == 200:
                print(f"✅ {service_name} is ready!")
                return True
        except requests.exceptions.RequestException:
            pass
        
        if i < max_retries - 1:
            print(f"   Attempt {i+1}/{max_retries} - {service_name} not ready yet, retrying in {delay}s...")
            time.sleep(delay)
    
    print(f"❌ {service_name} failed to start after {max_retries} attempts")
    return False

def run_tests():
    """Run the E2E tests"""
    print("🚀 Starting E2E Tests in CI Environment")
    print("=" * 50)
    
    # Get service URLs from environment
    quote_url = os.getenv('QUOTE_SERVICE_URL', 'http://quote-service:8080')
    translation_url = os.getenv('TRANSLATION_SERVICE_URL', 'http://translation-service:8000')
    
    print(f"📋 Test Configuration:")
    print(f"   Quote Service URL: {quote_url}")
    print(f"   Translation Service URL: {translation_url}")
    print()
    
    # Wait for services to be ready
    quote_ready = wait_for_service(f"{quote_url}/actuator/health", "Quote Service")
    translation_ready = wait_for_service(f"{translation_url}/health", "Translation Service")
    
    if not quote_ready or not translation_ready:
        print("❌ Services failed to start")
        return False
    
    print("🎉 All services are ready!")
    print("🧪 Running E2E tests...")
    print("=" * 50)
    
    # Run pytest with JSON reporting
    try:
        result = subprocess.run([
            'python', '-m', 'pytest', 
            'test_e2e.py', 
            '-v', 
            '--json-report', 
            '--json-report-file=test-results.json',
            '--tb=short'
        ], capture_output=True, text=True)
        
        # Print test output
        print(result.stdout)
        if result.stderr:
            print("STDERR:", result.stderr)
        
        # Check if tests passed
        if result.returncode == 0:
            print("✅ E2E tests completed successfully!")
            return True
        else:
            print("❌ E2E tests failed!")
            return False
            
    except Exception as e:
        print(f"❌ Error running tests: {e}")
        return False

def generate_test_summary():
    """Generate a test summary from the JSON report"""
    try:
        with open('test-results.json', 'r') as f:
            report = json.load(f)
        
        summary = report.get('summary', {})
        total = summary.get('total', 0)
        passed = summary.get('passed', 0)
        failed = summary.get('failed', 0)
        
        print(f"\n📊 Test Summary:")
        print(f"   Total: {total}")
        print(f"   Passed: {passed}")
        print(f"   Failed: {failed}")
        print(f"   Success Rate: {(passed/total*100):.1f}%" if total > 0 else "   Success Rate: N/A")
        
        return passed == total
        
    except FileNotFoundError:
        print("❌ Test results file not found")
        return False
    except Exception as e:
        print(f"❌ Error reading test results: {e}")
        return False

if __name__ == "__main__":
    success = run_tests()
    
    if success:
        summary_success = generate_test_summary()
        if not summary_success:
            print("⚠️  Some tests failed")
            sys.exit(1)
    else:
        print("❌ Test execution failed")
        sys.exit(1)
