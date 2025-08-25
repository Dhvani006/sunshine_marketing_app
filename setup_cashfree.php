<?php
/**
 * Cashfree Configuration Setup Script
 * Run this script to configure your Cashfree API credentials
 * 
 * IMPORTANT: This script should be run ONCE to set up your configuration
 * After setup, DELETE this file for security
 */

echo "=== Cashfree Configuration Setup ===\n\n";

// Check if configuration already exists
if (file_exists('cashfree_config.php')) {
    echo "✓ Configuration file exists\n";
    
    // Test if configuration is valid
    require_once 'cashfree_config.php';
    
    if (function_exists('validateCashfreeConfig')) {
        if (validateCashfreeConfig()) {
            echo "✓ Configuration is valid and ready to use\n";
            echo "✓ Client ID: " . substr(getCashfreeClientId(), 0, 8) . "...\n";
            echo "✓ Environment: " . getCashfreeEnvironment() . "\n";
            echo "\nYour Cashfree integration is properly configured!\n";
            exit(0);
        } else {
            echo "⚠ Configuration exists but credentials are not set\n";
        }
    }
}

echo "Setting up Cashfree configuration...\n\n";

// Get configuration from user
echo "Enter your Cashfree configuration:\n";
echo "Environment (TEST/PRODUCTION) [TEST]: ";
$environment = trim(fgets(STDIN)) ?: 'TEST';

echo "Client ID: ";
$clientId = trim(fgets(STDIN));

echo "Client Secret: ";
$clientSecret = trim(fgets(STDIN));

if (empty($clientId) || empty($clientSecret)) {
    echo "❌ Error: Client ID and Client Secret are required\n";
    exit(1);
}

// Create local configuration file
$localConfig = "<?php
// local_config.php - DO NOT COMMIT THIS FILE!
define('CF_ENVIRONMENT', '$environment');
define('CF_CLIENT_ID', '$clientId');
define('CF_CLIENT_SECRET', '$clientSecret');
?>";

if (file_put_contents('local_config.php', $localConfig)) {
    echo "✓ Created local_config.php\n";
} else {
    echo "❌ Failed to create local_config.php\n";
    exit(1);
}

// Update main config to include local config
$mainConfig = file_get_contents('cashfree_config.php');
if (strpos($mainConfig, 'local_config.php') === false) {
    $mainConfig = str_replace(
        '<?php',
        "<?php\n// Include local config if it exists\nif (file_exists('local_config.php')) {\n    require_once 'local_config.php';\n}",
        $mainConfig
    );
    
    if (file_put_contents('cashfree_config.php', $mainConfig)) {
        echo "✓ Updated cashfree_config.php to include local config\n";
    } else {
        echo "❌ Failed to update cashfree_config.php\n";
        exit(1);
    }
}

// Test configuration
require_once 'cashfree_config.php';
if (validateCashfreeConfig()) {
    echo "✓ Configuration test successful!\n";
    echo "✓ Environment: " . getCashfreeEnvironment() . "\n";
    echo "✓ Client ID: " . substr(getCashfreeClientId(), 0, 8) . "...\n";
    
    echo "\n🎉 Setup completed successfully!\n";
    echo "Your Cashfree integration is now configured.\n";
    echo "\n⚠️  IMPORTANT: Delete this setup script for security!\n";
    echo "   rm setup_cashfree.php\n";
    
} else {
    echo "❌ Configuration test failed\n";
    echo "Please check your credentials and try again\n";
    exit(1);
}
?>
