<?php
// Test script to debug checkout flow
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h2>Checkout Debug Test</h2>";

// Test 1: Check if create_order.php exists
echo "<h3>1. File Check</h3>";
if (file_exists('create_order.php')) {
    echo "✅ create_order.php exists<br>";
} else {
    echo "❌ create_order.php NOT FOUND<br>";
}

// Test 2: Check database connection
echo "<h3>2. Database Connection Test</h3>";
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
        echo "<h4>Orders Table Structure:</h4>";
        echo "<table border='1'><tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th></tr>";
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            echo "<tr><td>{$row['Field']}</td><td>{$row['Type']}</td><td>{$row['Null']}</td><td>{$row['Key']}</td><td>{$row['Default']}</td></tr>";
        }
        echo "</table>";
    } else {
        echo "❌ Orders table NOT FOUND<br>";
    }
    
} catch (Exception $e) {
    echo "❌ Database connection failed: " . $e->getMessage() . "<br>";
}

// Test 3: Simulate the exact request from Flutter
echo "<h3>3. Simulate Flutter Request</h3>";
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

echo "Test data: <pre>" . json_encode($testData, JSON_PRETTY_PRINT) . "</pre>";

// Test 4: Check if we can call create_order.php
echo "<h3>4. Test create_order.php Call</h3>";
if (file_exists('create_order.php')) {
    echo "Attempting to call create_order.php...<br>";
    
    // Simulate the request
    $_SERVER['REQUEST_METHOD'] = 'POST';
    $_SERVER['CONTENT_TYPE'] = 'application/json';
    
    // Set the input data
    $GLOBALS['HTTP_RAW_POST_DATA'] = json_encode($testData);
    
    // Capture output
    ob_start();
    include 'create_order.php';
    $output = ob_get_clean();
    
    echo "Response from create_order.php:<br>";
    echo "<pre>$output</pre>";
} else {
    echo "create_order.php not found<br>";
}
?>
