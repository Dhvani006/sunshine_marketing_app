<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Include configuration file
$config = require_once 'config.php';

// Extract Cashfree configuration
$cashfreeConfig = $config['cashfree'];
$clientId = $cashfreeConfig['client_id'];
$clientSecret = $cashfreeConfig['client_secret'];
$environment = $cashfreeConfig['environment'];

// Validate configuration
if (empty($clientId) || empty($clientSecret)) {
    echo json_encode([
        'status' => 'ERROR',
        'message' => 'Cashfree API configuration not set. Please configure your API credentials.'
    ]);
    exit();
}

// Get order ID from query parameter
$orderId = $_GET['order_id'] ?? '';

if (empty($orderId)) {
    echo json_encode([
        'status' => 'ERROR',
        'message' => 'Order ID is required'
    ]);
    exit();
}

// Log the return URL access
error_log("Cashfree Return URL accessed - Order ID: $orderId");

try {
    // Step 1: Verify the payment status with Cashfree
    $cfEnvironment = $environment;
    $cfClientId = $clientId;
    $cfClientSecret = $clientSecret;
    
    $baseUrl = $cfEnvironment === 'production' ? 'https://api.cashfree.com' : 'https://sandbox.cashfree.com';
    
    // Call Cashfree API to verify order status
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $baseUrl . '/pg/orders/' . $orderId);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'x-client-id: ' . $cfClientId,
        'x-client-secret: ' . $cfClientSecret,
        'x-api-version: 2023-08-01'
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    if ($error) {
        throw new Exception('cURL Error: ' . $error);
    }
    
    if ($httpCode !== 200) {
        error_log("Cashfree API error response: " . $response);
        throw new Exception('Cashfree API returned error: ' . $httpCode . ' - ' . $response);
    }
    
    $orderData = json_decode($response, true);
    if (!$orderData) {
        error_log("Failed to decode Cashfree response: " . $response);
        throw new Exception('Invalid JSON response from Cashfree API');
    }
    
    error_log("Cashfree order data: " . json_encode($orderData));
    
    // Step 2: Check if payment was successful
    $isPaid = false;
    $paymentStatus = 'unknown';
    $transactionId = null;
    $paymentMethod = 'UPI'; // Default
    
    error_log("Analyzing Cashfree order data: " . json_encode($orderData));
    
    // Check for successful payment indicators
    if (isset($orderData['order_status'])) {
        $orderStatus = $orderData['order_status'];
        error_log("Order status from Cashfree: $orderStatus");
        
        // Check for different success indicators
        if ($orderStatus === 'PAID' || $orderStatus === 'SUCCESS') {
            $isPaid = true;
            $paymentStatus = 'SUCCESS';
            // Use cf_order_id as transaction ID since cf_payment_id is not available
            $transactionId = $orderData['cf_order_id'] ?? $orderData['cf_payment_id'] ?? $orderData['payment_id'] ?? null;
            $paymentMethod = $orderData['payment_method'] ?? 'UPI';
            error_log("Payment successful based on order status: $orderStatus, Transaction ID: $transactionId");
        } elseif ($orderStatus === 'ACTIVE') {
            $paymentStatus = 'PENDING';
            error_log("Payment pending for order: $orderId");
        } elseif ($orderStatus === 'EXPIRED' || $orderStatus === 'CANCELLED') {
            $paymentStatus = 'FAILED';
            error_log("Payment failed for order: $orderId, Status: $orderStatus");
        }
    }
    
    // Fallback check for cf_payment_id (in case it exists in some responses)
    if (!$isPaid && isset($orderData['cf_payment_id']) && !empty($orderData['cf_payment_id'])) {
        $isPaid = true;
        $paymentStatus = 'SUCCESS';
        $transactionId = $orderData['cf_payment_id'];
        $paymentMethod = $orderData['payment_method'] ?? 'UPI';
        error_log("Payment successful - Transaction ID: $transactionId, Method: $paymentMethod");
    }
    
    // Additional check for payment details
    if (isset($orderData['payment_details']) && is_array($orderData['payment_details'])) {
        $paymentDetails = $orderData['payment_details'];
        if (isset($paymentDetails['cf_payment_id']) && !empty($paymentDetails['cf_payment_id'])) {
            $isPaid = true;
            $paymentStatus = 'SUCCESS';
            $transactionId = $paymentDetails['cf_payment_id'];
            $paymentMethod = $paymentDetails['payment_method'] ?? 'UPI';
            error_log("Payment successful from payment_details - Transaction ID: $transactionId");
        }
    }
    
    // Step 3: Find the local order in your database
    $pdo = new PDO('mysql:host=localhost;dbname=sunshine_marketing', 'root', '');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $stmt = $pdo->prepare("SELECT Order_id, User_id, Total_amount FROM orders WHERE cashfree_order_id = ?");
    $stmt->execute([$orderId]);
    $localOrder = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$localOrder) {
        throw new Exception('Local order not found for Cashfree order: ' . $orderId);
    }
    
    $localOrderId = $localOrder['Order_id'];
    $userId = $localOrder['User_id'];
    $amount = $localOrder['Total_amount'];
    
    error_log("Found local order: ID=$localOrderId, User=$userId, Amount=$amount");
    
    // Step 4: If payment was successful, save payment details
    if ($isPaid) {
        // Check if payment already exists
        $stmt = $pdo->prepare("SELECT Payment_id FROM payments WHERE Order_id = ?");
        $stmt->execute([$localOrderId]);
        $existingPayment = $stmt->fetch();
        
        if (!$existingPayment) {
            // Insert payment record with Cashfree data
            error_log("Inserting payment record - Transaction ID: $transactionId, Method: $paymentMethod, Amount: $amount");
            
            $stmt = $pdo->prepare("
                INSERT INTO payments (User_id, Order_id, Payment_method, Amount, Payment_status, Transaction_id, Cashfree_order_id, Cashfree_payment_status, Created_at, Updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
            ");
            $stmt->execute([$userId, $localOrderId, $paymentMethod, $amount, 'Success', $transactionId, $orderId, 'SUCCESS']);
            
            $paymentId = $pdo->lastInsertId();
            error_log("Payment record created: ID=$paymentId, Transaction ID=$transactionId");
            
            // Update order with payment ID and status
            $stmt = $pdo->prepare("UPDATE orders SET Payment_id = ?, payment_status = 'Success', Order_status = 'confirmed' WHERE Order_id = ?");
            $stmt->execute([$paymentId, $localOrderId]);
            
            error_log("Order updated with payment ID: $paymentId");
        } else {
            error_log("Payment already exists for order: $localOrderId");
            
            // Update existing payment record with transaction ID if it's missing
            if (empty($existingPayment['Transaction_id']) && !empty($transactionId)) {
                $stmt = $pdo->prepare("UPDATE payments SET Transaction_id = ?, Cashfree_payment_status = 'SUCCESS' WHERE Order_id = ?");
                $stmt->execute([$transactionId, $localOrderId]);
                error_log("Updated existing payment record with Transaction ID: $transactionId");
            }
        }
    }
    
    // Step 5: Create a proper redirect page that handles deep links
    $deepLink = 'sunshine_marketing_app://payment_complete?order_id=' . $localOrderId . '&status=' . $paymentStatus;
    if ($transactionId) {
        $deepLink .= '&transaction_id=' . $transactionId;
    }
    
    // Create HTML page that handles the deep link properly
    // Set proper headers for HTML content
    header('Content-Type: text/html; charset=UTF-8');
    ?>
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Redirecting to App...</title>
        <style>
            body { 
                font-family: Arial, sans-serif; 
                text-align: center; 
                padding: 50px; 
                background: #f5f5f5; 
            }
            .container { 
                background: white; 
                padding: 30px; 
                border-radius: 10px; 
                box-shadow: 0 2px 10px rgba(0,0,0,0.1); 
                max-width: 400px; 
                margin: 0 auto; 
            }
            .spinner { 
                border: 3px solid #f3f3f3; 
                border-top: 3px solid #3498db; 
                border-radius: 50%; 
                width: 40px; 
                height: 40px; 
                animation: spin 1s linear infinite; 
                margin: 20px auto; 
            }
            @keyframes spin { 
                0% { transform: rotate(0deg); } 
                100% { transform: rotate(360deg); } 
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h2>Payment Processed Successfully!</h2>
            <div class="spinner"></div>
            <p>Redirecting to Sunshine Marketing app...</p>
            <p><small>If the app doesn't open automatically, please open it manually.</small></p>
        </div>
        
        <script>
            // Try multiple methods to open the app
            const deepLink = '<?php echo $deepLink; ?>';
            console.log('Attempting to open app with:', deepLink);
            
            // Method 1: Direct redirect
            setTimeout(() => {
                try {
                    window.location.href = deepLink;
                } catch (e) {
                    console.log('Method 1 failed:', e);
                }
            }, 1000);
            
            // Method 2: Create link and click
            setTimeout(() => {
                try {
                    const link = document.createElement('a');
                    link.href = deepLink;
                    link.style.display = 'none';
                    document.body.appendChild(link);
                    link.click();
                    document.body.removeChild(link);
                } catch (e) {
                    console.log('Method 2 failed:', e);
                }
            }, 1500);
            
            // Method 3: Iframe method
            setTimeout(() => {
                try {
                    const iframe = document.createElement('iframe');
                    iframe.style.display = 'none';
                    iframe.src = deepLink;
                    document.body.appendChild(iframe);
                    setTimeout(() => {
                        if (document.body.contains(iframe)) {
                            document.body.removeChild(iframe);
                        }
                    }, 2000);
                } catch (e) {
                    console.log('Method 3 failed:', e);
                }
            }, 2000);
            
            // Show message after attempts
            setTimeout(() => {
                document.querySelector('.container').innerHTML = `
                    <h2>Payment Complete!</h2>
                    <p>✅ Your payment has been processed successfully.</p>
                    <p><strong>Order ID:</strong> <?php echo $localOrderId; ?></p>
                    <p><strong>Status:</strong> <?php echo $paymentStatus; ?></p>
                    <p>Please open the Sunshine Marketing app to view your order details.</p>
                `;
            }, 5000);
        </script>
    </body>
    </html>
    <?php
    exit();
    
} catch (Exception $e) {
    error_log("Error in return URL handler: " . $e->getMessage());
    
    // Create error page instead of redirecting
    // Set proper headers for HTML content
    header('Content-Type: text/html; charset=UTF-8');
    ?>
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Payment Error</title>
        <style>
            body { 
                font-family: Arial, sans-serif; 
                text-align: center; 
                padding: 50px; 
                background: #f5f5f5; 
            }
            .container { 
                background: white; 
                padding: 30px; 
                border-radius: 10px; 
                box-shadow: 0 2px 10px rgba(0,0,0,0.1); 
                max-width: 400px; 
                margin: 0 auto; 
            }
            .error { 
                color: #d32f2f; 
                font-size: 48px; 
                margin-bottom: 20px; 
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="error">⚠️</div>
            <h2>Payment Processing Error</h2>
            <p>There was an issue processing your payment.</p>
            <p><strong>Error:</strong> <?php echo htmlspecialchars($e->getMessage()); ?></p>
            <p>Please try again or contact support if the issue persists.</p>
        </div>
    </body>
    </html>
    <?php
    exit();
}
?>
