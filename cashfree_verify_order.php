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

// Cashfree API configuration from config file
$cfEnvironment = getCashfreeEnvironment();
$cfClientId = getCashfreeClientId();
$cfClientSecret = getCashfreeClientSecret();

// API endpoints
$baseUrl = getCashfreeBaseUrl();

// Get order ID from GET or POST request
$orderId = $_GET['order_id'] ?? $_POST['order_id'] ?? '';

if (empty($orderId)) {
    echo json_encode([
        'status' => 'ERROR',
        'message' => 'Order ID is required'
    ]);
    exit();
}

// Initialize cURL session
$ch = curl_init();

// Set cURL options for GET request
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/orders/' . $orderId);
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
        // Extract payment information
        $paymentStatus = 'unknown';
        $orderStatus = $responseData['order_status'] ?? 'unknown';
        $orderAmount = $responseData['order_amount'] ?? 0;
        $transactionId = null;
        $paymentMethod = null;
        
        // Try to get payment details from the order
        if (isset($responseData['payment_methods']) && !empty($responseData['payment_methods'])) {
            $paymentMethod = $responseData['payment_methods'][0] ?? 'UPI';
        }
        
        // Check if order is paid by looking at order status and other indicators
        $isPaid = false;
        if ($orderStatus === 'ACTIVE' && isset($responseData['cf_payment_id'])) {
            $isPaid = true;
            $paymentStatus = 'SUCCESS';
            $transactionId = $responseData['cf_payment_id'];
        } elseif ($orderStatus === 'ACTIVE') {
            $paymentStatus = 'PENDING';
        }
        
        // If we have payment session details, try to get more info
        if (isset($responseData['payment_session_id'])) {
            // The order exists but payment might still be pending
            if ($paymentStatus === 'unknown') {
                $paymentStatus = 'PENDING';
            }
        }
        
        echo json_encode([
            'status' => 'SUCCESS',
            'message' => 'Order verified successfully',
            'order_id' => $orderId,
            'payment_status' => $paymentStatus,
            'order_status' => $orderStatus,
            'order_amount' => $orderAmount,
            'customer_details' => $responseData['customer_details'] ?? [],
            'transaction_id' => $transactionId,
            'payment_method' => $paymentMethod,
            'is_paid' => $isPaid,
            'raw_response' => $responseData // Include full response for debugging
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
