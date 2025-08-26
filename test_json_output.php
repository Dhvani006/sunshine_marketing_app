<?php
/**
 * Test JSON Output from Web Checkout
 * This will help verify that the endpoint returns clean JSON
 */

echo "=== Testing JSON Output ===\n\n";

// Test data
$testData = [
    'order_id' => 'test_order_123',
    'payment_session_id' => 'test_session_456',
    'amount' => '100'
];

echo "Test Data: " . json_encode($testData) . "\n\n";

// Make request to web checkout endpoint
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'http://localhost/sunshine_marketing_app_backend/cashfree_web_checkout.php');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($testData));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json'
]);

echo "Making request to web checkout endpoint...\n";

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
} else {
    echo "❌ Response is NOT valid JSON\n";
    echo "JSON Error: " . json_last_error_msg() . "\n";
    
    // Check for HTML content
    if (strpos($response, '<') !== false || strpos($response, '>') !== false) {
        echo "⚠️ Response contains HTML tags!\n";
        echo "This is likely causing the FormatException in Flutter.\n";
    }
}

echo "\n=== Test Complete ===\n";
?>
