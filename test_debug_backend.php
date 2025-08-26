<?php
// Comprehensive debug test script
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>🔍 COMPREHENSIVE BACKEND DEBUG TEST</h1>";

// Test 1: Check if create_order.php exists
echo "<h2>1. File Check</h2>";
if (file_exists('create_order.php')) {
    echo "✅ create_order.php exists<br>";
} else {
    echo "❌ create_order.php NOT FOUND<br>";
    exit;
}

// Test 2: Check database connection
echo "<h2>2. Database Connection Test</h2>";
try {
    $host = 'localhost';
    $dbname = 'sunshine_marketing';
    $username = 'root';
    $password = '';

    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "✅ Database connection successful<br>";
    
    // Check if orders table exists
    $stmt = $pdo->query("SHOW TABLES LIKE 'orders'");
    if ($stmt->rowCount() > 0) {
        echo "✅ Orders table exists<br>";
        
        // Check table structure
        $stmt = $pdo->query("DESCRIBE orders");
        echo "<h3>Orders Table Structure:</h3>";
        echo "<table border='1' style='border-collapse: collapse; width: 100%;'>";
        echo "<tr style='background-color: #f0f0f0;'><th>Field</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th><th>Extra</th></tr>";
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            echo "<tr>";
            echo "<td>{$row['Field']}</td>";
            echo "<td>{$row['Type']}</td>";
            echo "<td>{$row['Null']}</td>";
            echo "<td>{$row['Key']}</td>";
            echo "<td>{$row['Default']}</td>";
            echo "<td>{$row['Extra']}</td>";
            echo "</tr>";
        }
        echo "</table>";
    } else {
        echo "❌ Orders table NOT FOUND<br>";
    }
    
} catch (Exception $e) {
    echo "❌ Database connection failed: " . $e->getMessage() . "<br>";
    exit;
}

// Test 3: Check cart data structure
echo "<h2>3. Cart Data Structure Test</h2>";
try {
    $stmt = $pdo->query("SELECT * FROM cart LIMIT 1");
    $cartItem = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($cartItem) {
        echo "✅ Cart item found<br>";
        echo "<h3>Sample Cart Item:</h3>";
        echo "<pre>" . json_encode($cartItem, JSON_PRETTY_PRINT) . "</pre>";
        
        echo "<h3>Cart Item Keys:</h3>";
        echo "<ul>";
        foreach (array_keys($cartItem) as $key) {
            echo "<li>$key</li>";
        }
        echo "</ul>";
    } else {
        echo "❌ No cart items found<br>";
    }
} catch (Exception $e) {
    echo "❌ Error checking cart: " . $e->getMessage() . "<br>";
}

// Test 4: Simulate the exact request from Flutter
echo "<h2>4. Simulate Flutter Request</h2>";
$testData = [
    'user_id' => 2,
    'cart_items' => [
        [
            'Cart_id' => 5,
            'User_id' => 2,
            'Ecomm_product_id' => 1,
            'Quantity' => 3,
            'Payment_status' => 'Pending',
            'Unique_code' => 'cart_test123',
            'Ecomm_product_name' => 'TestMobile',
            'Ecomm_product_image' => 'test_image.png',
            'Ecomm_product_price' => 12000.00
        ]
    ],
    'total_amount' => 36000,
    'cashfree_order_id' => 'test123',
    'name' => 'Test User',
    'email' => 'test@example.com',
    'phone' => '1234567890',
    'address' => 'Test Address',
    'city' => 'Test City',
    'state' => 'Test State',
    'pincode' => '123456'
];

echo "<h3>Test Data (Exact Flutter Format):</h3>";
echo "<pre>" . json_encode($testData, JSON_PRETTY_PRINT) . "</pre>";

// Test 5: Test create_order.php directly
echo "<h2>5. Test create_order.php Directly</h2>";
echo "Attempting to call create_order.php...<br>";

// Set up the request environment
$_SERVER['REQUEST_METHOD'] = 'POST';
$_SERVER['CONTENT_TYPE'] = 'application/json';
$_SERVER['HTTP_USER_AGENT'] = 'Flutter Test';
$_SERVER['REMOTE_ADDR'] = '127.0.0.1';

// Set the raw input data
$GLOBALS['HTTP_RAW_POST_DATA'] = json_encode($testData);

echo "<h3>Request Environment:</h3>";
echo "<ul>";
echo "<li>Request method: " . $_SERVER['REQUEST_METHOD'] . "</li>";
echo "<li>Content-Type: " . $_SERVER['CONTENT_TYPE'] . "</li>";
echo "<li>User-Agent: " . $_SERVER['HTTP_USER_AGENT'] . "</li>";
echo "<li>Remote address: " . $_SERVER['REMOTE_ADDR'] . "</li>";
echo "</ul>";

echo "<h3>Raw Input Data:</h3>";
echo "<pre>" . $GLOBALS['HTTP_RAW_POST_DATA'] . "</pre>";

// Capture output and errors
ob_start();
$oldErrorReporting = error_reporting(E_ALL);
$oldDisplayErrors = ini_get('display_errors');
ini_set('display_errors', 1);

try {
    echo "<h3>Calling create_order.php...</h3>";
    include 'create_order.php';
    $output = ob_get_clean();
    echo "<h4>✅ Response from create_order.php:</h4>";
    echo "<pre>$output</pre>";
} catch (Exception $e) {
    $output = ob_get_clean();
    echo "<h4>❌ Exception caught:</h4>";
    echo "<p><strong>Error:</strong> " . $e->getMessage() . "</p>";
    echo "<p><strong>File:</strong> " . $e->getFile() . "</p>";
    echo "<p><strong>Line:</strong> " . $e->getLine() . "</p>";
    echo "<h4>Output before exception:</h4>";
    echo "<pre>$output</pre>";
}

// Restore settings
error_reporting($oldErrorReporting);
ini_set('display_errors', $oldDisplayErrors);

echo "<h2>6. Check PHP Error Log</h2>";
echo "<p>Check your PHP error log for detailed debugging information:</p>";
echo "<ul>";
echo "<li>XAMPP: <code>C:\\xampp\\php\\logs\\php_error.log</code></li>";
echo "<li>Apache: <code>C:\\xampp\\apache\\logs\\error.log</code></li>";
echo "</ul>";

echo "<h2>🎯 NEXT STEPS</h2>";
echo "<ol>";
echo "<li>Check the PHP error log for detailed debugging</li>";
echo "<li>Try the checkout in your Flutter app</li>";
echo "<li>Look at the Flutter console for detailed logs</li>";
echo "<li>Compare the logs to see where the issue occurs</li>";
echo "</ol>";
?>
