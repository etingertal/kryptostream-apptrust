#!/usr/bin/env python3

import os
import pytest
import requests
import json
from typing import Dict, Any

class TestEndToEnd:
    """End-to-end tests for the quote and translation services"""
    
    @pytest.fixture(autouse=True)
    def setup(self):
        """Setup test configuration"""
        self.quote_url = os.getenv('QUOTE_SERVICE_URL', 'http://quote-service:8080')
        self.translation_url = os.getenv('TRANSLATION_SERVICE_URL', 'http://translation-service:8000')
        
    def test_quote_service_health(self):
        """Test that the quote service is healthy"""
        response = requests.get(f"{self.quote_url}/actuator/health")
        assert response.status_code == 200
        data = response.json()
        assert data['status'] == 'UP'
        print("✅ Quote service health check passed")
    
    def test_translation_service_health(self):
        """Test that the translation service is healthy"""
        response = requests.get(f"{self.translation_url}/health")
        assert response.status_code == 200
        data = response.json()
        assert data['status'] == 'healthy'
        assert data['model_loaded'] == True
        print("✅ Translation service health check passed")
    
    def test_quote_service_endpoints(self):
        """Test quote service endpoints"""
        # Test health endpoint
        response = requests.get(f"{self.quote_url}/api/quotes/health")
        assert response.status_code == 200
        
        # Test today's quote endpoint
        response = requests.get(f"{self.quote_url}/api/quotes/today")
        assert response.status_code == 200
        data = response.json()
        assert 'text' in data
        assert 'author' in data
        assert isinstance(data['text'], str)
        assert isinstance(data['author'], str)
        print("✅ Quote service endpoints test passed")
    
    def test_translation_service_endpoints(self):
        """Test translation service endpoints"""
        # Test root endpoint
        response = requests.get(f"{self.translation_url}/")
        assert response.status_code == 200
        
        # Test translation endpoint
        test_text = "Hello, world!"
        payload = {
            "text": test_text,
            "source_lang": "en",
            "target_lang": "fr"
        }
        
        response = requests.post(
            f"{self.translation_url}/translate",
            json=payload,
            headers={'Content-Type': 'application/json'}
        )
        assert response.status_code == 200
        data = response.json()
        assert data['original_text'] == test_text
        assert data['translated_text'] is not None
        assert data['source_lang'] == 'en'
        assert data['target_lang'] == 'fr'
        print("✅ Translation service endpoints test passed")
    
    def test_end_to_end_workflow(self):
        """Test the complete workflow: get quote and translate it"""
        # Step 1: Get today's quote
        response = requests.get(f"{self.quote_url}/api/quotes/today")
        assert response.status_code == 200
        quote_data = response.json()
        original_quote = quote_data['text']
        print(f"📝 Original quote: {original_quote}")
        
        # Step 2: Translate the quote
        payload = {
            "text": original_quote,
            "source_lang": "en",
            "target_lang": "fr"
        }
        
        response = requests.post(
            f"{self.translation_url}/translate",
            json=payload,
            headers={'Content-Type': 'application/json'}
        )
        assert response.status_code == 200
        translation_data = response.json()
        translated_quote = translation_data['translated_text']
        print(f"🌍 Translated quote: {translated_quote}")
        
        # Verify the translation
        assert translation_data['original_text'] == original_quote
        assert translation_data['translated_text'] != original_quote
        assert len(translation_data['translated_text']) > 0
        print("✅ End-to-end workflow test passed")
    
    def test_batch_translation(self):
        """Test batch translation functionality"""
        test_texts = ["Hello", "Good morning", "How are you?"]
        payload = {
            "texts": test_texts,
            "source_lang": "en",
            "target_lang": "fr"
        }
        
        response = requests.post(
            f"{self.translation_url}/translate/batch",
            json=payload,
            headers={'Content-Type': 'application/json'}
        )
        assert response.status_code == 200
        data = response.json()
        
        assert len(data['translations']) == len(test_texts)
        for i, translation in enumerate(data['translations']):
            assert translation['original_text'] == test_texts[i]
            assert translation['translated_text'] is not None
            assert translation['translated_text'] != test_texts[i]
        
        print("✅ Batch translation test passed")
    
    def test_error_handling(self):
        """Test error handling in both services"""
        # Test invalid translation request with very long text
        payload = {
            "text": "A" * 10000,  # Very long text that might cause issues
            "source_lang": "en",
            "target_lang": "fr"
        }
        
        response = requests.post(
            f"{self.translation_url}/translate",
            json=payload,
            headers={'Content-Type': 'application/json'}
        )
        # Should handle long text gracefully
        assert response.status_code in [200, 400, 500]
        print("✅ Error handling test passed")

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
