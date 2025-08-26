<?php
// Simple test to create a fresh Cashfree order
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>🧪 FRESH CASHFREE ORDER TEST</h1>";

// Test data
$testData = [
    'order_amount' => '100.0',
    'order_currency' => 'INR',
    'customer_details' => [
        'customer_id' => 'test_customer_' . time(),
        'customer_name' => 'Test User',
        'customer_email' => 'test@example.com',
        'customer_phone' => '1234567890'
    ],
    'order_note' => 'Fresh test order'
];

echo "<h2>Test Data:</h2>";
echo "<pre>" . json_encode($testData, JSON_PRETTY_PRINT) . "</pre>";

// Make request to your backend
$url = 'http://localhost/sunshine_marketing_app_backend/cashfree_order.php';

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($testData));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

echo "<h2>Response:</h2>";
echo "<p>HTTP Code: $httpCode</p>";
echo "<p>cURL Error: " . ($error ?: 'None') . "</p>";
echo "<p>Response Body:</p>";
echo "<pre>$response</pre>";

if ($response) {
    $data = json_decode($response, true);
    if ($data && isset($data['payment_session_id'])) {
        echo "<h2>🎉 SUCCESS! Fresh Order Created!</h2>";
        echo "<p><strong>Order ID:</strong> " . $data['order_id'] . "</p>";
        echo "<p><strong>Payment Session ID:</strong> " . $data['payment_session_id'] . "</p>";
        
        $paymentUrl = 'https://sandbox.cashfree.com/pg/checkout/' . $data['payment_session_id'];
        echo "<h3>🔗 Payment URL:</h3>";
        echo "<p><a href='$paymentUrl' target='_blank'>$paymentUrl</a></p>";
        echo "<p><strong>Click the link above to test the payment page!</strong></p>";
        
        echo "<h3>📋 Copy this URL:</h3>";
        echo "<textarea rows='3' cols='80' readonly>$paymentUrl</textarea>";
        
    } else {
        echo "<h2>❌ FAILED!</h2>";
        echo "<p>Could not create order or get payment session ID.</p>";
    }
} else {
    echo "<h2>❌ NO RESPONSE!</h2>";
    echo "<p>Backend did not respond.</p>";
}
?>
