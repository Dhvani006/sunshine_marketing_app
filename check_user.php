<?php
try {
    $pdo = new PDO('mysql:host=localhost;dbname=sunshine_marketing', 'root', '');
    $stmt = $pdo->query('SELECT U_id, Username, Email, Password FROM users WHERE Email = "sejallathigara1008@gmail.com"');
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if($user) {
        echo "User found: {$user['Username']} ({$user['Email']})\n";
        echo "Password hash: {$user['Password']}\n";
        echo "User ID: {$user['U_id']}\n";
    } else {
        echo "User not found\n";
    }
} catch(Exception $e) {
    echo 'Error: ' . $e->getMessage();
}
?>

