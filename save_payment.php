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

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Database configuration
$host = 'localhost';
$dbname = 'sunshine_marketing';
$username = 'root';
$password = '';

try {
    // Create database connection
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Get JSON input
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);
    
    // Log received data for debugging
    error_log('save_payment.php received data: ' . $input);
    
    if (!$data) {
        throw new Exception('Invalid JSON data received');
    }
    
    $userId = $data['user_id'] ?? null;
    $orderId = $data['order_id'] ?? null;
    $paymentMethod = $data['payment_method'] ?? 'UPI'; // Map to your enum values
    $amount = $data['amount'] ?? 0;
    $paymentStatus = $data['payment_status'] ?? 'Success';
    $transactionId = $data['transaction_id'] ?? null;
    
    // Log extracted values for debugging
    error_log("Extracted values - userId: $userId, orderId: $orderId, paymentMethod: $paymentMethod, amount: $amount, paymentStatus: $paymentStatus, transactionId: $transactionId");
    
    if (!$userId || !$orderId) {
        throw new Exception('Missing required data: user_id or order_id');
    }
    
    // Start transaction
    $pdo->beginTransaction();
    
    // Insert payment record
    $stmt = $pdo->prepare("
        INSERT INTO payments (User_id, Order_id, Payment_method, Amount, Payment_status, Transaction_id) 
        VALUES (?, ?, ?, ?, ?, ?)
    ");
    
    $stmt->execute([
        $userId,
        $orderId,
        $paymentMethod,
        $amount,
        $paymentStatus,
        $transactionId
    ]);
    
    $paymentId = $pdo->lastInsertId();
    
    // Update order with payment_id
    $stmt = $pdo->prepare("
        UPDATE orders 
        SET Payment_id = ? 
        WHERE Order_id = ?
    ");
    
    $stmt->execute([$paymentId, $orderId]);
    
    // Commit transaction
    $pdo->commit();
    
    // Return success response
    echo json_encode([
        'status' => 'SUCCESS',
        'message' => 'Payment details saved successfully',
        'payment_id' => $paymentId,
        'order_id' => $orderId
    ]);
    
} catch (Exception $e) {
    // Rollback transaction on error
    if (isset($pdo)) {
        $pdo->rollBack();
    }
    
    // Log error details
    error_log('save_payment.php error: ' . $e->getMessage());
    error_log('save_payment.php error trace: ' . $e->getTraceAsString());
    
    http_response_code(500);
    echo json_encode([
        'status' => 'ERROR',
        'message' => 'Failed to save payment details: ' . $e->getMessage(),
        'debug_info' => [
            'error' => $e->getMessage(),
            'file' => $e->getFile(),
            'line' => $e->getLine()
        ]
    ]);
}
?>
