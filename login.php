<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Start output buffering to prevent any accidental output
ob_start();

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    ob_end_clean();
    exit(0);
}

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        ob_end_clean();
        echo json_encode(['status' => 'error', 'message' => 'Only POST method allowed']);
        http_response_code(405);
        exit;
    }

    // Database connection with better error handling
    try {
        $pdo = new PDO('mysql:host=localhost;dbname=sunshine_marketing', 'root', '');
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    } catch (PDOException $e) {
        ob_end_clean();
        error_log("Database connection error: " . $e->getMessage());
        echo json_encode(['status' => 'error', 'message' => 'Database connection failed']);
        http_response_code(500);
        exit;
    }

    // Get JSON input
    $input = file_get_contents('php://input');
    error_log("Received input: " . $input); // Debug log
    
    $data = json_decode($input, true);

    if (!$data) {
        ob_end_clean();
        error_log("JSON decode error: " . json_last_error_msg());
        echo json_encode(['status' => 'error', 'message' => 'Invalid JSON input']);
        http_response_code(400);
        exit;
    }

    // Validate required fields
    if (!isset($data['email']) || !isset($data['password'])) {
        ob_end_clean();
        echo json_encode(['status' => 'error', 'message' => 'Email and password are required']);
        http_response_code(400);
        exit;
    }

    $email = trim($data['email']);
    $password = $data['password'];

    // Find user by email or phone number
    $stmt = $pdo->prepare("SELECT U_id, Username, Email, Password, Phone_number, Address, Role, email_verified, status FROM users WHERE Email = ? OR Phone_number = ?");
    $stmt->execute([$email, $email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        ob_end_clean();
        echo json_encode(['status' => 'error', 'message' => 'No account found with this email/mobile number']);
        http_response_code(401);
        exit;
    }

    // Verify password
    if (!password_verify($password, $user['Password'])) {
        ob_end_clean();
        echo json_encode(['status' => 'error', 'message' => 'Incorrect password']);
        http_response_code(401);
        exit;
    }

    // Check if user is blocked
    if ($user['status'] === 'blocked') {
        ob_end_clean();
        echo json_encode(['status' => 'error', 'message' => 'Your account has been blocked']);
        http_response_code(403);
        exit;
    }

    // Check if email is verified
    if ($user['email_verified'] == 0) {
        ob_end_clean();
        echo json_encode(['status' => 'error', 'message' => 'Please verify your email before logging in']);
        http_response_code(403);
        exit;
    }

    // Update last login
    $stmt = $pdo->prepare("UPDATE users SET last_login = NOW() WHERE U_id = ?");
    $stmt->execute([$user['U_id']]);

    // Clear any output buffer and return success response
    ob_end_clean();
    echo json_encode([
        'status' => 'success',
        'message' => 'Login successful',
        'user_id' => $user['U_id'],
        'username' => $user['Username'],
        'email' => $user['Email'],
        'role' => $user['Role']
    ]);

} catch (Exception $e) {
    ob_end_clean();
    error_log("Login error: " . $e->getMessage());
    echo json_encode(['status' => 'error', 'message' => 'An unexpected error occurred']);
    http_response_code(500);
}
?>

