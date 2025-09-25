<?php
/**
 * Local Cashfree Configuration
 * Add your actual Cashfree credentials here
 */

return [
    'cashfree' => [
        // TODO: Replace with your actual Cashfree credentials from dashboard
        'client_id' => 'CF_CLIENT_ID_TEST', // Replace with your actual client ID
        'client_secret' => 'CF_CLIENT_SECRET_TEST', // Replace with your actual client secret
        'environment' => 'sandbox' // Change to 'production' for live environment
    ],
    'server' => [
        'base_url' => 'http://192.168.27.5/sunshine_marketing_app_backend',
        'ngrok_url' => 'https://b81a71185ea7.ngrok-free.app/sunshine_marketing_app_backend'
    ]
];
