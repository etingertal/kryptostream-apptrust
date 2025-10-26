package com.example.btcwallet.model;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDate;

@Schema(description = "BTCWallet entity representing a Bitcoin wallet")
public class BTCWallet {
    @Schema(description = "The wallet address", example = "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa")
    private String address;

    @Schema(description = "The balance of the wallet", example = "0.001 BTC")
    private String balance;

    @Schema(description = "The date associated with this wallet", example = "2025-08-10")
    private LocalDate date;

    public BTCWallet() {
    }

    public BTCWallet(String address, String balance, LocalDate date) {
        this.address = address;
        this.balance = balance;
        this.date = date;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getBalance() {
        return balance;
    }

    public void setBalance(String balance) {
        this.balance = balance;
    }

    public LocalDate getDate() {
        return date;
    }

    public void setDate(LocalDate date) {
        this.date = date;
    }

    @Override
    public String toString() {
        return "BTCWallet{" +
                "address='" + address + '\'' +
                ", balance='" + balance + '\'' +
                ", date=" + date +
                '}';
    }
}