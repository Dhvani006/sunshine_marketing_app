<?php
// Test database structure
header('Content-Type: text/plain');

try {
    // Database connection
    $host = 'localhost';
    $dbname = 'sunshine_marketing';
    $username = 'root';
    $password = '';

    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    echo "=== DATABASE CONNECTION TEST ===\n";
    echo "✅ Connected to database: $dbname\n\n";

    // Check payments table structure
    echo "=== PAYMENTS TABLE STRUCTURE ===\n";
    $stmt = $pdo->query("DESCRIBE payments");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    foreach ($columns as $column) {
        echo "Column: {$column['Field']} - Type: {$column['Type']} - Null: {$column['Null']}\n";
    }

    // Check if Cashfree columns exist
    echo "\n=== CHECKING CASHFREE COLUMNS ===\n";
    $cashfreeColumns = ['Cashfree_order_id', 'Cashfree_payment_status', 'Cashfree_response'];
    
    foreach ($cashfreeColumns as $col) {
        $stmt = $pdo->prepare("SHOW COLUMNS FROM payments LIKE ?");
        $stmt->execute([$col]);
        $exists = $stmt->fetch();
        
        if ($exists) {
            echo "✅ Column '$col' exists\n";
        } else {
            echo "❌ Column '$col' MISSING\n";
        }
    }

    // Show sample data
    echo "\n=== SAMPLE PAYMENTS DATA ===\n";
    $stmt = $pdo->query("SELECT * FROM payments LIMIT 3");
    $payments = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (empty($payments)) {
        echo "No payments found in table\n";
    } else {
        foreach ($payments as $payment) {
            echo "Payment ID: {$payment['Payment_id']} - Order ID: {$payment['Order_id']} - Status: {$payment['Payment_status']}\n";
        }
    }

} catch (Exception $e) {
    echo "❌ ERROR: " . $e->getMessage() . "\n";
}
?>
