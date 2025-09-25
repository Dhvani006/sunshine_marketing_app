<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        echo json_encode(['status' => 'error', 'message' => 'Only POST method allowed']);
        http_response_code(405);
        exit;
    }

    // Get JSON input
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);

    if (!$data) {
        echo json_encode(['status' => 'error', 'message' => 'Invalid JSON input']);
        http_response_code(400);
        exit;
    }

    // Validate required fields
    if (!isset($data['cart_id'])) {
        echo json_encode(['status' => 'error', 'message' => 'Cart ID is required']);
        http_response_code(400);
        exit;
    }

    $cart_id = $data['cart_id'];

    // Database connection
    $pdo = new PDO('mysql:host=localhost;dbname=sunshine_marketing', 'root', '');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Remove item from cart
    $stmt = $pdo->prepare("DELETE FROM cart WHERE Cart_id = ?");
    $stmt->execute([$cart_id]);

    if ($stmt->rowCount() > 0) {
        echo json_encode([
            'status' => 'success',
            'message' => 'Item removed from cart successfully'
        ]);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Cart item not found']);
        http_response_code(404);
    }

} catch (Exception $e) {
    error_log("Remove from cart error: " . $e->getMessage());
    echo json_encode(['status' => 'error', 'message' => 'Failed to remove item from cart']);
    http_response_code(500);
}
?>
