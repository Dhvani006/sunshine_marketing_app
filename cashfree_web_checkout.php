<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        'status' => 'ERROR',
        'message' => 'Only POST method is allowed'
    ]);
    exit();
}

// Get JSON input
$input = file_get_contents('php://input');
$data = json_decode($input, true);

if (!$data) {
    echo json_encode([
        'status' => 'ERROR',
        'message' => 'Invalid JSON data received'
    ]);
    exit();
}

// Validate required fields
$orderId = $data['order_id'] ?? '';
$paymentSessionId = $data['payment_session_id'] ?? '';
$amount = $data['amount'] ?? '';
$returnUrl = $data['return_url'] ?? '';

if (empty($orderId) || empty($paymentSessionId) || empty($amount)) {
    echo json_encode([
        'status' => 'ERROR',
        'message' => 'Missing required fields: order_id, payment_session_id, amount'
    ]);
    exit();
}

// Cashfree API configuration
$cfEnvironment = 'TEST'; // TEST or PRODUCTION
$cfClientId = '127853d2ce159b71f6945456ab358721'; // Replace with your actual Client ID
$cfClientSecret = 'cfsk_ma_test_235fd634d4746bdf682810f852162ac8_094ed789'; // Replace with your actual Client Secret

// API endpoints
$baseUrl = ($cfEnvironment === 'PRODUCTION') 
    ? 'https://api.cashfree.com/pg' 
    : 'https://sandbox.cashfree.com/pg';

// For web checkout, we don't need to call additional API endpoints
// Cashfree provides the checkout URL directly when creating the order
// We just need to construct the proper checkout URL

// The correct Cashfree web checkout URL format
$checkoutUrl = 'https://test.cashfree.com/pg/checkout/' . $paymentSessionId;

// Log the checkout process
error_log("Cashfree Web Checkout - Order ID: $orderId, Session ID: $paymentSessionId, Amount: $amount");

echo json_encode([
    'status' => 'SUCCESS',
    'message' => 'Web checkout URL generated successfully',
    'checkout_url' => $checkoutUrl,
    'order_id' => $orderId,
    'payment_session_id' => $paymentSessionId,
    'note' => 'Direct checkout URL from Cashfree order creation'
]);
?>
