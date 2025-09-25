<?php
// Debug script to check order in database
header('Content-Type: application/json');

try {
    $pdo = new PDO('mysql:host=localhost;dbname=sunshine_marketing', 'root', '');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $testOrderId = 'CF_1758472840_2468c63a';
    
    echo "Looking for order with cashfree_order_id: $testOrderId\n";
    
    $stmt = $pdo->prepare("SELECT Order_id, User_id, Total_amount, cashfree_order_id FROM orders WHERE cashfree_order_id = ?");
    $stmt->execute([$testOrderId]);
    $order = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($order) {
        echo "Found order:\n";
        echo json_encode($order, JSON_PRETTY_PRINT);
    } else {
        echo "Order not found!\n";
        
        // Let's check what orders exist
        echo "\nAll orders with cashfree_order_id:\n";
        $stmt = $pdo->prepare("SELECT Order_id, cashfree_order_id FROM orders WHERE cashfree_order_id IS NOT NULL ORDER BY Order_id DESC LIMIT 10");
        $stmt->execute();
        $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach ($orders as $o) {
            echo "Order ID: {$o['Order_id']}, Cashfree ID: {$o['cashfree_order_id']}\n";
        }
    }
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
?>
