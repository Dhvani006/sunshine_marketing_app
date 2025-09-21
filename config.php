<?php
/**
 * Secure Cashfree Configuration
 * Loads API keys from environment variables
 */

// Prevent multiple declarations
if (!function_exists('loadEnv')) {
    // Load environment variables from .env file
    function loadEnv($path) {
        if (!file_exists($path)) {
            return false;
        }
        
        $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        foreach ($lines as $line) {
            if (strpos(trim($line), '#') === 0) {
                continue;
            }
            
            list($name, $value) = explode('=', $line, 2);
            $_ENV[trim($name)] = trim($value);
            putenv(trim($name) . '=' . trim($value));
        }
        return true;
    }
}

// Load .env file only once
if (!isset($_ENV['CASHFREE_APP_ID'])) {
    loadEnv(__DIR__ . '/.env');
}

// Cashfree Configuration
return [
    'cashfree' => [
        'client_id' => getenv('CASHFREE_APP_ID') ?: $_ENV['CASHFREE_APP_ID'] ?? 'CF_CLIENT_ID_TEST',
        'client_secret' => getenv('CASHFREE_SECRET_KEY') ?: $_ENV['CASHFREE_SECRET_KEY'] ?? 'CF_CLIENT_SECRET_TEST',
        'environment' => getenv('CASHFREE_ENVIRONMENT') ?: $_ENV['CASHFREE_ENVIRONMENT'] ?? 'sandbox'
    ],
    'server' => [
        'base_url' => getenv('SERVER_URL') ?: $_ENV['SERVER_URL'] ?? 'http://192.168.56.69/sunshine_marketing_app_backend',
        'ngrok_url' => getenv('NGROK_URL') ?: $_ENV['NGROK_URL'] ?? 'https://ad797d09e91d.ngrok-free.app/sunshine_marketing_app_backend'
    ]
];
