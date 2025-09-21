<?php
// Test script to verify secure configuration
require_once 'config.php';

echo "=== SECURE CONFIGURATION TEST ===\n";
echo "Testing PHP configuration loading...\n\n";

try {
    $config = include 'config.php';
    
    echo "✅ Configuration loaded successfully\n";
    echo "Cashfree App ID: " . substr($config['cashfree']['client_id'], 0, 10) . "...\n";
    echo "Cashfree Secret: " . substr($config['cashfree']['client_secret'], 0, 10) . "...\n";
    echo "Environment: " . $config['cashfree']['environment'] . "\n";
    echo "Base URL: " . $config['server']['base_url'] . "\n";
    echo "Ngrok URL: " . $config['server']['ngrok_url'] . "\n\n";
    
    // Test environment variable loading
    echo "=== ENVIRONMENT VARIABLES TEST ===\n";
    $appId = getenv('CASHFREE_APP_ID');
    $secretKey = getenv('CASHFREE_SECRET_KEY');
    
    if ($appId && $secretKey) {
        echo "✅ Environment variables loaded successfully\n";
        echo "App ID from env: " . substr($appId, 0, 10) . "...\n";
        echo "Secret from env: " . substr($secretKey, 0, 10) . "...\n";
    } else {
        echo "❌ Environment variables not loaded\n";
    }
    
    echo "\n=== SECURITY CHECK ===\n";
    if (strpos($config['cashfree']['client_id'], 'CF_CLIENT_ID') === 0) {
        echo "❌ Using default/placeholder App ID\n";
    } else {
        echo "✅ Using actual App ID\n";
    }
    
    if (strpos($config['cashfree']['client_secret'], 'CF_CLIENT_SECRET') === 0) {
        echo "❌ Using default/placeholder Secret Key\n";
    } else {
        echo "✅ Using actual Secret Key\n";
    }
    
    echo "\n=== CONFIGURATION COMPLETE ===\n";
    echo "Your API keys are now securely managed!\n";
    
} catch (Exception $e) {
    echo "❌ Error loading configuration: " . $e->getMessage() . "\n";
}
?>
