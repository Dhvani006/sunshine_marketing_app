<?php
// Test login with different passwords
$testPasswords = ['password123', '123456', 'password', 'sejal123', 'test123'];

foreach($testPasswords as $password) {
    $hash = '$2y$10$TE9HW6nZwX/PDhxNspJz7e37qAYYVuwYQi1/ONWMA1O7.E/jxVe2u';
    if(password_verify($password, $hash)) {
        echo "Password found: $password\n";
        break;
    }
}

// If none work, let's test the login endpoint with a simple password
echo "Testing login endpoint...\n";

$testData = [
    'email' => 'sejallathigara1008@gmail.com',
    'password' => 'password123'
];

// Simulate POST request
$_SERVER['REQUEST_METHOD'] = 'POST';
$_SERVER['CONTENT_TYPE'] = 'application/json';

// Mock the input stream by creating a temporary file
$tempFile = tempnam(sys_get_temp_dir(), 'login_test');
file_put_contents($tempFile, json_encode($testData));

// Redirect php://input to our temp file
$originalInput = 'php://input';
$GLOBALS['test_input'] = $tempFile;

// Override file_get_contents for php://input
function mock_file_get_contents($filename) {
    if ($filename === 'php://input') {
        return file_get_contents($GLOBALS['test_input']);
    }
    return file_get_contents($filename);
}

// Capture output
ob_start();
include 'login.php';
$output = ob_get_clean();

echo "Login test result:\n";
echo $output . "\n";

// Cleanup
unlink($tempFile);
?>

