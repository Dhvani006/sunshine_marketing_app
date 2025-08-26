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

    // Extract payment details
    $userId = $data['user_id'] ?? null;
    $orderId = $data['order_id'] ?? null;
    $paymentMethod = $data['payment_method'] ?? 'UPI';
    $amount = $data['amount'] ?? 0;
    $paymentStatus = $data['payment_status'] ?? 'Success';
    $transactionId = $data['transaction_id'] ?? '';
    
    // Extract Cashfree-specific fields
    $cashfreeOrderId = $data['cashfree_order_id'] ?? null;
    $cashfreePaymentStatus = $data['cashfree_payment_status'] ?? null;
    $cashfreeResponse = $data['cashfree_response'] ?? null;

    // Validate required fields
    if (!$userId || !$orderId || !$amount) {
        throw new Exception('Missing required fields: user_id, order_id, amount');
    }

    // Start transaction
    $pdo->beginTransaction();

    try {
        // Check if payment record already exists
        $stmt = $pdo->prepare("SELECT Payment_id FROM payments WHERE Order_id = ?");
        $stmt->execute([$orderId]);
        $existingPayment = $stmt->fetch();

        if ($existingPayment) {
            // Update existing payment record
            $stmt = $pdo->prepare("
                UPDATE payments 
                SET Payment_status = ?, Transaction_id = ?, Payment_method = ?, Amount = ?, 
                    Cashfree_order_id = ?, Cashfree_payment_status = ?, Cashfree_response = ?
                WHERE Order_id = ?
            ");
            $stmt->execute([$paymentStatus, $transactionId, $paymentMethod, $amount, $cashfreeOrderId, $cashfreePaymentStatus, $cashfreeResponse, $orderId]);
            
            $paymentId = $existingPayment['Payment_id'];
            $message = 'Payment updated successfully';
        } else {
            // Create new payment record
            $stmt = $pdo->prepare("
                INSERT INTO payments (User_id, Order_id, Payment_method, Amount, Payment_status, Transaction_id, Cashfree_order_id, Cashfree_payment_status, Cashfree_response) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([$userId, $orderId, $paymentMethod, $amount, $paymentStatus, $transactionId, $cashfreeOrderId, $cashfreePaymentStatus, $cashfreeResponse]);
            
            $paymentId = $pdo->lastInsertId();
            $message = 'Payment saved successfully';
        }

        // Update order with payment ID and status
        $orderStatus = ($paymentStatus === 'Success') ? 'Completed' : 'Pending';
        $stmt = $pdo->prepare("UPDATE orders SET Payment_id = ?, Order_status = ? WHERE Order_id = ?");
        $stmt->execute([$paymentId, $orderStatus, $orderId]);

        // Commit transaction
        $pdo->commit();

        // Return success response
        echo json_encode([
            'status' => 'SUCCESS',
            'message' => $message,
            'payment_id' => $paymentId,
            'order_id' => $orderId,
            'payment_status' => $paymentStatus
        ]);

    } catch (Exception $e) {
        // Rollback transaction on error
        $pdo->rollBack();
        throw $e;
    }

} catch (Exception $e) {
    // Always return JSON, never HTML
    http_response_code(500);
    echo json_encode([
        'status' => 'ERROR',
        'message' => 'Payment save failed: ' . $e->getMessage()
    ]);
}
?>
