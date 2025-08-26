<?php
// Set proper headers first
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Error handling
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);

try {
    // Include Cashfree configuration
    if (!file_exists('cashfree_config.php')) {
        throw new Exception('Cashfree configuration file not found');
    }
    require_once 'cashfree_config.php';

    // Get JSON input
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);

    if (!$data) {
        throw new Exception('Invalid JSON input');
    }

    // Extract required fields
    $orderId = $data['order_id'] ?? '';
    $paymentSessionId = $data['payment_session_id'] ?? '';
    $amount = $data['amount'] ?? 0;
    $returnUrl = $data['return_url'] ?? '';

    if (empty($orderId) || empty($paymentSessionId)) {
        throw new Exception('Missing required fields');
    }

    // Build the correct checkout URL using the updated base URL
    $baseUrl = getCashfreeBaseUrl();
    $encodedSessionId = urlencode($paymentSessionId);
    $checkoutUrl = $baseUrl . '/checkout/' . $encodedSessionId;

    // Log for debugging
    error_log("Cashfree Web Checkout - Base URL: " . $baseUrl);
    error_log("Cashfree Web Checkout - Session ID: " . $paymentSessionId);
    error_log("Cashfree Web Checkout - Final URL: " . $checkoutUrl);

    echo json_encode([
        'status' => 'SUCCESS',
        'message' => 'Web checkout URL generated successfully',
        'checkout_url' => $checkoutUrl,
        'order_id' => $orderId,
        'payment_session_id' => $paymentSessionId,
        'note' => 'Direct checkout URL from Cashfree order creation'
    ]);

} catch (Exception $e) {
    // Always return JSON, never HTML
    http_response_code(500);
    echo json_encode([
        'status' => 'ERROR',
        'message' => 'Web checkout failed: ' . $e->getMessage()
    ]);
}
?>
