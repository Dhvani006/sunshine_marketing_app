<?php
// Simple test script to test create_order.php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h2>Testing create_order.php Directly</h2>";

// Test data matching exactly what Flutter sends
$testData = [
    'user_id' => 2,
    'cart_items' => [
        [
            'Ecomm_product_id' => 1,
            'Quantity' => 1,
            'Ecomm_product_price' => 184080
        ]
    ],
    'total_amount' => 184080,
    'cashfree_order_id' => 'test123',
    'address' => 'dfe',
    'city' => 'asd',
    'state' => 'dsaf',
    'pincode' => '111222'
];

echo "<h3>Test Data:</h3>";
echo "<pre>" . json_encode($testData, JSON_PRETTY_PRINT) . "</pre>";

// Test 1: Check if create_order.php exists
echo "<h3>1. File Check</h3>";
if (file_exists('create_order.php')) {
    echo "✅ create_order.php exists<br>";
} else {
    echo "❌ create_order.php NOT FOUND<br>";
    exit;
}

// Test 2: Simulate the exact HTTP request
echo "<h3>2. Simulate HTTP Request</h3>";

// Set up the request environment
$_SERVER['REQUEST_METHOD'] = 'POST';
$_SERVER['CONTENT_TYPE'] = 'application/json';

// Set the raw input data
$GLOBALS['HTTP_RAW_POST_DATA'] = json_encode($testData);

echo "Request method: " . $_SERVER['REQUEST_METHOD'] . "<br>";
echo "Content-Type: " . $_SERVER['CONTENT_TYPE'] . "<br>";
echo "Raw input data: " . $GLOBALS['HTTP_RAW_POST_DATA'] . "<br>";

// Test 3: Call create_order.php
echo "<h3>3. Call create_order.php</h3>";

// Capture output and errors
ob_start();
$oldErrorReporting = error_reporting(E_ALL);
$oldDisplayErrors = ini_get('display_errors');
ini_set('display_errors', 1);

try {
    include 'create_order.php';
    $output = ob_get_clean();
    echo "<h4>Response:</h4>";
    echo "<pre>$output</pre>";
} catch (Exception $e) {
    $output = ob_get_clean();
    echo "<h4>Exception caught:</h4>";
    echo "<p>Error: " . $e->getMessage() . "</p>";
    echo "<h4>Output before exception:</h4>";
    echo "<pre>$output</pre>";
}

// Restore settings
error_reporting($oldErrorReporting);
ini_set('display_errors', $oldDisplayErrors);
?>
