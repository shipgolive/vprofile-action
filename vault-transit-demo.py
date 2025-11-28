#!/usr/bin/env python3
"""
Vault Transit Engine Demo - Encryption as a Service
Usage with your vprofile application
"""

import requests
import base64
import json

class VaultTransit:
    def __init__(self, vault_url, token):
        self.vault_url = vault_url.rstrip('/')
        self.token = token
        self.headers = {'X-Vault-Token': token}
    
    def encrypt(self, key_name, plaintext):
        """Encrypt data using Vault Transit engine"""
        # Encode plaintext to base64
        encoded_data = base64.b64encode(plaintext.encode()).decode()
        
        url = f"{self.vault_url}/v1/transit/encrypt/{key_name}"
        payload = {"plaintext": encoded_data}
        
        response = requests.post(url, headers=self.headers, json=payload)
        if response.status_code == 200:
            return response.json()['data']['ciphertext']
        else:
            raise Exception(f"Encryption failed: {response.text}")
    
    def decrypt(self, key_name, ciphertext):
        """Decrypt data using Vault Transit engine"""
        url = f"{self.vault_url}/v1/transit/decrypt/{key_name}"
        payload = {"ciphertext": ciphertext}
        
        response = requests.post(url, headers=self.headers, json=payload)
        if response.status_code == 200:
            encoded_data = response.json()['data']['plaintext']
            return base64.b64decode(encoded_data).decode()
        else:
            raise Exception(f"Decryption failed: {response.text}")

# Example usage for vprofile application
if __name__ == "__main__":
    # Your existing Vault LoadBalancer URL
    VAULT_URL = "http://ad8d1589c834542a3a0778944c8f03c4-87591684.us-east-2.elb.amazonaws.com:8200"
    VAULT_TOKEN = "your-transit-token"  # Get this from setup script
    
    vault = VaultTransit(VAULT_URL, VAULT_TOKEN)
    
    # Encrypt sensitive data (passwords, API keys, etc.)
    sensitive_data = "mysql_password_123"
    encrypted = vault.encrypt("vprofile-key", sensitive_data)
    print(f"Encrypted: {encrypted}")
    
    # Decrypt when needed
    decrypted = vault.decrypt("vprofile-key", encrypted)
    print(f"Decrypted: {decrypted}")
    
    # Example: Encrypt database credentials
    db_config = {
        "username": "vprofile_user",
        "password": "secure_password_123",
        "host": "mysql.example.com"
    }
    
    # Encrypt password
    encrypted_password = vault.encrypt("vprofile-key", db_config["password"])
    print(f"Encrypted DB Password: {encrypted_password}")
    
    # Store encrypted password in config
    secure_config = {
        "username": db_config["username"],
        "encrypted_password": encrypted_password,
        "host": db_config["host"]
    }
    
    print(f"Secure Config: {json.dumps(secure_config, indent=2)}")