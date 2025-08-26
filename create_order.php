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

    // Extract order details
    $userId = $data['user_id'] ?? null;
    $cartItems = $data['cart_items'] ?? [];
    $customerDetails = $data['customer_details'] ?? [];
    $cashfreeOrderId = $data['cashfree_order_id'] ?? '';
    
    // Debug logging
    error_log("Create Order - Received data: " . json_encode($data));
    error_log("Create Order - Cart items: " . json_encode($cartItems));
    error_log("Create Order - User ID: " . $userId);

    // Validate required fields
    if (!$userId || empty($cartItems)) {
        throw new Exception('Missing required fields: user_id, cart_items');
    }

    // Start transaction
    $pdo->beginTransaction();

    try {
        $createdOrders = [];

        // Create orders for each cart item
        foreach ($cartItems as $index => $item) {
            error_log("Processing cart item $index: " . json_encode($item));
            
            // Handle both field name formats
            $productId = $item['product_id'] ?? $item['Ecomm_product_id'] ?? null;
            $quantity = $item['quantity'] ?? $item['Quantity'] ?? 1;
            $price = $item['price'] ?? $item['Ecomm_product_price'] ?? 0;
            $totalAmount = $price * $quantity;
            
            error_log("Extracted values - productId: $productId, quantity: $quantity, price: $price, totalAmount: $totalAmount");

            if (!$productId || $totalAmount <= 0) {
                error_log("Invalid cart item data: " . json_encode($item));
                error_log("Validation failed - productId: " . ($productId ?? 'NULL') . ", price: $price, quantity: $quantity, totalAmount: $totalAmount");
                throw new Exception('Invalid cart item data: product_id=' . ($productId ?? 'NULL') . ', price=' . $price . ', quantity=' . $quantity . ', totalAmount=' . $totalAmount);
            }

            // Insert order
            error_log("About to insert order with values: userId=$userId, productId=$productId, quantity=$quantity, totalAmount=$totalAmount, cashfreeOrderId=$cashfreeOrderId");
            
            $address = $data['address'] ?? $customerDetails['address'] ?? '';
            $city = $data['city'] ?? $customerDetails['city'] ?? '';
            $state = $data['state'] ?? $customerDetails['state'] ?? '';
            $pincode = $data['pincode'] ?? $customerDetails['pincode'] ?? '';
            
            error_log("Address fields: address='$address', city='$city', state='$state', pincode='$pincode'");
            
            $stmt = $pdo->prepare("
                INSERT INTO orders (User_id, Ecomm_product_id, Quantity, Total_amount, Order_status, cashfree_order_id, address, city, state, pincode, Order_date) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
            ");

            error_log("SQL prepared, executing with parameters...");
            $stmt->execute([
                $userId,
                $productId,
                $quantity,
                $totalAmount,
                'Pending',
                $cashfreeOrderId,
                $address,
                $city,
                $state,
                $pincode
            ]);
            
                        error_log("Order inserted successfully, getting last insert ID...");
            
            $orderId = $pdo->lastInsertId();
            error_log("Last insert ID: $orderId");
            
            $createdOrders[] = [
                'order_id' => $orderId,
                'product_id' => $productId,
                'quantity' => $quantity,
                'total_amount' => $totalAmount
            ];
            
            error_log("Added to createdOrders array. Array now has " . count($createdOrders) . " items");
        }

        // Commit transaction
        error_log("About to commit transaction...");
        $pdo->commit();
        error_log("Transaction committed successfully");

        // Return success response
        error_log("Preparing success response...");
        $response = [
            'status' => 'SUCCESS',
            'message' => 'Orders created successfully',
            'order_ids' => array_column($createdOrders, 'order_id'),
            'cashfree_order_id' => $cashfreeOrderId
        ];
        error_log("Response data: " . json_encode($response));
        
        echo json_encode($response);
        error_log("Response sent successfully");

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
        'message' => 'Order creation failed: ' . $e->getMessage()
    ]);
}
?>
