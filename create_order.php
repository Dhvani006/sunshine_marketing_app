<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

try {
    // Database connection
    $pdo = new PDO('mysql:host=localhost;dbname=sunshine_marketing', 'root', '');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Get JSON input
    $input = file_get_contents('php://input');
    
    $data = json_decode($input, true);

    if (!$data) {
        throw new Exception('Invalid JSON input');
    }

    // Validate required fields
    $required_fields = ['user_id', 'items', 'address', 'city', 'state', 'pincode', 'total_amount'];
    foreach ($required_fields as $field) {
        if (!isset($data[$field]) || ($field !== 'items' && empty($data[$field]))) {
            throw new Exception("Missing required field: $field");
        }
    }

    $user_id = $data['user_id'];
    $items = $data['items'];
    $address = $data['address'];
    $city = $data['city'];
    $state = $data['state'];
    $pincode = $data['pincode'];
    $total_amount = $data['total_amount'];
    $order_status = $data['order_status'] ?? 'Pending';
    $payment_status = $data['payment_status'] ?? 'Pending';

    // Start transaction
    $pdo->beginTransaction();

    try {
        $order_ids = [];
        
        // Insert orders for each item
        foreach ($items as $item) {
            $stmt = $pdo->prepare("
                INSERT INTO orders (
                    User_id, 
                    Ecomm_product_id, 
                    Quantity, 
                    Total_amount, 
                    Order_status, 
                    payment_status,
                    address, 
                    city, 
                    state, 
                    pincode
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            
            $item_total = $item['price'] * $item['quantity'];
            
            $stmt->execute([
                $user_id,
                $item['id'],
                $item['quantity'],
                $item_total,
                $order_status,
                $payment_status,
                $address,
                $city,
                $state,
                $pincode
            ]);
            
            $order_ids[] = $pdo->lastInsertId();
        }

        // Commit transaction
        $pdo->commit();

        echo json_encode([
            'success' => true,
            'message' => 'Order created successfully',
            'data' => [
                'order_ids' => $order_ids,
                'total_amount' => $total_amount
            ]
        ]);

    } catch (Exception $e) {
        $pdo->rollBack();
        throw $e;
    }

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Failed to create order: ' . $e->getMessage()
    ]);
}
?>
