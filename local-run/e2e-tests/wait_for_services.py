#!/usr/bin/env python3

import os
import time
import requests
from urllib.parse import urljoin

def wait_for_service(url, service_name, max_wait=300):
    """Wait for a service to be ready"""
    print(f"⏳ Waiting for {service_name} at {url}...")
    
    start_time = time.time()
    while time.time() - start_time < max_wait:
        try:
            response = requests.get(url, timeout=5)
            if response.status_code == 200:
                print(f"✅ {service_name} is ready!")
                return True
        except requests.exceptions.RequestException as e:
            print(f"⏳ {service_name} not ready yet: {e}")
        
        time.sleep(5)
    
    print(f"❌ {service_name} failed to start within {max_wait} seconds")
    return False

def main():
    quote_url = os.getenv('QUOTE_SERVICE_URL', 'http://quote-service:8080')
    translation_url = os.getenv('TRANSLATION_SERVICE_URL', 'http://translation-service:8000')
    
    # Wait for both services
    quote_ready = wait_for_service(
        urljoin(quote_url, '/actuator/health'),
        'Quote Service'
    )
    
    translation_ready = wait_for_service(
        urljoin(translation_url, '/health'),
        'Translation Service'
    )
    
    if not quote_ready or not translation_ready:
        print("❌ One or more services failed to start")
        exit(1)
    
    print("🎉 All services are ready!")

if __name__ == "__main__":
    main()
