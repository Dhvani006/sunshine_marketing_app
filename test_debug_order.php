<?php
// Debug file to see what data is received
header('Content-Type: text/plain');
header('Access-Control-Allow-Origin: *');

echo "=== DEBUG ORDER DATA ===\n";
echo "Request Method: " . $_SERVER['REQUEST_METHOD'] . "\n";
echo "Content Type: " . ($_SERVER['CONTENT_TYPE'] ?? 'Not set') . "\n";
echo "Raw Input Length: " . strlen(file_get_contents('php://input')) . " bytes\n";

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $rawInput = file_get_contents('php://input');
    echo "Raw Input: $rawInput\n\n";
    
    $data = json_decode($rawInput, true);
    if ($data) {
        echo "Parsed JSON:\n";
        echo json_encode($data, JSON_PRETTY_PRINT) . "\n";
        
        echo "\nField Check:\n";
        echo "order_amount: " . ($data['order_amount'] ?? 'MISSING') . " (type: " . gettype($data['order_amount'] ?? null) . ")\n";
        echo "order_currency: " . ($data['order_currency'] ?? 'MISSING') . "\n";
        echo "customer_details: " . (isset($data['customer_details']) ? 'EXISTS' : 'MISSING') . "\n";
        
        if (isset($data['customer_details'])) {
            $cd = $data['customer_details'];
            echo "  - customer_id: " . ($cd['customer_id'] ?? 'MISSING') . "\n";
            echo "  - customer_name: " . ($cd['customer_name'] ?? 'MISSING') . "\n";
            echo "  - customer_phone: " . ($cd['customer_phone'] ?? 'MISSING') . "\n";
            echo "  - customer_email: " . ($cd['customer_email'] ?? 'MISSING') . "\n";
        }
        
        echo "order_note: " . ($data['order_note'] ?? 'MISSING') . "\n";
    } else {
        echo "Failed to parse JSON\n";
        echo "JSON Error: " . json_last_error_msg() . "\n";
    }
} else {
    echo "Not a POST request\n";
}
?>

