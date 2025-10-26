package com.example.btcwallet.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class OpenAPIConfig {

    @Bean
    public OpenAPI btcWalletOpenAPI() {
        Server devServer = new Server();
        devServer.setUrl("http://localhost:8001");
        devServer.setDescription("Development server");

        Server prodServer = new Server();
        prodServer.setUrl("https://api.example.com");
        prodServer.setDescription("Production server");

        Contact contact = new Contact();
        contact.setEmail("demo@jfrog.com");
        contact.setName("JFrog Evidence Integration Demo");
        contact.setUrl("https://github.com/jfrog/evidence-integration");

        License mitLicense = new License()
                .name("Apache License, Version 2.0")
                .url("https://www.apache.org/licenses/LICENSE-2.0");

        Info info = new Info()
                .title("BTC Wallet Service API")
                .version("1.0.0")
                .contact(contact)
                .description("This API provides endpoints for managing Bitcoin wallet transactions, including creating, retrieving, and deleting wallet addresses.")
                .termsOfService("https://www.apache.org/licenses/LICENSE-2.0")
                .license(mitLicense);

        return new OpenAPI()
                .info(info)
                .servers(List.of(devServer, prodServer));
    }
}
