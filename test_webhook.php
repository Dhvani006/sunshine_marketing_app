<?php
// Test script to simulate Cashfree webhook calls
// Use this to test your webhook endpoint

$webhookUrl = 'https://74412feae097.ngrok-free.app/cashfree_webhook.php';

// Sample webhook payload (successful payment)
$successPayload = [
    'orderId' => 'order_12785331jTeDeKPrJJx0SoDRyqtJfWVgX',
    'orderAmount' => 56640.00,
    'orderStatus' => 'PAID',
    'paymentStatus' => 'SUCCESS',
    'transactionId' => 'CF_TXN_' . time(),
    'customerDetails' => [
        'customerName' => 'Test User',
        'customerEmail' => 'test@example.com',
        'customerPhone' => '9999999999'
    ]
];

// Sample webhook payload (failed payment)
$failedPayload = [
    'orderId' => 'order_12785331jTeDeKPrJJx0SoDRyqtJfWVgX',
    'orderAmount' => 56640.00,
    'orderStatus' => 'FAILED',
    'paymentStatus' => 'FAILED',
    'transactionId' => 'CF_TXN_' . time(),
    'customerDetails' => [
        'customerName' => 'Test User',
        'customerEmail' => 'test@example.com',
        'customerPhone' => '9999999999'
    ]
];

function testWebhook($url, $payload, $description) {
    echo "Testing: $description\n";
    echo "URL: $url\n";
    echo "Payload: " . json_encode($payload, JSON_PRETTY_PRINT) . "\n\n";
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'X-Webhook-Signature: test_signature'
    ]);
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
    echo "----------------------------------------\n\n";
}

// Test successful payment
testWebhook($webhookUrl, $successPayload, "Successful Payment Webhook");

// Test failed payment
testWebhook($webhookUrl, $failedPayload, "Failed Payment Webhook");

echo "Webhook testing completed!\n";
?>
