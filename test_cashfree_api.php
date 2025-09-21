<?php
// Test Cashfree API with correct credentials
require_once 'config_simple.php';

echo "=== CASHFREE API TEST ===\n";
echo "Testing payment session creation...\n\n";

try {
    $config = include 'config_simple.php';
    $cf = $config['cashfree'];
    
    echo "✅ Configuration loaded\n";
    echo "App ID: " . substr($cf['client_id'], 0, 10) . "...\n";
    echo "Secret: " . substr($cf['client_secret'], 0, 10) . "...\n";
    echo "Environment: " . $cf['environment'] . "\n\n";
    
    // Test API call
    $baseUrl = $cf['environment'] === 'sandbox' ? 'https://sandbox.cashfree.com' : 'https://api.cashfree.com';
    $url = $baseUrl . '/pg/orders';
    
    $payload = [
        'order_id' => 'TEST_' . time(),
        'order_amount' => 100.0,
        'order_currency' => 'INR',
        'customer_details' => [
            'customer_id' => 'test_customer',
            'customer_email' => 'test@example.com',
            'customer_phone' => '1234567890'
        ],
        'order_note' => 'Test order from API'
    ];
    
    $headers = [
        'Content-Type: application/json',
        'x-client-id: ' . $cf['client_id'],
        'x-client-secret: ' . $cf['client_secret'],
        'x-api-version: 2023-08-01'
    ];
    
    echo "Making API call to: $url\n";
    echo "Payload: " . json_encode($payload, JSON_PRETTY_PRINT) . "\n\n";
    
    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL => $url,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode($payload),
        CURLOPT_HTTPHEADER => $headers,
        CURLOPT_TIMEOUT => 30
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);
    
    echo "=== API RESPONSE ===\n";
    echo "HTTP Code: $httpCode\n";
    
    if ($curlError) {
        echo "cURL Error: $curlError\n";
    } else {
        echo "Response: $response\n";
        
        if ($httpCode === 200) {
            $data = json_decode($response, true);
            if (isset($data['order_id'])) {
                echo "\n✅ SUCCESS! Payment session created\n";
                echo "Order ID: " . $data['order_id'] . "\n";
                echo "Payment Session ID: " . $data['payment_session_id'] . "\n";
            } else {
                echo "\n❌ Unexpected response format\n";
            }
        } else {
            echo "\n❌ API call failed with HTTP $httpCode\n";
        }
    }
    
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
}

echo "\n=== TEST COMPLETE ===\n";
?>
