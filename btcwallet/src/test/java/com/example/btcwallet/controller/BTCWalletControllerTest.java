package com.example.btcwallet.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.ResponseEntity;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class BTCWalletControllerTest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    void getFirstWallet_ShouldReturnFirstWallet() {
        // When
        ResponseEntity<String> response = restTemplate.getForEntity(
                "http://localhost:" + port + "/api/btcwallet/first", String.class);

        // Then
        assertEquals(200, response.getStatusCodeValue());
        assertTrue(response.getBody().contains("address"));
        assertTrue(response.getBody().contains("balance"));
        assertTrue(response.getBody().contains("date"));
    }

    @Test
    void getWalletByAddress_ShouldReturnWallet() {
        // When
        ResponseEntity<String> response = restTemplate.getForEntity(
                "http://localhost:" + port + "/api/btcwallet/address/1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa", String.class);

        // Then
        assertEquals(200, response.getStatusCodeValue());
        assertTrue(response.getBody().contains("address"));
        assertTrue(response.getBody().contains("balance"));
        assertTrue(response.getBody().contains("date"));
    }

    @Test
    void getAllWallets_ShouldReturnAllWallets() {
        // When
        ResponseEntity<String> response = restTemplate.getForEntity(
                "http://localhost:" + port + "/api/btcwallet/all", String.class);

        // Then
        assertEquals(200, response.getStatusCodeValue());
        assertTrue(response.getBody().startsWith("["));
        assertTrue(response.getBody().endsWith("]"));
    }

    @Test
    void healthCheck_ShouldReturnStatusUp() {
        // When
        ResponseEntity<String> response = restTemplate.getForEntity(
                "http://localhost:" + port + "/api/btcwallet/health", String.class);

        // Then
        assertEquals(200, response.getStatusCodeValue());
        assertTrue(response.getBody().contains("running"));
    }
}
