-- Add cashfree_order_id column to orders table
-- Run this in your phpMyAdmin or MySQL command line

USE sunshine_marketing;

-- Add the new column
ALTER TABLE `orders` 
ADD COLUMN `cashfree_order_id` VARCHAR(255) DEFAULT NULL 
AFTER `Payment_id`;

-- Verify the column was added
DESCRIBE orders;

-- Show sample data with new column
SELECT Order_id, User_id, Total_amount, cashfree_order_id, address, city, state, pincode 
FROM orders 
LIMIT 5;



