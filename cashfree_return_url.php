<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Include configuration file
require_once 'cashfree_config.php';

// Validate configuration
if (!function_exists('getCashfreeEnvironment') || !function_exists('getCashfreeClientId') || !function_exists('getCashfreeClientSecret')) {
    echo json_encode([
        'status' => 'ERROR',
        'message' => 'Cashfree API configuration not set. Please configure your API credentials.'
    ]);
    exit();
}

// Get order ID from query parameter
$orderId = $_GET['order_id'] ?? '';

if (empty($orderId)) {
    echo json_encode([
        'status' => 'ERROR',
        'message' => 'Order ID is required'
    ]);
    exit();
}

// Log the return URL access
error_log("Cashfree Return URL accessed - Order ID: $orderId");

try {
    // Step 1: Verify the payment status with Cashfree
    $cfEnvironment = getCashfreeEnvironment();
    $cfClientId = getCashfreeClientId();
    $cfClientSecret = getCashfreeClientSecret();
    
    $baseUrl = getCashfreeBaseUrl();
    
    // Call Cashfree API to verify order status
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $baseUrl . '/pg/orders/' . $orderId);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'x-client-id: ' . $cfClientId,
        'x-client-secret: ' . $cfClientSecret,
        'x-api-version: 2023-08-01'
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    if ($error) {
        throw new Exception('cURL Error: ' . $error);
    }
    
    if ($httpCode !== 200) {
        throw new Exception('Cashfree API returned error: ' . $httpCode);
    }
    
    $orderData = json_decode($response, true);
    error_log("Cashfree order data: " . json_encode($orderData));
    
    // Step 2: Check if payment was successful
    $isPaid = false;
    $paymentStatus = 'unknown';
    $transactionId = null;
    $paymentMethod = 'UPI'; // Default
    
    if (isset($orderData['cf_payment_id'])) {
        $isPaid = true;
        $paymentStatus = 'SUCCESS';
        $transactionId = $orderData['cf_payment_id'];
        error_log("Payment successful - Transaction ID: $transactionId");
    } elseif (isset($orderData['order_status']) && $orderData['order_status'] === 'ACTIVE') {
        $paymentStatus = 'PENDING';
        error_log("Payment pending for order: $orderId");
    }
    
    // Step 3: Find the local order in your database
    $pdo = new PDO('mysql:host=localhost;dbname=sunshine_marketing', 'root', '');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $stmt = $pdo->prepare("SELECT Order_id, User_id, Total_amount FROM orders WHERE cashfree_order_id = ?");
    $stmt->execute([$orderId]);
    $localOrder = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$localOrder) {
        throw new Exception('Local order not found for Cashfree order: ' . $orderId);
    }
    
    $localOrderId = $localOrder['Order_id'];
    $userId = $localOrder['User_id'];
    $amount = $localOrder['Total_amount'];
    
    error_log("Found local order: ID=$localOrderId, User=$userId, Amount=$amount");
    
    // Step 4: If payment was successful, save payment details
    if ($isPaid) {
        // Check if payment already exists
        $stmt = $pdo->prepare("SELECT Payment_id FROM payments WHERE Order_id = ?");
        $stmt->execute([$localOrderId]);
        $existingPayment = $stmt->fetch();
        
        if (!$existingPayment) {
            // Insert payment record
            $stmt = $pdo->prepare("
                INSERT INTO payments (User_id, Order_id, Payment_method, Amount, Payment_status, Transaction_id)
                VALUES (?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([$userId, $localOrderId, $paymentMethod, $amount, 'Success', $transactionId]);
            
            $paymentId = $pdo->lastInsertId();
            error_log("Payment record created: ID=$paymentId");
            
            // Update order with payment ID
            $stmt = $pdo->prepare("UPDATE orders SET Payment_id = ? WHERE Order_id = ?");
            $stmt->execute([$paymentId, $localOrderId]);
            
            error_log("Order updated with payment ID: $paymentId");
        } else {
            error_log("Payment already exists for order: $localOrderId");
        }
    }
    
    // Step 5: Return success response with redirect information
    echo json_encode([
        'status' => 'SUCCESS',
        'message' => 'Payment processing completed',
        'order_id' => $orderId,
        'local_order_id' => $localOrderId,
        'payment_status' => $paymentStatus,
        'is_paid' => $isPaid,
        'transaction_id' => $transactionId,
        'redirect_url' => 'sunshine_marketing_app://payment_complete?order_id=' . $localOrderId . '&status=' . $paymentStatus
    ]);
    
} catch (Exception $e) {
    error_log("Error in return URL handler: " . $e->getMessage());
    
    echo json_encode([
        'status' => 'ERROR',
        'message' => 'Error processing payment: ' . $e->getMessage(),
        'order_id' => $orderId,
        'note' => 'Check server logs for details'
    ]);
}
?>
