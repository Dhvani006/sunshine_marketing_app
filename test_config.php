<?php
// Simple test to check Cashfree configuration
header('Content-Type: application/json');

try {
    $config = include 'config_simple.php';
    
    // Load local config if available
    if (file_exists(__DIR__ . '/config_local.php')) {
        $localConfig = include 'config_local.php';
        $cf = $localConfig['cashfree'];
        $configFile = 'config_local.php';
    } else {
        $cf = $config['cashfree'];
        $configFile = 'config_simple.php';
    }
    
    $result = [
        'config_file' => $configFile,
        'client_id' => $cf['client_id'],
        'client_secret_length' => strlen($cf['client_secret']),
        'environment' => $cf['environment'],
        'is_configured' => !empty($cf['client_id']) && strpos($cf['client_id'], 'CF_CLIENT_ID_TEST') !== 0,
        'needs_setup' => empty($cf['client_id']) || strpos($cf['client_id'], 'CF_CLIENT_ID_TEST') === 0
    ];
    
    echo json_encode($result, JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>