<?php
/**
 * Validate Session ID Format
 * Check if the session ID contains invalid characters
 */

echo "=== Session ID Validation ===\n\n";

// The problematic session ID from your logs
$problematicSessionId = 'session__Xu9YDS8YPoWj8UhDAkxIq7SOy3nasEVvDwnDX17hAKUJ2xeKkdDSQjFtUXkvhl2npyxM12ta97J8Tt4vth0tMAGQCXzMBi4jeq3KQeAt-jFJSz_onD8Kb3r7O0payment';

echo "Problematic Session ID: $problematicSessionId\n";
echo "Length: " . strlen($problematicSessionId) . " characters\n\n";

// Check for problematic characters
echo "Character Analysis:\n";
$charCount = [];
for ($i = 0; $i < strlen($problematicSessionId); $i++) {
    $char = $problematicSessionId[$i];
    if (!isset($charCount[$char])) {
        $charCount[$char] = 0;
    }
    $charCount[$char]++;
}

// Sort by frequency
arsort($charCount);

foreach ($charCount as $char => $count) {
    $ascii = ord($char);
    $isAlphanumeric = ctype_alnum($char);
    $isValid = preg_match('/^[a-zA-Z0-9_-]$/', $char);
    
    echo "Character: '$char' (ASCII: $ascii) - Count: $count - ";
    echo "Alphanumeric: " . ($isAlphanumeric ? 'Yes' : 'No') . " - ";
    echo "Valid for URL: " . ($isValid ? 'Yes' : 'No') . "\n";
}

echo "\n=== URL Encoding Test ===\n";
$encoded = urlencode($problematicSessionId);
echo "Original: $problematicSessionId\n";
echo "Encoded: $encoded\n";
echo "Length difference: " . (strlen($encoded) - strlen($problematicSessionId)) . " characters\n";

echo "\n=== Checkout URL Test ===\n";
$checkoutUrl = 'https://test.cashfree.com/pg/checkout/' . $encoded;
echo "Checkout URL: $checkoutUrl\n";

// Test if the URL is valid
if (filter_var($checkoutUrl, FILTER_VALIDATE_URL)) {
    echo "✅ URL format is valid\n";
} else {
    echo "❌ URL format is invalid\n";
}

echo "\n=== Recommendations ===\n";
echo "1. Check if the session ID from Cashfree is correct\n";
echo "2. Ensure the session ID doesn't contain invalid characters\n";
echo "3. Try creating a new order to get a fresh session ID\n";
echo "4. Verify the Cashfree API response format\n";

echo "\n=== Test Complete ===\n";
?>
