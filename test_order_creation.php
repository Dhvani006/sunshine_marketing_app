<?php
/**
 * Test Order Creation Step by Step
 * This will help debug the 400 error
 */

echo "=== Testing Cashfree Order Creation ===\n\n";

// Include configuration
require_once 'cashfree_config.php';

// Test data matching your Flutter app
$testData = [
    'order_amount' => '100',
    'order_currency' => 'INR',
    'customer_id' => 'customer_' . time(),
    'customer_name' => 'Test Customer',
    'customer_email' => 'test@example.com',
    'customer_phone' => '9876543210',
    'order_note' => 'Test order from debug script'
];

echo "Test Data:\n";
echo json_encode($testData, JSON_PRETTY_PRINT) . "\n\n";

// Test the order creation endpoint - Using port 8080
echo "=== Testing Order Creation Endpoint ===\n";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'http://localhost:8080/sunshine_marketing_app_backend/cashfree_order.php');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($testData));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json'
]);

echo "Making request to order creation endpoint...\n";
echo "URL: http://localhost:8080/sunshine_marketing_app_backend/cashfree_order.php\n\n";

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

if ($error) {
    echo "❌ cURL Error: $error\n";
    exit(1);
}

echo "HTTP Status Code: $httpCode\n";
echo "Response Length: " . strlen($response) . " characters\n\n";

echo "Raw Response:\n";
echo "----------------------------------------\n";
echo $response;
echo "\n----------------------------------------\n\n";

// Check if response is valid JSON
$decoded = json_decode($response, true);
if (json_last_error() === JSON_ERROR_NONE) {
    echo "✅ Response is valid JSON\n";
    echo "Decoded Data:\n";
    print_r($decoded);
    
    if ($decoded['status'] === 'SUCCESS') {
        echo "\n🎉 Order created successfully!\n";
        echo "Order ID: " . ($decoded['order_id'] ?? 'N/A') . "\n";
        echo "Payment Session ID: " . ($decoded['payment_session_id'] ?? 'N/A') . "\n";
    } else {
        echo "\n❌ Order creation failed\n";
        echo "Error: " . ($decoded['message'] ?? 'Unknown error') . "\n";
        
        if (isset($decoded['response'])) {
            echo "Cashfree API Response:\n";
            print_r($decoded['response']);
        }
    }
} else {
    echo "❌ Response is NOT valid JSON\n";
    echo "JSON Error: " . json_last_error_msg() . "\n";
}

echo "\n=== Test Complete ===\n";
?>
