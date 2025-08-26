<?php
// Test script to see what data is being received
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h2>Test Cart Data</h2>";

// Simulate the exact data structure being sent from Flutter
$testData = [
    'user_id' => 2,
    'cart_items' => [
        [
            'Ecomm_product_id' => 1,
            'Quantity' => 1,
            'Ecomm_product_price' => 14160
        ]
    ],
    'total_amount' => 14160,
    'cashfree_order_id' => 'test123',
    'address' => 'test',
    'city' => 'test',
    'state' => 'test',
    'pincode' => '123456'
];

echo "<h3>Test Data Structure:</h3>";
echo "<pre>" . json_encode($testData, JSON_PRETTY_PRINT) . "</pre>";

echo "<h3>Testing Field Extraction:</h3>";
foreach ($testData['cart_items'] as $index => $item) {
    echo "<h4>Item $index:</h4>";
    
    // Test the exact field names from cart
    $productId = $item['Ecomm_product_id'] ?? null;
    $quantity = $item['Quantity'] ?? 1;
    $price = $item['Ecomm_product_price'] ?? 0;
    
    echo "Ecomm_product_id: " . ($productId ?? 'NULL') . "<br>";
    echo "Quantity: " . $quantity . "<br>";
    echo "Ecomm_product_price: " . $price . "<br>";
    
    // Test the fallback logic
    $fallbackProductId = $item['product_id'] ?? $item['Ecomm_product_id'] ?? null;
    $fallbackQuantity = $item['quantity'] ?? $item['Quantity'] ?? 1;
    $fallbackPrice = $item['price'] ?? $item['Ecomm_product_price'] ?? 0;
    
    echo "<strong>Fallback Logic:</strong><br>";
    echo "product_id: " . ($fallbackProductId ?? 'NULL') . "<br>";
    echo "quantity: " . $fallbackQuantity . "<br>";
    echo "price: " . $fallbackPrice . "<br>";
    
    $totalAmount = $fallbackPrice * $fallbackQuantity;
    echo "totalAmount: " . $totalAmount . "<br>";
    
    if (!$fallbackProductId || $totalAmount <= 0) {
        echo "<strong style='color: red;'>❌ Invalid cart item data</strong><br>";
    } else {
        echo "<strong style='color: green;'>✅ Valid cart item data</strong><br>";
    }
    echo "<hr>";
}

echo "<h3>Address Fields:</h3>";
echo "address: '" . ($testData['address'] ?? '') . "'<br>";
echo "city: '" . ($testData['city'] ?? '') . "'<br>";
echo "state: '" . ($testData['state'] ?? '') . "'<br>";
echo "pincode: '" . ($testData['pincode'] ?? '') . "'<br>";
?>
