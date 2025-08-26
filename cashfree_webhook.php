<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Include Cashfree configuration
require_once 'cashfree_config.php';

// Database connection
$host = 'localhost';
$dbname = 'sunshine_marketing';
$username = 'root';
$password = '';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    error_log("Webhook Database Error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['status' => 'ERROR', 'message' => 'Database connection failed']);
    exit;
}

// Get webhook data
$webhookData = file_get_contents('php://input');
error_log("Webhook raw data received: " . $webhookData);

$data = json_decode($webhookData, true);

if (!$data) {
    $jsonError = json_last_error_msg();
    error_log("Webhook Error: Invalid JSON data received. JSON Error: " . $jsonError);
    error_log("Webhook Error: Raw data: " . $webhookData);
    http_response_code(400);
    echo json_encode([
        'status' => 'ERROR', 
        'message' => 'Invalid webhook data',
        'json_error' => $jsonError,
        'raw_data' => $webhookData
    ]);
    exit;
}

// Log webhook data for debugging
error_log("Webhook received: " . json_encode($data));
error_log("Webhook data keys: " . implode(', ', array_keys($data)));

// Extract order information
$cashfreeOrderId = $data['order_id'] ?? '';
$paymentStatus = $data['order_status'] ?? '';
$transactionId = $data['cf_payment_id'] ?? '';
$paymentMethod = $data['payment_method'] ?? 'UPI';

error_log("Extracted values - Order ID: $cashfreeOrderId, Status: $paymentStatus, Transaction ID: $transactionId");

if (empty($cashfreeOrderId)) {
    error_log("Webhook Error: Missing order_id");
    http_response_code(400);
    echo json_encode(['status' => 'ERROR', 'message' => 'Missing order_id']);
    exit;
}

try {
    // Find local order using cashfree_order_id
    $stmt = $pdo->prepare("SELECT Order_id, User_id, Total_amount FROM orders WHERE cashfree_order_id = ?");
    $stmt->execute([$cashfreeOrderId]);
    $order = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$order) {
        error_log("Webhook Error: Local order not found for cashfree_order_id: " . $cashfreeOrderId);
        http_response_code(404);
        echo json_encode(['status' => 'ERROR', 'message' => 'Local order not found']);
        exit;
    }
    
    $localOrderId = $order['Order_id'];
    $userId = $order['User_id'];
    $amount = $order['Total_amount'];
    
    // Map Cashfree status to local status
    $localPaymentStatus = 'Pending';
    if ($paymentStatus === 'PAID') {
        $localPaymentStatus = 'Success';
    } elseif ($paymentStatus === 'EXPIRED' || $paymentStatus === 'FAILED') {
        $localPaymentStatus = 'Failed';
    }
    
    // Check if payment record already exists
    $stmt = $pdo->prepare("SELECT Payment_id FROM payments WHERE Order_id = ?");
    $stmt->execute([$localOrderId]);
    $existingPayment = $stmt->fetch();
    
    if ($existingPayment) {
        // Update existing payment record
        $stmt = $pdo->prepare("UPDATE payments SET Payment_status = ?, Transaction_id = ?, Payment_method = ? WHERE Order_id = ?");
        $stmt->execute([$localPaymentStatus, $transactionId, $paymentMethod, $localOrderId]);
        error_log("Webhook: Updated existing payment for order: " . $localOrderId);
    } else {
        // Create new payment record
        $stmt = $pdo->prepare("INSERT INTO payments (User_id, Order_id, Payment_method, Amount, Payment_status, Transaction_id, Payment_date) VALUES (?, ?, ?, ?, ?, ?, NOW())");
        $stmt->execute([$userId, $localOrderId, $paymentMethod, $amount, $localPaymentStatus, $transactionId]);
        
        // Get the payment ID
        $paymentId = $pdo->lastInsertId();
        
        // Update order with payment ID and status
        $orderStatus = ($localPaymentStatus === 'Success') ? 'Completed' : 'Pending';
        $stmt = $pdo->prepare("UPDATE orders SET Payment_id = ?, Order_status = ? WHERE Order_id = ?");
        $stmt->execute([$paymentId, $orderStatus, $localOrderId]);
        
        error_log("Webhook: Created new payment record with ID: " . $paymentId . " for order: " . $localOrderId);
    }
    
    echo json_encode([
        'status' => 'SUCCESS',
        'message' => 'Webhook processed successfully',
        'order_id' => $localOrderId,
        'payment_status' => $localPaymentStatus
    ]);
    
} catch (Exception $e) {
    error_log("Webhook Error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['status' => 'ERROR', 'message' => 'Webhook processing failed']);
}
?>
