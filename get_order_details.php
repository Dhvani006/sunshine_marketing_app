<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    echo json_encode(['success' => false, 'message' => 'Only GET method allowed']);
    http_response_code(405);
    exit;
}

// Get order ID from query parameter
$orderId = $_GET['order_id'] ?? '';

if (empty($orderId)) {
    echo json_encode(['success' => false, 'message' => 'Order ID is required']);
    http_response_code(400);
    exit;
}

try {
    // Connect to database
    $pdo = new PDO('mysql:host=localhost;dbname=sunshine_marketing', 'root', '');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Get order details
    $stmt = $pdo->prepare("SELECT * FROM orders WHERE Order_id = ? OR cashfree_order_id = ?");
    $stmt->execute([$orderId, $orderId]);
    $order = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$order) {
        echo json_encode(['success' => false, 'message' => 'Order not found']);
        http_response_code(404);
        exit;
    }
    
    // Get payment details if available
    $stmt = $pdo->prepare("SELECT * FROM payments WHERE Order_id = ?");
    $stmt->execute([$order['Order_id']]);
    $payment = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Get order items if available
    $stmt = $pdo->prepare("SELECT * FROM order_items WHERE Order_id = ?");
    $stmt->execute([$order['Order_id']]);
    $orderItems = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Return order details
    echo json_encode([
        'success' => true,
        'order' => $order,
        'payment' => $payment,
        'order_items' => $orderItems
    ]);
    
} catch (Exception $e) {
    error_log("Error fetching order details: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    http_response_code(500);
}
?>
