<?php
// Simple test for Cashfree order creation
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Test data that matches what Flutter app sends
$testData = [
    'order_amount' => '100.00',
    'order_currency' => 'INR',
    'customer_details' => [
        'customer_id' => 'customer_123',
        'customer_name' => 'Test Customer',
        'customer_phone' => '9876543210',
        'customer_email' => 'test@example.com',
    ],
    'order_note' => 'Test order from Flutter app'
];

echo "=== TEST DATA ===\n";
echo json_encode($testData, JSON_PRETTY_PRINT);
echo "\n\n=== TESTING BACKEND ===\n";

// Test the backend
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'http://10.127.160.66/sunshine_marketing_app_backend/cashfree_order.php');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($testData));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

echo "HTTP Code: $httpCode\n";
if ($error) {
    echo "cURL Error: $error\n";
} else {
    echo "Response: $response\n";
}
?>
