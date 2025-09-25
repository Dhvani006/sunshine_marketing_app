<?php
// Payment Status Page - Handles Cashfree redirects and shows payment status
header('Content-Type: text/html; charset=UTF-8');
header('Access-Control-Allow-Origin: *');

// Include configuration
$config = require_once 'config.php';
$cashfreeConfig = $config['cashfree'];

// Get parameters from URL
$orderId = $_GET['order_id'] ?? '';
$status = $_GET['status'] ?? '';
$transactionId = $_GET['transaction_id'] ?? '';
$errorMessage = $_GET['error'] ?? '';

// If no order ID, show error
if (empty($orderId)) {
    $errorMessage = 'Order ID is required';
    $showError = true;
} else {
    $showError = false;
    
    try {
        // Connect to database to get order details
        $pdo = new PDO('mysql:host=localhost;dbname=sunshine_marketing', 'root', '');
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        
        // Get order details
        $stmt = $pdo->prepare("SELECT * FROM orders WHERE Order_id = ? OR cashfree_order_id = ?");
        $stmt->execute([$orderId, $orderId]);
        $order = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$order) {
            $errorMessage = $errorMessage ?: 'Order not found';
            $showError = true;
        } else {
            // Get payment details if available
            $stmt = $pdo->prepare("SELECT * FROM payments WHERE Order_id = ?");
            $stmt->execute([$order['Order_id']]);
            $payment = $stmt->fetch(PDO::FETCH_ASSOC);
            
            $orderDetails = $order;
            $paymentDetails = $payment;
        }
        
    } catch (Exception $e) {
        $errorMessage = $errorMessage ?: 'Database error: ' . $e->getMessage();
        $showError = true;
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment Status - Sunshine Marketing</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        
        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            padding: 40px;
            max-width: 500px;
            width: 100%;
            text-align: center;
            animation: slideUp 0.6s ease-out;
        }
        
        @keyframes slideUp {
            from {
                opacity: 0;
                transform: translateY(30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        .status-icon {
            width: 100px;
            height: 100px;
            border-radius: 50%;
            margin: 0 auto 30px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 50px;
            color: white;
        }
        
        .success {
            background: linear-gradient(135deg, #4CAF50, #45a049);
        }
        
        .error {
            background: linear-gradient(135deg, #f44336, #d32f2f);
        }
        
        .pending {
            background: linear-gradient(135deg, #ff9800, #f57c00);
        }
        
        h1 {
            color: #333;
            margin-bottom: 20px;
            font-size: 28px;
        }
        
        .message {
            color: #666;
            font-size: 18px;
            margin-bottom: 30px;
            line-height: 1.5;
        }
        
        .order-details {
            background: #f8f9fa;
            border-radius: 12px;
            padding: 20px;
            margin: 20px 0;
            text-align: left;
        }
        
        .order-details h3 {
            color: #333;
            margin-bottom: 15px;
            font-size: 18px;
        }
        
        .detail-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
            padding: 8px 0;
            border-bottom: 1px solid #eee;
        }
        
        .detail-row:last-child {
            border-bottom: none;
        }
        
        .detail-label {
            font-weight: 600;
            color: #555;
        }
        
        .detail-value {
            color: #333;
        }
        
        .buttons {
            margin-top: 30px;
            display: flex;
            gap: 15px;
            flex-wrap: wrap;
        }
        
        .btn {
            flex: 1;
            padding: 15px 25px;
            border: none;
            border-radius: 10px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            transition: all 0.3s ease;
            min-width: 120px;
        }
        
        .btn-primary {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
        }
        
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(102, 126, 234, 0.3);
        }
        
        .btn-secondary {
            background: #f8f9fa;
            color: #666;
            border: 2px solid #e9ecef;
        }
        
        .btn-secondary:hover {
            background: #e9ecef;
            transform: translateY(-2px);
        }
        
        .deep-link-btn {
            background: linear-gradient(135deg, #4CAF50, #45a049);
            color: white;
            margin-top: 20px;
        }
        
        .deep-link-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(76, 175, 80, 0.3);
        }
        
        .loading {
            display: none;
        }
        
        .spinner {
            border: 3px solid #f3f3f3;
            border-top: 3px solid #667eea;
            border-radius: 50%;
            width: 30px;
            height: 30px;
            animation: spin 1s linear infinite;
            margin: 0 auto 20px;
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        
        @media (max-width: 600px) {
            .container {
                padding: 30px 20px;
            }
            
            .buttons {
                flex-direction: column;
            }
            
            .btn {
                width: 100%;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <?php if ($showError): ?>
            <!-- Error State -->
            <div class="status-icon error">
                <span>✕</span>
            </div>
            <h1>Payment Error</h1>
            <p class="message"><?php echo htmlspecialchars($errorMessage); ?></p>
            <div class="buttons">
                <a href="javascript:history.back()" class="btn btn-secondary">Go Back</a>
                <a href="javascript:window.close()" class="btn btn-primary">Close</a>
            </div>
            
        <?php else: ?>
            <?php
            // Determine status and styling
            $isSuccess = false;
            $isPending = false;
            $isError = false;
            
            if ($paymentDetails && $paymentDetails['Payment_status'] === 'Success') {
                $isSuccess = true;
                $statusText = 'Payment Successful!';
                $messageText = 'Your payment has been processed successfully.';
                $iconClass = 'success';
                $iconSymbol = '✓';
            } elseif ($paymentDetails && $paymentDetails['Payment_status'] === 'Pending') {
                $isPending = true;
                $statusText = 'Payment Pending';
                $messageText = 'Your payment is being processed. Please wait a moment.';
                $iconClass = 'pending';
                $iconSymbol = '⏳';
            } else {
                $isError = true;
                $statusText = 'Payment Failed';
                $messageText = 'There was an issue processing your payment.';
                $iconClass = 'error';
                $iconSymbol = '✕';
            }
            ?>
            
            <!-- Success/Pending/Error State -->
            <div class="status-icon <?php echo $iconClass; ?>">
                <span><?php echo $iconSymbol; ?></span>
            </div>
            <h1><?php echo $statusText; ?></h1>
            <p class="message"><?php echo $messageText; ?></p>
            
            <?php if ($isSuccess): ?>
            <!-- Auto-redirect notification -->
            <div id="autoRedirectNotification" style="display: none; background: #e3f2fd; border: 1px solid #2196f3; border-radius: 8px; padding: 15px; margin: 20px 0; text-align: center;">
                <div style="display: flex; align-items: center; justify-content: center; margin-bottom: 10px;">
                    <div id="countdownCircle" style="width: 40px; height: 40px; border-radius: 50%; background: #2196f3; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 18px; margin-right: 15px;">
                        3
                    </div>
                    <div style="text-align: left;">
                        <div style="font-weight: bold; color: #1976d2;">Returning to App...</div>
                        <div style="font-size: 14px; color: #666;">Automatically redirecting in <span id="countdownText">3</span> seconds</div>
                    </div>
                </div>
                <button onclick="cancelAutoRedirect()" style="background: #ff5722; color: white; border: none; padding: 8px 16px; border-radius: 4px; cursor: pointer; font-size: 14px;">
                    Cancel Auto-Redirect
                </button>
            </div>
            <?php endif; ?>
            
            <!-- Order Details -->
            <div class="order-details">
                <h3>Order Details</h3>
                <div class="detail-row">
                    <span class="detail-label">Order ID:</span>
                    <span class="detail-value"><?php echo htmlspecialchars($orderDetails['Order_id']); ?></span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Amount:</span>
                    <span class="detail-value">₹<?php echo number_format($orderDetails['Total_amount'], 2); ?></span>
                </div>
                <?php if ($paymentDetails): ?>
                <div class="detail-row">
                    <span class="detail-label">Payment Status:</span>
                    <span class="detail-value"><?php echo htmlspecialchars($paymentDetails['Payment_status']); ?></span>
                </div>
                <?php if ($paymentDetails['Transaction_id']): ?>
                <div class="detail-row">
                    <span class="detail-label">Transaction ID:</span>
                    <span class="detail-value"><?php echo htmlspecialchars($paymentDetails['Transaction_id']); ?></span>
                </div>
                <?php endif; ?>
                <?php endif; ?>
                <div class="detail-row">
                    <span class="detail-label">Order Status:</span>
                    <span class="detail-value"><?php echo htmlspecialchars($orderDetails['Order_status']); ?></span>
                </div>
            </div>
            
            <!-- Auto-redirect message -->
            <?php if ($isSuccess): ?>
            <div class="buttons">
                <div style="text-align: center; padding: 20px; background: #e8f5e8; border-radius: 10px; margin: 20px 0;">
                    <div style="font-size: 18px; color: #2e7d32; margin-bottom: 10px;">
                        <strong>Redirecting to App...</strong>
                    </div>
                    <div style="color: #666; font-size: 14px;">
                        You will be automatically redirected to the Sunshine Marketing app
                    </div>
                </div>
            </div>
            <?php elseif ($isPending): ?>
            <div class="buttons">
                <div style="text-align: center; padding: 20px; background: #fff3e0; border-radius: 10px; margin: 20px 0;">
                    <div style="font-size: 18px; color: #f57c00; margin-bottom: 10px;">
                        <strong>Payment Processing...</strong>
                    </div>
                    <div style="color: #666; font-size: 14px;">
                        Please wait while we process your payment
                    </div>
                </div>
            </div>
            <?php else: ?>
            <div class="buttons">
                <div style="text-align: center; padding: 20px; background: #ffebee; border-radius: 10px; margin: 20px 0;">
                    <div style="font-size: 18px; color: #d32f2f; margin-bottom: 10px;">
                        <strong>Payment Issue</strong>
                    </div>
                    <div style="color: #666; font-size: 14px;">
                        There was an issue with your payment. Please try again.
                    </div>
                </div>
            </div>
            <?php endif; ?>
            
            <!-- Manual Instructions Modal -->
            <div id="manualInstructions" style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.8); z-index: 1000; display: flex; align-items: center; justify-content: center;">
                <div style="background: white; padding: 30px; border-radius: 15px; max-width: 400px; margin: 20px; text-align: center;">
                    <h3 style="margin-bottom: 20px; color: #333;">Manual App Opening</h3>
                    <p style="margin-bottom: 15px; color: #666;">If the app didn't open automatically:</p>
                    <ol style="text-align: left; margin-bottom: 20px; color: #555;">
                        <li style="margin-bottom: 10px;">Open the Sunshine Marketing app manually</li>
                        <li style="margin-bottom: 10px;">Your payment has been processed successfully</li>
                        <li style="margin-bottom: 10px;">Order ID: <strong><?php echo htmlspecialchars($orderDetails['Order_id'] ?? ''); ?></strong></li>
                        <li style="margin-bottom: 10px;">Amount: <strong>₹<?php echo number_format($orderDetails['Total_amount'] ?? 0, 2); ?></strong></li>
                    </ol>
                    <button onclick="hideManualInstructions()" class="btn btn-primary" style="width: 100%;">
                        Got It
                    </button>
                </div>
            </div>
            
        <?php endif; ?>
    </div>

    <script>
        // Deep link to app
        function openApp() {
            const orderId = '<?php echo $orderDetails['Order_id'] ?? ''; ?>';
            const status = '<?php echo $isSuccess ? 'SUCCESS' : ($isPending ? 'PENDING' : 'FAILED'); ?>';
            
            // Try to open the app with deep link
            const deepLink = `sunshine_marketing_app://payment_complete?order_id=${orderId}&status=${status}`;
            
            console.log('Attempting to open app with deep link:', deepLink);
            
            // Show user feedback immediately
            const btn = event.target;
            const originalText = btn.innerHTML;
            btn.innerHTML = 'Opening App...';
            btn.disabled = true;
            
            // Try multiple methods to open the app
            let attempts = 0;
            const maxAttempts = 3;
            
            function tryOpenApp() {
                attempts++;
                console.log(`Attempt ${attempts} to open app`);
                
                if (attempts === 1) {
                    // Method 1: Direct window.location
                    try {
                        window.location.href = deepLink;
                    } catch (e) {
                        console.log('Method 1 failed:', e);
                    }
                } else if (attempts === 2) {
                    // Method 2: Create and click link
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
                } else if (attempts === 3) {
                    // Method 3: Iframe method
                    try {
                        const iframe = document.createElement('iframe');
                        iframe.style.display = 'none';
                        iframe.src = deepLink;
                        document.body.appendChild(iframe);
                        
                        setTimeout(() => {
                            if (document.body.contains(iframe)) {
                                document.body.removeChild(iframe);
                            }
                        }, 1000);
                    } catch (e) {
                        console.log('Method 3 failed:', e);
                    }
                }
                
                // If we haven't reached max attempts, try again
                if (attempts < maxAttempts) {
                    setTimeout(tryOpenApp, 500);
                } else {
                    // After all attempts, show message and reset button
                    setTimeout(() => {
                        alert('If the app didn\'t open automatically, please:\n\n1. Make sure the Sunshine Marketing app is installed\n2. Try opening the app manually\n3. The payment has been processed successfully');
                        btn.innerHTML = originalText;
                        btn.disabled = false;
                    }, 2000);
                }
            }
            
            // Start the attempts
            tryOpenApp();
        }
        
        // Check payment status
        function checkStatus() {
            const orderId = '<?php echo $orderId; ?>';
            
            // Show loading
            const btn = event.target;
            const originalText = btn.innerHTML;
            btn.innerHTML = '<div class="spinner"></div>Checking...';
            btn.disabled = true;
            
            // Call the return URL to check status
            fetch(`cashfree_return_url.php?order_id=${orderId}`)
                .then(response => response.json())
                .then(data => {
                    if (data.status === 'SUCCESS' && data.is_paid) {
                        // Payment successful, reload page
                        window.location.reload();
                    } else {
                        // Still pending or failed
                        alert('Payment is still being processed. Please wait a moment and try again.');
                        btn.innerHTML = originalText;
                        btn.disabled = false;
                    }
                })
                .catch(error => {
                    console.error('Error checking status:', error);
                    alert('Error checking payment status. Please try again.');
                    btn.innerHTML = originalText;
                    btn.disabled = false;
                });
        }
        
        // Retry payment
        function retryPayment() {
            if (confirm('Do you want to retry the payment?')) {
                // Redirect to payment page or close and let user retry
                window.close();
            }
        }
        
        // Show manual instructions
        function showManualInstructions() {
            document.getElementById('manualInstructions').style.display = 'flex';
        }
        
        // Hide manual instructions
        function hideManualInstructions() {
            document.getElementById('manualInstructions').style.display = 'none';
        }
        
        // Auto-redirect to app after successful payment
        <?php if ($isSuccess): ?>
        let autoRedirectTimer = null;
        let countdown = 3;
        let autoRedirectActive = true;
        
        function startAutoRedirect() {
            // Show the notification
            const notification = document.getElementById('autoRedirectNotification');
            if (notification) {
                notification.style.display = 'block';
            }
            
            // Update button text
            const btn = document.querySelector('.deep-link-btn');
            if (btn) {
                btn.innerHTML = `Return to App (${countdown})`;
                btn.disabled = true;
            }
            
            autoRedirectTimer = setInterval(() => {
                if (!autoRedirectActive) return;
                
                countdown--;
                
                // Update countdown display
                const countdownCircle = document.getElementById('countdownCircle');
                const countdownText = document.getElementById('countdownText');
                if (countdownCircle) countdownCircle.textContent = countdown;
                if (countdownText) countdownText.textContent = countdown;
                
                // Update button text
                if (btn) {
                    btn.innerHTML = `Return to App (${countdown})`;
                }
                
                if (countdown <= 0) {
                    clearInterval(autoRedirectTimer);
                    openApp();
                }
            }, 1000);
        }
        
        function cancelAutoRedirect() {
            autoRedirectActive = false;
            clearInterval(autoRedirectTimer);
            
            // Hide notification
            const notification = document.getElementById('autoRedirectNotification');
            if (notification) {
                notification.style.display = 'none';
            }
            
            // Reset button
            const btn = document.querySelector('.deep-link-btn');
            if (btn) {
                btn.innerHTML = 'Return to App';
                btn.disabled = false;
            }
        }
        
        // Start auto-redirect after 2 seconds
        setTimeout(() => {
            startAutoRedirect();
        }, 2000);
        <?php endif; ?>
        
        // Auto-check status if pending
        <?php if ($isPending): ?>
        setTimeout(() => {
            checkStatus();
        }, 5000); // Check after 5 seconds
        <?php endif; ?>
    </script>
</body>
</html>
