<?php
// Debug script for create_order.php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h2>Debug Create Order</h2>";

// Test data
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

echo "<h3>Test Data:</h3>";
echo "<pre>" . json_encode($testData, JSON_PRETTY_PRINT) . "</pre>";

// Test cart item processing
echo "<h3>Testing Cart Item Processing:</h3>";
foreach ($testData['cart_items'] as $index => $item) {
    echo "<h4>Item $index:</h4>";
    
    // Test field extraction
    $productId = $item['product_id'] ?? $item['Ecomm_product_id'] ?? null;
    $quantity = $item['quantity'] ?? $item['Quantity'] ?? 1;
    $price = $item['price'] ?? $item['Ecomm_product_price'] ?? 0;
    $totalAmount = $price * $quantity;
    
    echo "product_id: " . ($productId ?? 'NULL') . "<br>";
    echo "quantity: " . $quantity . "<br>";
    echo "price: " . $price . "<br>";
    echo "totalAmount: " . $totalAmount . "<br>";
    
    if (!$productId || $totalAmount <= 0) {
        echo "<strong style='color: red;'>❌ Invalid cart item data</strong><br>";
        echo "product_id: " . ($productId ?? 'NULL') . "<br>";
        echo "price: " . $price . "<br>";
        echo "quantity: " . $quantity . "<br>";
    } else {
        echo "<strong style='color: green;'>✅ Valid cart item data</strong><br>";
    }
    echo "<hr>";
}

// Test address field extraction
echo "<h3>Testing Address Field Extraction:</h3>";
$address = $testData['address'] ?? '';
$city = $testData['city'] ?? '';
$state = $testData['state'] ?? '';
$pincode = $testData['pincode'] ?? '';

echo "address: '$address'<br>";
echo "city: '$city'<br>";
echo "state: '$state'<br>";
echo "pincode: '$pincode'<br>";

if (empty($address) || empty($city) || empty($state) || empty($pincode)) {
    echo "<strong style='color: red;'>❌ Missing address fields</strong><br>";
} else {
    echo "<strong style='color: green;'>✅ All address fields present</strong><br>";
}
?>
