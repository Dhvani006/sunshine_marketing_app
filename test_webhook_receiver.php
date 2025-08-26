<?php
// Simple webhook test receiver
header('Content-Type: text/plain');

echo "=== WEBHOOK TEST RECEIVER ===\n";
echo "Time: " . date('Y-m-d H:i:s') . "\n";
echo "Method: " . $_SERVER['REQUEST_METHOD'] . "\n";
echo "Content-Type: " . ($_SERVER['CONTENT_TYPE'] ?? 'Not set') . "\n\n";

// Get raw input
$rawInput = file_get_contents('php://input');
echo "Raw Input:\n";
echo $rawInput . "\n\n";

// Get headers
echo "Headers:\n";
foreach (getallheaders() as $name => $value) {
    echo "$name: $value\n";
}
echo "\n";

// Get query parameters
echo "Query Parameters:\n";
foreach ($_GET as $key => $value) {
    echo "$key: $value\n";
}
echo "\n";

// Get POST data
echo "POST Data:\n";
foreach ($_POST as $key => $value) {
    echo "$key: $value\n";
}
echo "\n";

// Try to decode JSON
if (!empty($rawInput)) {
    echo "JSON Decode Attempt:\n";
    $jsonData = json_decode($rawInput, true);
    if ($jsonData === null) {
        echo "JSON Error: " . json_last_error_msg() . "\n";
    } else {
        echo "JSON Decoded Successfully:\n";
        print_r($jsonData);
    }
}

echo "\n=== END WEBHOOK TEST ===\n";
?>
