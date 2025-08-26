<?php
/**
 * Test Script for Cashfree API Order Creation
 * This will help debug the payment session ID issue
 */

echo "=== Testing Cashfree API Order Creation ===\n\n";

// Include configuration
require_once 'cashfree_config.php';

// Test data - Added missing order_currency field
$testData = [
    'order_amount' => '100',
    'order_currency' => 'INR',  // Added this required field
    'customer_details' => [
        'customer_id' => 'customer_' . time(),
        'customer_name' => 'Test Customer',
        'customer_email' => 'test@example.com',
        'customer_phone' => '9876543210'
    ],
    'order_note' => 'Test order from API test script'
];

echo "Test Data:\n";
echo "Amount: {$testData['order_amount']}\n";
echo "Currency: {$testData['order_currency']}\n";
echo "Customer: {$testData['customer_details']['customer_name']}\n";
echo "Email: {$testData['customer_details']['customer_email']}\n";
echo "Phone: {$testData['customer_details']['customer_phone']}\n\n";

try {
    // Make API call to Cashfree
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, getCashfreeBaseUrl() . '/orders');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($testData));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'x-client-id: ' . getCashfreeClientId(),
        'x-client-secret: ' . getCashfreeClientSecret(),
        'x-api-version: ' . getCashfreeApiVersion()
    ]);
    
    echo "Making API call to: " . getCashfreeBaseUrl() . '/orders' . "\n";
    echo "Client ID: " . substr(getCashfreeClientId(), 0, 8) . "...\n";
    echo "Environment: " . getCashfreeEnvironment() . "\n\n";
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    if ($error) {
        echo "❌ cURL Error: $error\n";
        exit(1);
    }
    
    echo "HTTP Status Code: $httpCode\n\n";
    
    if ($httpCode === 200) {
        $responseData = json_decode($response, true);
        echo "✅ SUCCESS! Order created successfully\n\n";
        echo "Response Data:\n";
        echo "Order ID: " . ($responseData['order_id'] ?? 'N/A') . "\n";
        echo "Payment Session ID: " . ($responseData['payment_session_id'] ?? 'N/A') . "\n";
        echo "Order Status: " . ($responseData['order_status'] ?? 'N/A') . "\n";
        echo "Order Amount: " . ($responseData['order_amount'] ?? 'N/A') . "\n\n";
        
        // Test the checkout URL
        if (isset($responseData['payment_session_id'])) {
            $checkoutUrl = 'https://test.cashfree.com/pg/checkout/' . $responseData['payment_session_id'];
            echo "Checkout URL: $checkoutUrl\n\n";
            
            // Test if the checkout URL is accessible
            echo "Testing checkout URL accessibility...\n";
            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $checkoutUrl);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_NOBODY, true);
            curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
            
            $checkoutResponse = curl_exec($ch);
            $checkoutHttpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            
            echo "Checkout URL HTTP Code: $checkoutHttpCode\n";
            
            if ($checkoutHttpCode === 200 || $checkoutHttpCode === 302) {
                echo "✅ Checkout URL is accessible\n";
            } else {
                echo "⚠️ Checkout URL returned code: $checkoutHttpCode\n";
            }
        }
        
    } else {
        echo "❌ API call failed with status: $httpCode\n";
        echo "Response: $response\n";
    }
    
} catch (Exception $e) {
    echo "❌ Exception: " . $e->getMessage() . "\n";
}

echo "\n=== Test Complete ===\n";
?>
