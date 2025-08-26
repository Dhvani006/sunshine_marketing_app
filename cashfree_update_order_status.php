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

    // Extract data
    $orderId = $data['order_id'] ?? null;
    $transactionId = $data['transaction_id'] ?? null;
    $paymentStatus = $data['payment_status'] ?? null;
    $amount = $data['amount'] ?? null;
    $customerDetails = $data['customer_details'] ?? null;

    // Validate required fields
    if (!$orderId || !$transactionId || !$paymentStatus || !$amount) {
        throw new Exception('Missing required fields: order_id, transaction_id, payment_status, amount');
    }

    // Start transaction
    $pdo->beginTransaction();

    try {
        // Update the order status in your local database
        $stmt = $pdo->prepare("
            UPDATE orders 
            SET Order_status = 'Completed', 
                Payment_status = ?,
                Updated_at = NOW()
            WHERE Order_id = ?
        ");
        $stmt->execute([$paymentStatus, $orderId]);

        // Update or create payment record with Cashfree data
        $stmt = $pdo->prepare("
            INSERT INTO payments (User_id, Order_id, Payment_method, Amount, Payment_status, Transaction_id, Cashfree_order_id, Cashfree_transaction_id, Created_at) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())
            ON DUPLICATE KEY UPDATE
                Payment_status = VALUES(Payment_status),
                Transaction_id = VALUES(Transaction_id),
                Cashfree_order_id = VALUES(Cashfree_order_id),
                Cashfree_transaction_id = VALUES(Cashfree_transaction_id),
                Updated_at = NOW()
        ");
        
        // Get user_id from orders table
        $stmt2 = $pdo->prepare("SELECT User_id FROM orders WHERE Order_id = ?");
        $stmt2->execute([$orderId]);
        $orderData = $stmt2->fetch();
        $userId = $orderData['User_id'] ?? 0;

        $stmt->execute([
            $userId,
            $orderId,
            'Cashfree',
            $amount,
            $paymentStatus,
            $transactionId,
            $orderId, // Cashfree order ID
            $transactionId, // Cashfree transaction ID
        ]);

        // Now call Cashfree API to update their dashboard
        $cashfreeResponse = _updateCashfreeOrderStatus($orderId, $transactionId, $paymentStatus, $amount, $customerDetails);

        // Commit transaction
        $pdo->commit();

        // Return success response
        echo json_encode([
            'status' => 'SUCCESS',
            'message' => 'Order status updated and synced with Cashfree',
            'order_id' => $orderId,
            'transaction_id' => $transactionId,
            'cashfree_response' => $cashfreeResponse
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
        'message' => 'Failed to update order status: ' . $e->getMessage()
    ]);
}

// Function to update Cashfree order status
function _updateCashfreeOrderStatus($orderId, $transactionId, $paymentStatus, $amount, $customerDetails) {
    try {
        // Include Cashfree configuration
        require_once 'cashfree_config.php';
        
        // Get Cashfree credentials
        $appId = getCashfreeAppId();
        $clientId = getCashfreeClientId();
        $clientSecret = getCashfreeClientSecret();
        $baseUrl = getCashfreeBaseUrl();
        
        // Prepare data for Cashfree API
        $cashfreeData = [
            'orderId' => $orderId,
            'orderAmount' => $amount,
            'orderCurrency' => 'INR',
            'orderStatus' => $paymentStatus,
            'transactionId' => $transactionId,
            'customerDetails' => $customerDetails,
        ];
        
        // Make API call to Cashfree to update order status
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $baseUrl . '/orders/' . $orderId . '/status');
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($cashfreeData));
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'x-client-id: ' . $clientId,
            'x-client-secret: ' . $clientSecret,
            'x-api-version: 2022-09-01'
        ]);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        if ($httpCode === 200) {
            return json_decode($response, true);
        } else {
            error_log("Cashfree API call failed: HTTP $httpCode - $response");
            return ['error' => 'Cashfree API call failed', 'http_code' => $httpCode];
        }
        
    } catch (Exception $e) {
        error_log("Error updating Cashfree order status: " . $e->getMessage());
        return ['error' => $e->getMessage()];
    }
}
?>
