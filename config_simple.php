<?php
/**
 * Simple Secure Cashfree Configuration
 * Loads API keys from environment variables without function conflicts
 */

// Load .env file if it exists and not already loaded
if (!isset($_ENV['CASHFREE_APP_ID']) && file_exists(__DIR__ . '/.env')) {
    $lines = file(__DIR__ . '/.env', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos(trim($line), '#') === 0) {
            continue;
        }
        
        if (strpos($line, '=') !== false) {
            list($name, $value) = explode('=', $line, 2);
            $_ENV[trim($name)] = trim($value);
            putenv(trim($name) . '=' . trim($value));
        }
    }
}

// Cashfree Configuration
return [
    'cashfree' => [
        'client_id' => getenv('CASHFREE_APP_ID') ?: $_ENV['CASHFREE_APP_ID'] ?? 'CF_CLIENT_ID_TEST',
        'client_secret' => getenv('CASHFREE_SECRET_KEY') ?: $_ENV['CASHFREE_SECRET_KEY'] ?? 'CF_CLIENT_SECRET_TEST',
        'environment' => getenv('CASHFREE_ENVIRONMENT') ?: $_ENV['CASHFREE_ENVIRONMENT'] ?? 'sandbox'
    ],
    'server' => [
        'base_url' => getenv('SERVER_URL') ?: $_ENV['SERVER_URL'] ?? 'http://192.168.27.5/sunshine_marketing_app_backend',
        'ngrok_url' => getenv('NGROK_URL') ?: $_ENV['NGROK_URL'] ?? 'https://b81a71185ea7.ngrok-free.app/sunshine_marketing_app_backend'
    ]
];
