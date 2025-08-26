<?php
// Set proper headers first
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
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

    // Get order ID from request
    $orderId = $_GET['order_id'] ?? $_POST['order_id'] ?? '';

    if (empty($orderId)) {
        throw new Exception('Order ID is required');
    }

    // Verify order with Cashfree
    $verificationResult = verifyCashfreeOrder($orderId);

    // Always return 200, but include the status in the response
    echo json_encode($verificationResult);

} catch (Exception $e) {
    // Always return JSON, never HTML
    http_response_code(500);
    echo json_encode([
        'status' => 'ERROR',
        'message' => 'Verification failed: ' . $e->getMessage()
    ]);
}

function verifyCashfreeOrder($orderId) {
    try {
        $baseUrl = getCashfreeBaseUrl();
        $clientId = getCashfreeClientId();
        $clientSecret = getCashfreeClientSecret();
        
        // Use correct API version
        $apiVersion = '2023-08-01';
        
        $url = $baseUrl . '/orders/' . urlencode($orderId);
        
        $headers = [
            'Content-Type: application/json',
            'x-api-version: ' . $apiVersion,
            'x-client-id: ' . $clientId,
            'x-client-secret: ' . $clientSecret
        ];
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_HTTPGET, true);
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
        
        // Extract payment information
        $paymentStatus = $responseData['order_status'] ?? 'UNKNOWN';
        $isPaid = ($paymentStatus === 'PAID') || ($responseData['order_status'] === 'ACTIVE' && isset($responseData['payment_details']));
        $transactionId = $responseData['cf_payment_id'] ?? null;
        $paymentMethod = $responseData['payment_method'] ?? null;
        
        return [
            'status' => 'SUCCESS',
            'message' => 'Order verified successfully',
            'order_id' => $orderId,
            'payment_status' => $paymentStatus,
            'order_status' => $responseData['order_status'] ?? 'UNKNOWN',
            'order_amount' => $responseData['order_amount'] ?? 0,
            'customer_details' => $responseData['customer_details'] ?? null,
            'transaction_id' => $transactionId,
            'payment_method' => $paymentMethod,
            'is_paid' => $isPaid,
            'raw_response' => $responseData
        ];
        
    } catch (Exception $e) {
        return ['status' => 'ERROR', 'message' => 'Verification error: ' . $e->getMessage()];
    }
}
?>
