<?php
// Debug script to test payment insertion
header('Content-Type: application/json');

// Database configuration
$host = 'localhost';
$dbname = 'sunshine_marketing';
$username = 'root';
$password = '';

try {
    // Create database connection
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "Database connection successful\n";
    
    // Check if user exists
    $userId = 2; // Test with user ID 2
    $stmt = $pdo->prepare("SELECT U_id, Username FROM users WHERE U_id = ?");
    $stmt->execute([$userId]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($user) {
        echo "User found: " . json_encode($user) . "\n";
    } else {
        echo "User not found with ID: $userId\n";
    }
    
    // Check orders table structure
    echo "\nOrders table structure:\n";
    $stmt = $pdo->prepare("DESCRIBE orders");
    $stmt->execute();
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($columns as $column) {
        echo "- " . $column['Field'] . " (" . $column['Type'] . ")\n";
    }
    
    // Check payments table structure
    echo "\nPayments table structure:\n";
    $stmt = $pdo->prepare("DESCRIBE payments");
    $stmt->execute();
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($columns as $column) {
        echo "- " . $column['Field'] . " (" . $column['Type'] . ")\n";
    }
    
    // Check recent orders
    echo "\nRecent orders:\n";
    $stmt = $pdo->prepare("SELECT Order_id, User_id, Total_amount, cashfree_order_id FROM orders ORDER BY Order_id DESC LIMIT 5");
    $stmt->execute();
    $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($orders as $order) {
        echo "- Order ID: " . $order['Order_id'] . ", User ID: " . $order['User_id'] . ", Amount: " . $order['Total_amount'] . ", Cashfree ID: " . $order['cashfree_order_id'] . "\n";
    }
    
    // Test payment insertion with a valid order ID
    if (!empty($orders)) {
        $testOrderId = $orders[0]['Order_id'];
        echo "\nTesting payment insertion with order ID: $testOrderId\n";
        
        try {
            $stmt = $pdo->prepare("
                INSERT INTO payments (User_id, Order_id, Payment_method, Amount, Payment_status, Transaction_id) 
                VALUES (?, ?, ?, ?, ?, ?)
            ");
            
            $stmt->execute([
                $userId,
                $testOrderId,
                'UPI',
                100.00,
                'Success',
                'TEST_TXN_' . time()
            ]);
            
            $paymentId = $pdo->lastInsertId();
            echo "Payment inserted successfully with ID: $paymentId\n";
            
            // Clean up test payment
            $stmt = $pdo->prepare("DELETE FROM payments WHERE Payment_id = ?");
            $stmt->execute([$paymentId]);
            echo "Test payment cleaned up\n";
            
        } catch (Exception $e) {
            echo "Payment insertion failed: " . $e->getMessage() . "\n";
        }
    }
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
    echo "Stack trace: " . $e->getTraceAsString() . "\n";
}
?>
