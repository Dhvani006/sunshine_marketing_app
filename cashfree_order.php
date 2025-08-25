<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Include configuration file
require_once 'cashfree_config.php';

// Validate configuration
if (!validateCashfreeConfig()) {
    echo json_encode([
        'status' => 'ERROR',
        'message' => 'Cashfree API configuration not set. Please configure your API credentials.'
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

// Cashfree API configuration from config file
$cfEnvironment = getCashfreeEnvironment();
$cfClientId = getCashfreeClientId();
$cfClientSecret = getCashfreeClientSecret();

// API endpoints
$baseUrl = getCashfreeBaseUrl();

// Get order details from JSON request
$orderAmount = $data['order_amount'] ?? '1';
$orderCurrency = $data['order_currency'] ?? 'INR';
$customerId = $data['customer_id'] ?? 'customer_' . time();
$customerName = $data['customer_name'] ?? '';
$customerEmail = $data['customer_email'] ?? '';
$customerPhone = $data['customer_phone'] ?? '';
$orderNote = $data['order_note'] ?? '';

// Create order payload
$orderData = [
    'order_amount' => $orderAmount,
    'order_currency' => $orderCurrency,
    'customer_details' => [
        'customer_id' => $customerId,
        'customer_name' => $customerName,
        'customer_email' => $customerEmail,
        'customer_phone' => $customerPhone
    ],
    'order_meta' => [
        'return_url' => 'https://test.cashfree.com/pgappsdemos/return.php?order_id=' . $customerId
    ],
    'order_note' => $orderNote
];

// Initialize cURL session
$ch = curl_init();

// Set cURL options
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/orders');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($orderData));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'x-client-id: ' . $cfClientId,
    'x-client-secret: ' . $cfClientSecret,
    'x-api-version: 2023-08-01'
]);

// Execute cURL request
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);

curl_close($ch);

// Handle response
if ($error) {
    echo json_encode([
        'status' => 'ERROR',
        'message' => 'cURL Error: ' . $error
    ]);
} else {
    $responseData = json_decode($response, true);
    
    if ($httpCode === 200) {
        echo json_encode([
            'status' => 'SUCCESS',
            'order_id' => $responseData['order_id'] ?? null,
            'payment_session_id' => $responseData['payment_session_id'] ?? null,
            'data' => $responseData
        ]);
    } else {
        echo json_encode([
            'status' => 'ERROR',
            'message' => 'API Error: ' . $httpCode,
            'response' => $responseData
        ]);
    }
}
?>
