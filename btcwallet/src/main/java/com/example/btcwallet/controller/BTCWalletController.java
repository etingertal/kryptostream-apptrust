package com.example.btcwallet.controller;

import com.example.btcwallet.model.BTCWallet;
import com.example.btcwallet.service.BTCWalletService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/btcwallet")
@CrossOrigin(origins = "*")
@Tag(name = "BTC Wallet", description = "BTC Wallet management APIs ")
public class BTCWalletController {

    private final BTCWalletService btcWalletService;

    @Autowired
    public BTCWalletController(BTCWalletService btcWalletService) {
        this.btcWalletService = btcWalletService;
    }

    @GetMapping("/first")
    @Operation(
        summary = "Get first wallet",
        description = "Retrieves the first BTC wallet in the list"
    )
    @ApiResponses(value = {
        @ApiResponse(
            responseCode = "200",
            description = "Successfully retrieved the first wallet",
            content = @Content(
                mediaType = "application/json",
                schema = @Schema(implementation = BTCWallet.class)
            )
        ),
        @ApiResponse(
            responseCode = "500",
            description = "Internal server error",
            content = @Content
        )
    })
    public ResponseEntity<BTCWallet> getFirstWallet() {
        BTCWallet wallet = btcWalletService.getAllWallets().stream().findFirst().orElse(null);
        return ResponseEntity.ok(wallet);
    }

    @GetMapping("/address/{address}")
    @Operation(
        summary = "Get wallet by address",
        description = "Retrieves a BTC wallet by its address"
    )
    @ApiResponses(value = {
        @ApiResponse(
            responseCode = "200",
            description = "Successfully retrieved the wallet",
            content = @Content(
                mediaType = "application/json",
                schema = @Schema(implementation = BTCWallet.class)
            )
        ),
        @ApiResponse(
            responseCode = "404",
            description = "Wallet not found",
            content = @Content
        ),
        @ApiResponse(
            responseCode = "500",
            description = "Internal server error",
            content = @Content
        )
    })
    public ResponseEntity<BTCWallet> getWalletByAddress(
            @Parameter(description = "The address of the wallet", example = "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa")
            @PathVariable String address) {
        BTCWallet wallet = btcWalletService.getWalletByAddress(address);
        return ResponseEntity.ok(wallet);
    }

    @GetMapping("/all")
    @Operation(
        summary = "Get all wallets",
        description = "Retrieves all BTC wallets in the system"
    )
    @ApiResponses(value = {
        @ApiResponse(
            responseCode = "200",
            description = "Successfully retrieved all wallets",
            content = @Content(
                mediaType = "application/json",
                schema = @Schema(implementation = BTCWallet.class)
            )
        ),
        @ApiResponse(
            responseCode = "500",
            description = "Internal server error",
            content = @Content
        )
    })
    public ResponseEntity<List<BTCWallet>> getAllWallets() {
        List<BTCWallet> wallets = btcWalletService.getAllWallets();
        return ResponseEntity.ok(wallets);
    }


    @GetMapping("/health")
    @Operation(
        summary = "Health check",
        description = "Checks if the BTC Wallet service is running and healthy"
    )
    @ApiResponses(value = {
        @ApiResponse(
            responseCode = "200",
            description = "Service is healthy",
            content = @Content(
                mediaType = "text/plain",
                examples = @ExampleObject(
                    name = "Health Response",
                    value = "BTC Wallet Service is running!"
                )
            )
        )
    })
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("BTC Wallet Service is running!");
    }
}
