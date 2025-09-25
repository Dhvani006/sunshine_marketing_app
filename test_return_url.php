<?php
// Test script to verify return URL functionality
header('Content-Type: application/json');

// Test with the order ID from your database
$testOrderId = 'CF_1758472840_2468c63a';

echo "Testing return URL with order ID: $testOrderId\n";
echo "URL: " . $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI'] . "\n";

// Simulate the return URL call
$returnUrl = "http://192.168.27.5/sunshine_marketing_app_backend/cashfree_return_url.php?order_id=" . $testOrderId;

echo "Calling return URL: $returnUrl\n";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $returnUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

echo "Response Code: $httpCode\n";
if ($error) {
    echo "cURL Error: $error\n";
} else {
    echo "Response: $response\n";
}
?>
