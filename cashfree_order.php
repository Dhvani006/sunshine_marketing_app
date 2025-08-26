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

    // Database connection
    $host = 'localhost';
    $dbname = 'sunshine_marketing';
    $username = 'root';
    $password = '';

    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Get JSON input
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);

    if (!$data) {
        throw new Exception('Invalid JSON input');
    }

    // Extract order details
    $orderAmount = $data['order_amount'] ?? null;
    $orderCurrency = $data['order_currency'] ?? 'INR';
    $customerDetails = $data['customer_details'] ?? [];
    $orderNote = $data['order_note'] ?? 'Order from Sunshine Marketing App';

    // Debug: Log what we received
    error_log("Received data: " . json_encode($data));
    error_log("Order amount: " . var_export($orderAmount, true));
    error_log("Customer details: " . json_encode($customerDetails));

    // Validate required fields with better checks
    if ($orderAmount === null || $orderAmount === '' || $orderAmount <= 0) {
        throw new Exception('Invalid or missing order amount: ' . var_export($orderAmount, true));
    }
    
    if (empty($customerDetails) || !is_array($customerDetails)) {
        throw new Exception('Customer details are missing or invalid');
    }
    
    // Check if customer details have required fields
    $requiredCustomerFields = ['customer_name', 'customer_email', 'customer_phone'];
    foreach ($requiredCustomerFields as $field) {
        if (empty($customerDetails[$field])) {
            throw new Exception("Missing required customer field: $field");
        }
    }

    // Prepare order data for Cashfree
    $orderData = [
        'order_amount' => $orderAmount,
        'order_currency' => $orderCurrency,
        'customer_details' => [
            'customer_id' => $customerDetails['customer_id'] ?? 'customer_' . time(),
            'customer_name' => $customerDetails['customer_name'] ?? '',
            'customer_email' => $customerDetails['customer_email'] ?? '',
            'customer_phone' => $customerDetails['customer_phone'] ?? ''
        ],
        'order_note' => $orderNote,
        'order_meta' => [
            'return_url' => 'http://10.127.160.66/sunshine_marketing_app_backend/cashfree_return_url.php?order_id=' . ($customerDetails['customer_id'] ?? 'customer_' . time())
        ]
    ];

    // Create Cashfree order
    $cashfreeOrder = createCashfreeOrder($orderData);

    if ($cashfreeOrder['status'] === 'SUCCESS') {
        echo json_encode([
            'status' => 'SUCCESS',
            'message' => 'Order created successfully',
            'order_id' => $cashfreeOrder['order_id'],
            'payment_session_id' => $cashfreeOrder['payment_session_id'],
            'data' => $cashfreeOrder['data'] ?? null
        ]);
    } else {
        http_response_code(400);
        echo json_encode([
            'status' => 'ERROR',
            'message' => $cashfreeOrder['message'] ?? 'Failed to create order'
        ]);
    }

} catch (Exception $e) {
    // Always return JSON, never HTML
    http_response_code(500);
    echo json_encode([
        'status' => 'ERROR',
        'message' => 'Order creation failed: ' . $e->getMessage()
    ]);
}

function createCashfreeOrder($orderData) {
    try {
        $baseUrl = getCashfreeBaseUrl();
        $clientId = getCashfreeClientId();
        $clientSecret = getCashfreeClientSecret();
        
        // Use correct API version
        $apiVersion = '2023-08-01';
        
        $url = $baseUrl . '/orders';
        
        $headers = [
            'Content-Type: application/json',
            'x-api-version: ' . $apiVersion,
            'x-client-id: ' . $clientId,
            'x-client-secret: ' . $clientSecret
        ];
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($orderData));
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_TIMEOUT, 30);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);
        curl_close($ch);
        
        if ($error) {
            return ['status' => 'ERROR', 'message' => 'cURL Error: ' . $error];
        }
        
        if ($httpCode !== 200) {
            return ['status' => 'ERROR', 'message' => 'HTTP Error: ' . $httpCode . ' - ' . $response];
        }
        
        $responseData = json_decode($response, true);
        
        if (!$responseData) {
            return ['status' => 'ERROR', 'message' => 'Invalid response from Cashfree'];
        }
        
        if (isset($responseData['cf_order_id'])) {
            return [
                'status' => 'SUCCESS',
                'order_id' => $responseData['cf_order_id'],
                'payment_session_id' => $responseData['payment_session_id'],
                'data' => $responseData
            ];
        } else {
            return ['status' => 'ERROR', 'message' => 'Order creation failed: ' . ($responseData['message'] ?? 'Unknown error')];
        }
        
    } catch (Exception $e) {
        return ['status' => 'ERROR', 'message' => 'Order creation error: ' . $e->getMessage()];
    }
}
?>
