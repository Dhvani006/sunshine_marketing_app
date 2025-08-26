<?php
/**
 * Test Script for Cashfree Configuration
 * Run this to verify your setup is working
 */

echo "=== Cashfree Configuration Test ===\n\n";

// Include the configuration
require_once 'cashfree_config.php';

echo "✓ Configuration file loaded\n";

// Test configuration values
echo "Environment: " . getCashfreeEnvironment() . "\n";
echo "Client ID: " . substr(getCashfreeClientId(), 0, 8) . "...\n";
echo "Client Secret: " . substr(getCashfreeClientSecret(), 0, 8) . "...\n";
echo "Base URL: " . getCashfreeBaseUrl() . "\n";

// Test configuration validation
if (validateCashfreeConfig()) {
    echo "✓ Configuration validation passed\n";
} else {
    echo "❌ Configuration validation failed\n";
}

// Test if we can make a basic API call
echo "\n=== Testing API Connection ===\n";

try {
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, getCashfreeBaseUrl() . '/orders');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'x-client-id: ' . getCashfreeClientId(),
        'x-client-secret: ' . getCashfreeClientSecret(),
        'x-api-version: ' . getCashfreeApiVersion()
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    if ($error) {
        echo "❌ cURL Error: $error\n";
    } else {
        echo "✓ API connection test completed\n";
        echo "HTTP Status Code: $httpCode\n";
        
        if ($httpCode === 401) {
            echo "⚠ API authentication failed - check your credentials\n";
        } elseif ($httpCode === 200 || $httpCode === 400) {
            echo "✓ API connection successful\n";
        } else {
            echo "⚠ Unexpected response code: $httpCode\n";
        }
    }
    
} catch (Exception $e) {
    echo "❌ Error testing API: " . $e->getMessage() . "\n";
}

echo "\n=== Test Complete ===\n";
echo "If you see any errors, check your configuration.\n";
echo "If everything shows ✓, your setup is working!\n";
?>
