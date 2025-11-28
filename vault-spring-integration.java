// VaultTransitService.java - Spring Boot integration with Vault Transit
package com.visualpathit.account.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

@Service
public class VaultTransitService {
    
    @Value("${vault.url}")
    private String vaultUrl;
    
    @Value("${vault.token}")
    private String vaultToken;
    
    private final RestTemplate restTemplate = new RestTemplate();
    
    public String encrypt(String keyName, String plaintext) {
        try {
            String url = vaultUrl + "/v1/transit/encrypt/" + keyName;
            
            HttpHeaders headers = new HttpHeaders();
            headers.set("X-Vault-Token", vaultToken);
            headers.setContentType(MediaType.APPLICATION_JSON);
            
            Map<String, String> payload = new HashMap<>();
            payload.put("plaintext", Base64.getEncoder().encodeToString(plaintext.getBytes()));
            
            HttpEntity<Map<String, String>> request = new HttpEntity<>(payload, headers);
            ResponseEntity<Map> response = restTemplate.postForEntity(url, request, Map.class);
            
            Map<String, Object> data = (Map<String, Object>) response.getBody().get("data");
            return (String) data.get("ciphertext");
            
        } catch (Exception e) {
            throw new RuntimeException("Encryption failed: " + e.getMessage());
        }
    }
    
    public String decrypt(String keyName, String ciphertext) {
        try {
            String url = vaultUrl + "/v1/transit/decrypt/" + keyName;
            
            HttpHeaders headers = new HttpHeaders();
            headers.set("X-Vault-Token", vaultToken);
            headers.setContentType(MediaType.APPLICATION_JSON);
            
            Map<String, String> payload = new HashMap<>();
            payload.put("ciphertext", ciphertext);
            
            HttpEntity<Map<String, String>> request = new HttpEntity<>(payload, headers);
            ResponseEntity<Map> response = restTemplate.postForEntity(url, request, Map.class);
            
            Map<String, Object> data = (Map<String, Object>) response.getBody().get("data");
            String encodedPlaintext = (String) data.get("plaintext");
            return new String(Base64.getDecoder().decode(encodedPlaintext));
            
        } catch (Exception e) {
            throw new RuntimeException("Decryption failed: " + e.getMessage());
        }
    }
}

// Usage in your existing service classes:
/*
@Autowired
private VaultTransitService vaultService;

// Encrypt database password before storing
String encryptedPassword = vaultService.encrypt("vprofile-key", "mysql_password");

// Decrypt when connecting to database
String plainPassword = vaultService.decrypt("vprofile-key", encryptedPassword);
*/