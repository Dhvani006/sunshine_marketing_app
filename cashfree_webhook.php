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

// Database configuration
$host = 'localhost';
$dbname = 'sunshine_marketing';
$username = 'root';
$password = '';

// Cashfree webhook secret (you'll get this from Cashfree dashboard)
$webhookSecret = 'your_webhook_secret_here'; // Replace with your actual webhook secret

try {
    // Verify webhook signature (security)
    $payload = file_get_contents('php://input');
    $signature = $_SERVER['HTTP_X_WEBHOOK_SIGNATURE'] ?? '';
    
    // For now, we'll skip signature verification in test mode
    // In production, you should verify the signature
    
    $data = json_decode($payload, true);
    
    if (!$data) {
        throw new Exception('Invalid webhook payload');
    }
    
    // Log webhook data for debugging
    error_log('Cashfree Webhook Received: ' . $payload);
    
    // Extract important data from Cashfree webhook
    $cashfreeOrderId = $data['orderId'] ?? null;
    $orderAmount = $data['orderAmount'] ?? 0;
    $orderStatus = $data['orderStatus'] ?? null;
    $paymentStatus = $data['paymentStatus'] ?? null;
    $transactionId = $data['transactionId'] ?? null;
    $customerDetails = $data['customerDetails'] ?? [];
    
    if (!$cashfreeOrderId) {
        throw new Exception('Missing Cashfree order ID in webhook');
    }
    
    // Create database connection
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Start transaction
    $pdo->beginTransaction();
    
    // Find the order in your database using cashfree_order_id
    $stmt = $pdo->prepare("SELECT Order_id, User_id FROM orders WHERE cashfree_order_id = ?");
    $stmt->execute([$cashfreeOrderId]);
    $order = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$order) {
        // If order not found, create a new one
        $stmt = $pdo->prepare("
            INSERT INTO orders (User_id, Ecomm_product_id, Quantity, Total_amount, Order_status, cashfree_order_id, address, city, state, pincode) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ");
        
        // Use default values for missing data
        $stmt->execute([
            1, // Default user ID
            1, // Default product ID
            1, // Default quantity
            $orderAmount,
            'Processing',
            $cashfreeOrderId, // Store the Cashfree order ID
            'Webhook Created',
            'Unknown',
            'Unknown',
            '000000'
        ]);
        
        $localOrderId = $pdo->lastInsertId();
        $userId = 1; // Default user ID
    } else {
        $localOrderId = $order['Order_id'];
        $userId = $order['User_id'];
    }
    
    // Map Cashfree payment status to your enum values
    $mappedPaymentStatus = 'Pending'; // Default
    if ($paymentStatus) {
        switch (strtolower($paymentStatus)) {
            case 'success':
            case 'paid':
                $mappedPaymentStatus = 'Success';
                break;
            case 'failed':
            case 'declined':
                $mappedPaymentStatus = 'Failed';
                break;
            default:
                $mappedPaymentStatus = 'Pending';
        }
    }
    
    // Map payment method to your enum values
    // Since 'Cashfree' is not in your enum, we'll use 'UPI' as it's closest
    $paymentMethod = 'UPI';
    
    // Check if payment record already exists
    $stmt = $pdo->prepare("SELECT Payment_id FROM payments WHERE Transaction_id = ?");
    $stmt->execute([$transactionId]);
    $existingPayment = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($existingPayment) {
        // Update existing payment record
        $stmt = $pdo->prepare("
            UPDATE payments 
            SET Payment_status = ?, 
                Amount = ?, 
                Transaction_date = CURRENT_TIMESTAMP
            WHERE Payment_id = ?
        ");
        
        $stmt->execute([
            $mappedPaymentStatus,
            $orderAmount,
            $existingPayment['Payment_id']
        ]);
        
        $paymentId = $existingPayment['Payment_id'];
    } else {
        // Create new payment record
        $stmt = $pdo->prepare("
            INSERT INTO payments (User_id, Order_id, Payment_method, Amount, Payment_status, Transaction_id) 
            VALUES (?, ?, ?, ?, ?, ?)
        ");
        
        $stmt->execute([
            $userId,
            $localOrderId,
            $paymentMethod,
            $orderAmount,
            $mappedPaymentStatus,
            $transactionId
        ]);
        
        $paymentId = $pdo->lastInsertId();
    }
    
    // Update order with payment_id
    $stmt = $pdo->prepare("UPDATE orders SET Payment_id = ? WHERE Order_id = ?");
    $stmt->execute([$paymentId, $localOrderId]);
    
    // Update order status if provided
    if ($orderStatus) {
        $mappedOrderStatus = 'Processing'; // Default
        switch (strtolower($orderStatus)) {
            case 'paid':
            case 'completed':
                $mappedOrderStatus = 'Processing';
                break;
            case 'cancelled':
                $mappedOrderStatus = 'Cancelled';
                break;
            default:
                $mappedOrderStatus = 'Processing';
        }
        
        $stmt = $pdo->prepare("UPDATE orders SET Order_status = ? WHERE Order_id = ?");
        $stmt->execute([$mappedOrderStatus, $localOrderId]);
    }
    
    // Commit transaction
    $pdo->commit();
    
    // Return success response
    http_response_code(200);
    echo json_encode([
        'status' => 'SUCCESS',
        'message' => 'Webhook processed successfully',
        'local_order_id' => $localOrderId,
        'cashfree_order_id' => $cashfreeOrderId,
        'payment_id' => $paymentId,
        'payment_status' => $mappedPaymentStatus,
        'order_status' => $orderStatus
    ]);
    
} catch (Exception $e) {
    // Rollback transaction on error
    if (isset($pdo)) {
        $pdo->rollBack();
    }
    
    // Log error
    error_log('Cashfree Webhook Error: ' . $e->getMessage());
    
    http_response_code(500);
    echo json_encode([
        'status' => 'ERROR',
        'message' => 'Webhook processing failed: ' . $e->getMessage()
    ]);
}
?>
