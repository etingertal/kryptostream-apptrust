package com.example.btcwallet.service;

import com.example.btcwallet.model.BTCWallet;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class BTCWalletServiceTest {

    private BTCWalletService btcWalletService;

    @BeforeEach
    void setUp() {
        btcWalletService = new BTCWalletService();
    }

    @Test
    void getWalletByAddress_ShouldReturnWallet() {
        // When
        BTCWallet wallet = btcWalletService.getWalletByAddress("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa");

        // Then
        assertNotNull(wallet);
        assertEquals("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa", wallet.getAddress());
    }

    @Test
    void getAllWallets_ShouldReturnAllWallets() {
        // When
        List<BTCWallet> wallets = btcWalletService.getAllWallets();

        // Then
        assertNotNull(wallets);
        assertFalse(wallets.isEmpty());
        assertTrue(wallets.size() > 0);
    }
}
