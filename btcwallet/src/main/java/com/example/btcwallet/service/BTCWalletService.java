package com.example.btcwallet.service;

import com.example.btcwallet.model.BTCWallet;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;

@Service
public class BTCWalletService {

    private final List<BTCWallet> wallets = Arrays.asList(
            new BTCWallet("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa", "0.001 BTC", LocalDate.now()),
            new BTCWallet("3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy", "0.005 BTC", LocalDate.now()),
            new BTCWallet("bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kygt080", "0.010 BTC", LocalDate.now())
    );

    public BTCWallet getWalletByAddress(String address) {
        return wallets.stream()
                .filter(wallet -> wallet.getAddress().equals(address))
                .findFirst()
                .orElse(null);
    }

    public List<BTCWallet> getAllWallets() {
        return wallets;
    }
}
