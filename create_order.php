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

try {
    // Create database connection
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Get JSON input
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);
    
    if (!$data) {
        throw new Exception('Invalid JSON data received');
    }
    
    $userId = $data['user_id'] ?? null;
    $cartItems = $data['cart_items'] ?? [];
    $totalAmount = $data['total_amount'] ?? 0;
    $cashfreeOrderId = $data['cashfree_order_id'] ?? null;
    $address = $data['address'] ?? '';
    $city = $data['city'] ?? '';
    $state = $data['state'] ?? '';
    $pincode = $data['pincode'] ?? '';
    
    if (!$userId || empty($cartItems)) {
        throw new Exception('Missing required data: user_id or cart_items');
    }
    
    // Start transaction
    $pdo->beginTransaction();
    
    $orderIds = [];
    
    // Create orders for each cart item
    foreach ($cartItems as $item) {
        $productId = $item['Ecomm_product_id'] ?? null;
        $quantity = $item['Quantity'] ?? 1;
        
        if (!$productId) {
            throw new Exception('Invalid product ID in cart item');
        }
        
        // Insert order
        $stmt = $pdo->prepare("
            INSERT INTO orders (User_id, Ecomm_product_id, Quantity, Total_amount, cashfree_order_id, address, city, state, pincode) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ");
        
        $stmt->execute([
            $userId,
            $productId,
            $quantity,
            $totalAmount / count($cartItems), // Distribute total amount across items
            $cashfreeOrderId,
            $address,
            $city,
            $state,
            $pincode
        ]);
        
        $orderId = $pdo->lastInsertId();
        $orderIds[] = $orderId;
        
        // Clear cart item
        $cartId = $item['Cart_id'] ?? null;
        if ($cartId) {
            $stmt = $pdo->prepare("DELETE FROM cart WHERE Cart_id = ?");
            $stmt->execute([$cartId]);
        }
    }
    
    // Commit transaction
    $pdo->commit();
    
    // Return success response
    echo json_encode([
        'status' => 'SUCCESS',
        'message' => 'Orders created successfully',
        'order_ids' => $orderIds,
        'total_orders' => count($orderIds)
    ]);
    
} catch (Exception $e) {
    // Rollback transaction on error
    if (isset($pdo)) {
        $pdo->rollBack();
    }
    
    http_response_code(500);
    echo json_encode([
        'status' => 'ERROR',
        'message' => 'Failed to create orders: ' . $e->getMessage()
    ]);
}
?>
