<?php
// Payment gateway configuration (Cashfree)
// Loads environment variables from backend/.env if present, then falls back to env

// Lightweight .env loader (supports KEY=VALUE lines without quotes)
$envPath = __DIR__ . '/.env';
// 1) Prefer local override file if present (no env needed)
$localOverride = __DIR__ . '/payment.local.php';
if (file_exists($localOverride)) {
    $localConfig = include $localOverride;
    if (is_array($localConfig) && isset($localConfig['cashfree'])) {
        return $localConfig;
    }
}

if (file_exists($envPath) && is_readable($envPath)) {
    $envVars = @parse_ini_file($envPath, false, INI_SCANNER_RAW);
    if (is_array($envVars)) {
        foreach ($envVars as $key => $value) {
            if (getenv($key) === false) {
                putenv($key . '=' . $value);
            }
        }
    }
}

return [
    'cashfree' => [
        'client_id' => getenv('CASHFREE_CLIENT_ID') ?: 'CF_CLIENT_ID_TEST',
        'client_secret' => getenv('CASHFREE_CLIENT_SECRET') ?: 'CF_CLIENT_SECRET_TEST',
        // 'sandbox' or 'production'
        'environment' => getenv('CASHFREE_ENV') ?: 'sandbox'
    ],
];
?>
