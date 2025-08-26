<?php
// Direct test of cashfree_order.php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>🧪 DIRECT CASHFREE ORDER TEST</h1>";

// Test 1: Check if cashfree_order.php exists
echo "<h2>1. File Check</h2>";
if (file_exists('cashfree_order.php')) {
    echo "✅ cashfree_order.php exists<br>";
} else {
    echo "❌ cashfree_order.php NOT FOUND<br>";
    exit;
}

// Test 2: Check if cashfree_config.php exists
echo "<h2>2. Config Check</h2>";
if (file_exists('cashfree_config.php')) {
    echo "✅ cashfree_config.php exists<br>";
    
    // Include config and show values
    require_once 'cashfree_config.php';
    echo "Environment: " . getCashfreeEnvironment() . "<br>";
    echo "Base URL: " . getCashfreeBaseUrl() . "<br>";
    echo "Client ID: " . getCashfreeClientId() . "<br>";
    echo "Client Secret: " . substr(getCashfreeClientSecret(), 0, 20) . "...<br>";
} else {
    echo "❌ cashfree_config.php NOT FOUND<br>";
    exit;
}

// Test 3: Simulate the exact request from Flutter
echo "<h2>3. Simulate Flutter Request</h2>";
$testData = [
    'order_amount' => '269040.0',
    'order_currency' => 'INR',
    'customer_details' => [
        'customer_id' => 'customer_test123',
        'customer_name' => 'Test User',
        'customer_email' => 'test@example.com',
        'customer_phone' => '1234567890'
    ],
    'order_note' => 'Order from Sunshine Marketing App'
];

echo "<h3>Test Data (Exact Flutter Format):</h3>";
echo "<pre>" . json_encode($testData, JSON_PRETTY_PRINT) . "</pre>";

// Test 4: Test cashfree_order.php directly
echo "<h2>4. Test cashfree_order.php Directly</h2>";
echo "Attempting to call cashfree_order.php...<br>";

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
    echo "<h3>Calling cashfree_order.php...</h3>";
    include 'cashfree_order.php';
    $output = ob_get_clean();
    echo "<h4>✅ Response from cashfree_order.php:</h4>";
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

echo "<h2>5. Check PHP Error Log</h2>";
echo "<p>Check your PHP error log for detailed debugging information:</p>";
echo "<ul>";
echo "<li>XAMPP: <code>C:\\xampp\\php\\logs\\php_error.log</code></li>";
echo "<li>Apache: <code>C:\\xampp\\apache\\logs\\error.log</code></li>";
echo "</ul>";

echo "<h2>🎯 NEXT STEPS</h2>";
echo "<ol>";
echo "<li>Check the PHP error log for detailed debugging</li>";
echo "<li>Try the checkout in your Flutter app again</li>";
echo "<li>Look at the Flutter console for the new detailed logs</li>";
echo "<li>Compare both logs to see where the issue occurs</li>";
echo "</ol>";
?>
