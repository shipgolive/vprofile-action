package com.visualpathit.account.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

@Service
public class VaultEncryptionService {
    
    @Value("${vault.url:http://vault.vault.svc.cluster.local:8200}")
    private String vaultUrl;
    
    @Value("${vault.token}")
    private String vaultToken;
    
    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();
    
    /**
     * Encrypt sensitive data using Vault Transit engine
     */
    public String encrypt(String plaintext) {
        try {
            String url = vaultUrl + "/v1/transit/encrypt/vprofile-key";
            
            HttpHeaders headers = new HttpHeaders();
            headers.set("X-Vault-Token", vaultToken);
            headers.setContentType(MediaType.APPLICATION_JSON);
            
            Map<String, String> payload = new HashMap<>();
            payload.put("plaintext", Base64.getEncoder().encodeToString(plaintext.getBytes()));
            
            HttpEntity<Map<String, String>> request = new HttpEntity<>(payload, headers);
            ResponseEntity<String> response = restTemplate.postForEntity(url, request, String.class);
            
            Map<String, Object> responseBody = objectMapper.readValue(response.getBody(), Map.class);
            Map<String, Object> data = (Map<String, Object>) responseBody.get("data");
            
            return (String) data.get("ciphertext");
            
        } catch (Exception e) {
            throw new RuntimeException("Encryption failed: " + e.getMessage());
        }
    }
    
    /**
     * Decrypt sensitive data using Vault Transit engine
     */
    public String decrypt(String ciphertext) {
        try {
            String url = vaultUrl + "/v1/transit/decrypt/vprofile-key";
            
            HttpHeaders headers = new HttpHeaders();
            headers.set("X-Vault-Token", vaultToken);
            headers.setContentType(MediaType.APPLICATION_JSON);
            
            Map<String, String> payload = new HashMap<>();
            payload.put("ciphertext", ciphertext);
            
            HttpEntity<Map<String, String>> request = new HttpEntity<>(payload, headers);
            ResponseEntity<String> response = restTemplate.postForEntity(url, request, String.class);
            
            Map<String, Object> responseBody = objectMapper.readValue(response.getBody(), Map.class);
            Map<String, Object> data = (Map<String, Object>) responseBody.get("data");
            
            String encodedPlaintext = (String) data.get("plaintext");
            return new String(Base64.getDecoder().decode(encodedPlaintext));
            
        } catch (Exception e) {
            throw new RuntimeException("Decryption failed: " + e.getMessage());
        }
    }
    
    /**
     * Encrypt database password for secure storage
     */
    public String encryptDatabasePassword(String password) {
        return encrypt(password);
    }
    
    /**
     * Decrypt database password for connection
     */
    public String decryptDatabasePassword(String encryptedPassword) {
        return decrypt(encryptedPassword);
    }
}