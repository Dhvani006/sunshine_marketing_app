<?php
// Simple database connection test
header('Content-Type: application/json');

try {
    // Database connection
    $host = 'localhost';
    $dbname = 'sunshine_marketing';
    $username = 'root';
    $password = '';

    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo json_encode([
        'status' => 'SUCCESS',
        'message' => 'Database connection successful',
        'database' => $dbname
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'ERROR',
        'message' => 'Database connection failed: ' . $e->getMessage()
    ]);
}
?>
