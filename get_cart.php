<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
        echo json_encode(['status' => 'error', 'message' => 'Only GET method allowed']);
        http_response_code(405);
        exit;
    }

    // Get user_id from query parameters
    $user_id = $_GET['user_id'] ?? null;
    
    if (!$user_id) {
        echo json_encode(['status' => 'error', 'message' => 'User ID is required']);
        http_response_code(400);
        exit;
    }

    // Database connection
    $pdo = new PDO('mysql:host=localhost;dbname=sunshine_marketing', 'root', '');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Get cart items with product details
    $stmt = $pdo->prepare("
        SELECT 
            c.Cart_id,
            c.User_id,
            c.Ecomm_product_id,
            c.Quantity,
            c.Payment_status,
            c.Unique_code,
            p.Ecomm_product_name,
            p.Ecomm_product_image,
            p.Ecomm_product_price
        FROM cart c
        INNER JOIN ecomm_product p ON c.Ecomm_product_id = p.Ecomm_product_id
        WHERE c.User_id = ?
        ORDER BY c.Cart_id DESC
    ");
    
    $stmt->execute([$user_id]);
    $cartItems = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'status' => 'success',
        'message' => 'Cart items retrieved successfully',
        'cart' => $cartItems
    ]);

} catch (Exception $e) {
    error_log("Get cart error: " . $e->getMessage());
    echo json_encode(['status' => 'error', 'message' => 'Failed to retrieve cart items']);
    http_response_code(500);
}
?>
