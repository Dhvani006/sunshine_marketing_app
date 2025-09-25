<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'config_simple.php';
require_once 'helpers.php';

// Load local config if available
if (file_exists(__DIR__ . '/config_local.php')) {
    $localConfig = include 'config_local.php';
}

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        echo json_encode(['success' => false, 'message' => 'Only POST method allowed']);
        http_response_code(405);
        exit;
    }

    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input) {
        echo json_encode(['success' => false, 'message' => 'Invalid JSON input']);
        http_response_code(400);
        exit;
    }

    $required = ['order_amount', 'customer_id', 'customer_email', 'customer_phone'];
    $missing = validateRequiredFields($input, $required);
    if (!empty($missing)) {
        echo json_encode(['success' => false, 'message' => 'Missing fields: ' . implode(', ', $missing)]);
        http_response_code(400);
        exit;
    }

    // Get local order ID if provided (for Flutter app)
    $localOrderId = $input['local_order_id'] ?? null;

    $config = include 'config_simple.php';
    
    // Use local config if available, otherwise use main config
    if (isset($localConfig)) {
        $cf = $localConfig['cashfree'];
        $serverConfig = $localConfig['server'];
    } else {
        $cf = $config['cashfree'];
        $serverConfig = $config['server'];
    }
    
    // Check if credentials are properly configured
    if (empty($cf['client_id']) || strpos($cf['client_id'], 'CF_CLIENT_ID_TEST') === 0) {
        echo json_encode([
            'success' => false, 
            'message' => 'Cashfree client_id not configured. Please add your actual Cashfree credentials to config_local.php',
            'debug_info' => [
                'current_client_id' => $cf['client_id'],
                'config_file' => isset($localConfig) ? 'config_local.php' : 'config_simple.php'
            ]
        ]);
        http_response_code(500);
        exit;
    }
    if (empty($cf['client_secret']) || strpos($cf['client_secret'], 'CF_CLIENT_SECRET_TEST') === 0) {
        echo json_encode([
            'success' => false, 
            'message' => 'Cashfree client_secret not configured. Please add your actual Cashfree credentials to config_local.php',
            'debug_info' => [
                'current_client_secret' => substr($cf['client_secret'], 0, 10) . '...',
                'config_file' => isset($localConfig) ? 'config_local.php' : 'config_simple.php'
            ]
        ]);
        http_response_code(500);
        exit;
    }
    $isSandbox = ($cf['environment'] ?? 'sandbox') === 'sandbox';
    $baseUrl = $isSandbox ? 'https://sandbox.cashfree.com' : 'https://api.cashfree.com';

    // Build order payload
    $orderId = 'CF_' . time() . '_' . substr(sha1(uniqid('', true)), 0, 8);
    $orderAmount = (float)$input['order_amount'];
    if (!is_numeric($orderAmount) || $orderAmount <= 0) {
        echo json_encode(['success' => false, 'message' => 'Invalid order_amount']);
        http_response_code(400);
        exit;
    }

    $payload = [
        'order_id' => $orderId,
        'order_amount' => (float)number_format($orderAmount, 2, '.', ''),
        'order_currency' => 'INR',
        'customer_details' => [
            'customer_id' => (string)$input['customer_id'],
            'customer_name' => $input['customer_name'] ?? 'Customer',
            'customer_email' => $input['customer_email'],
            'customer_phone' => $input['customer_phone']
        ],
        'order_note' => $input['order_note'] ?? 'Sunshine Marketing Order',
        'order_meta' => [
            'return_url' => $serverConfig['ngrok_url'] . '/cashfree_return_url.php?order_id=' . $orderId
        ]
    ];

    // Debug logging
    error_log("Cashfree Debug - Base URL: " . $baseUrl);
    error_log("Cashfree Debug - Full URL: " . $baseUrl . '/pg/orders');
    error_log("Cashfree Debug - Client ID: " . $cf['client_id']);
    error_log("Cashfree Debug - Client Secret: " . substr($cf['client_secret'], 0, 10) . "...");
    error_log("Cashfree Debug - Payload: " . json_encode($payload));

    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL => $baseUrl . '/pg/orders',
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'x-client-id: ' . $cf['client_id'],
            'x-client-secret: ' . $cf['client_secret'],
            'x-api-version: 2023-08-01',
            'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        ],
        CURLOPT_POSTFIELDS => json_encode($payload),
        CURLOPT_TIMEOUT => 30,
        CURLOPT_FOLLOWLOCATION => false,
        CURLOPT_MAXREDIRS => 0,
        CURLOPT_PROXY => '', // Disable proxy
        CURLOPT_PROXYUSERPWD => '',
        CURLOPT_HTTPPROXYTUNNEL => false,
    ]);
    // For local dev on some environments, SSL root certs may be missing; disable verification in sandbox only
    if ($isSandbox) {
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
    }
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlErr = curl_error($ch);
    curl_close($ch);

    // Debug logging
    error_log("Cashfree Debug - HTTP Code: " . $httpCode);
    error_log("Cashfree Debug - Response: " . $response);
    if ($curlErr) {
        error_log("Cashfree Debug - cURL Error: " . $curlErr);
    }

    if ($curlErr) {
        echo json_encode(['success' => false, 'message' => 'Curl error: ' . $curlErr]);
        http_response_code(500);
        exit;
    }

    $data = json_decode($response, true);
    if ($httpCode >= 200 && $httpCode < 300) {
        // Debug: Log the full response
        error_log("Cashfree Debug - Full Response Data: " . json_encode($data));
        
        // Check if we have the required fields
        if (!isset($data['payment_session_id'])) {
            error_log("Cashfree Debug - Missing payment_session_id in response");
            error_log("Cashfree Debug - Available fields: " . implode(', ', array_keys($data ?: [])));
            
            echo json_encode([
                'success' => false, 
                'message' => 'Cashfree did not return payment_session_id',
                'data' => $data,
                'debug_info' => [
                    'http_code' => $httpCode,
                    'response_fields' => array_keys($data ?: []),
                    'full_response' => $response
                ]
            ]);
            http_response_code(500);
            exit;
        }

        // Update local order with Cashfree order ID if provided
        if ($localOrderId) {
            try {
                $pdo = new PDO('mysql:host=localhost;dbname=sunshine_marketing', 'root', '');
                $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
                
                $stmt = $pdo->prepare("UPDATE orders SET cashfree_order_id = ? WHERE Order_id = ?");
                $stmt->execute([$data['order_id'] ?? $orderId, $localOrderId]);
                
                error_log("Updated local order $localOrderId with Cashfree order ID: " . ($data['order_id'] ?? $orderId));
            } catch (Exception $e) {
                error_log("Failed to update local order with Cashfree order ID: " . $e->getMessage());
                // Don't fail the entire request if this update fails
            }
        }

        echo json_encode([
            'success' => true,
            'message' => 'Cashfree session created successfully',
            'data' => [
                'order_id' => $data['order_id'] ?? $orderId,
                'payment_session_id' => $data['payment_session_id'],
                'order_status' => $data['order_status'] ?? 'ACTIVE',
                'checkout_url' => $isSandbox 
                    ? "https://sandbox.cashfree.com/pg/checkout/{$data['payment_session_id']}"
                    : "https://www.cashfree.com/pg/checkout/{$data['payment_session_id']}",
                'local_order_id' => $localOrderId
            ]
        ]);
        exit;
    }

    echo json_encode([
        'success' => false,
        'message' => $data['message'] ?? 'Failed to create Cashfree order',
        'data' => [
            'http_code' => $httpCode,
            'cashfree_response' => $data ?: $response,
        ],
    ]);
    http_response_code($httpCode ?: 500);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
    http_response_code(500);
}
?>