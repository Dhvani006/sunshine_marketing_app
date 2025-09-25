<?php
// Test script for login.php
$testData = [
    'email' => 'sejallathigara1008@gmail.com',
    'password' => 'password123' // This might not be the correct password, but let's test the endpoint
];

// Simulate POST request
$_SERVER['REQUEST_METHOD'] = 'POST';
$_SERVER['CONTENT_TYPE'] = 'application/json';

// Mock the input stream
$input = json_encode($testData);

// Capture output
ob_start();
include 'login.php';
$output = ob_get_clean();

echo "Login test result:\n";
echo $output . "\n";
?>

