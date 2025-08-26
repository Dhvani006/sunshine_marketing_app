<?php
/**
 * Test Script for Checkout URL Construction
 * This will help debug the checkout URL format issue
 */

echo "=== Testing Checkout URL Construction ===\n\n";

// Test different session ID formats
$testSessionIds = [
    'session_normal_123456',
    'session__Xu9YDS8YPoWj8UhDAkxIq7SOy3nasEVvDwnDX17hAKUJ2xeKkdDSQjFtUXkvhl2npyxM12ta97J8Tt4vth0tMAGQCXzMBi4jeq3KQeAt-jFJSz_onD8Kb3r7O0payment',
    'session-with-dashes_123',
    'session.with.dots_123',
    'session+with+plus_123'
];

foreach ($testSessionIds as $sessionId) {
    echo "Original Session ID: $sessionId\n";
    
    // URL encode the session ID
    $encodedSessionId = urlencode($sessionId);
    echo "Encoded Session ID: $encodedSessionId\n";
    
    // Construct checkout URL
    $checkoutUrl = 'https://test.cashfree.com/pg/checkout/' . $encodedSessionId;
    echo "Checkout URL: $checkoutUrl\n";
    
    // Test URL accessibility
    echo "Testing URL accessibility...\n";
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $checkoutUrl);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_NOBODY, true);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    if ($error) {
        echo "❌ cURL Error: $error\n";
    } else {
        echo "HTTP Code: $httpCode\n";
        
        if ($httpCode === 200 || $httpCode === 302) {
            echo "✅ URL accessible\n";
        } elseif ($httpCode === 404) {
            echo "❌ URL not found\n";
        } elseif ($httpCode === 400) {
            echo "⚠️ Bad request - might be invalid session ID\n";
        } else {
            echo "⚠️ Unexpected response: $httpCode\n";
        }
    }
    
    echo "----------------------------------------\n\n";
}

echo "=== Test Complete ===\n";
echo "Note: Some URLs may return errors if the session IDs are not real.\n";
echo "The important thing is to see if the URL encoding fixes the format.\n";
?>
