-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Aug 24, 2025 at 11:34 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `sunshine_marketing`
--

-- --------------------------------------------------------

--
-- Table structure for table `cart`
--

CREATE TABLE `cart` (
  `Cart_id` int(11) NOT NULL,
  `User_id` int(11) NOT NULL,
  `Ecomm_product_id` int(11) NOT NULL,
  `Quantity` int(11) DEFAULT 1,
  `Payment_status` enum('Pending','Paid','Failed') DEFAULT 'Pending',
  `Unique_code` varchar(100) NOT NULL DEFAULT uuid()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `cart`
--

INSERT INTO `cart` (`Cart_id`, `User_id`, `Ecomm_product_id`, `Quantity`, `Payment_status`, `Unique_code`) VALUES
(3, 3, 1, 1, 'Pending', 'cart_689bce6105269'),
(4, 4, 1, 9, 'Pending', 'cart_689edd8583e7e'),
(5, 2, 1, 3, 'Pending', 'cart_68aad12231e38');

-- --------------------------------------------------------

--
-- Table structure for table `ecomm_product`
--

CREATE TABLE `ecomm_product` (
  `Ecomm_product_id` int(11) NOT NULL,
  `Ecomm_product_name` varchar(255) NOT NULL,
  `Ecomm_product_image` varchar(255) DEFAULT NULL,
  `ecomm_product_description` text DEFAULT NULL,
  `Ecomm_product_price` decimal(10,2) NOT NULL,
  `Ecomm_product_stock` int(11) DEFAULT 0,
  `Ecomm_created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `Master_cat_id` int(11) DEFAULT NULL,
  `Sub_cat_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `ecomm_product`
--

INSERT INTO `ecomm_product` (`Ecomm_product_id`, `Ecomm_product_name`, `Ecomm_product_image`, `ecomm_product_description`, `Ecomm_product_price`, `Ecomm_product_stock`, `Ecomm_created_at`, `Master_cat_id`, `Sub_cat_id`) VALUES
(1, 'TestMobile', 'http://localhost:8000/uploads/products/689836b283d56_1754805938.png', 'Test Description', 12000.00, 15, '2025-08-10 06:05:40', 1, 1);

-- --------------------------------------------------------

--
-- Table structure for table `ecomm_product_images`
--

CREATE TABLE `ecomm_product_images` (
  `Image_id` int(11) NOT NULL,
  `Ecomm_product_id` int(11) NOT NULL,
  `Image_path` varchar(255) NOT NULL,
  `Is_primary` tinyint(1) DEFAULT 0,
  `Created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `ecomm_product_images`
--

INSERT INTO `ecomm_product_images` (`Image_id`, `Ecomm_product_id`, `Image_path`, `Is_primary`, `Created_at`) VALUES
(1, 1, 'http://localhost:8000/uploads/products/689836b283d56_1754805938.png', 1, '2025-08-10 06:05:40'),
(2, 1, 'http://localhost:8000/uploads/products/689836b286b76_1754805938.png', 0, '2025-08-10 06:05:40'),
(3, 1, 'http://localhost:8000/uploads/products/689836b28a142_1754805938.png', 0, '2025-08-10 06:05:40'),
(4, 1, 'http://localhost:8000/uploads/products/689836b28ad6e_1754805938.png', 0, '2025-08-10 06:05:40');

-- --------------------------------------------------------

--
-- Table structure for table `email_verifications`
--

CREATE TABLE `email_verifications` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `token` varchar(64) NOT NULL,
  `expires_at` datetime NOT NULL,
  `used` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `master_category`
--

CREATE TABLE `master_category` (
  `Master_cat_id` int(11) NOT NULL,
  `Master_cat_name` varchar(100) NOT NULL,
  `Master_cat_image` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `master_category`
--

INSERT INTO `master_category` (`Master_cat_id`, `Master_cat_name`, `Master_cat_image`) VALUES
(1, 'Electronics', 'http://localhost:8000/uploads/categories/6898312016f27_1754804512.png');

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `Order_id` int(11) NOT NULL,
  `User_id` int(11) NOT NULL,
  `Ecomm_product_id` int(11) NOT NULL,
  `Quantity` int(11) NOT NULL DEFAULT 1,
  `Total_amount` decimal(10,2) NOT NULL,
  `Order_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `Order_status` enum('Processing','Shipped','Delivered','Cancelled') DEFAULT 'Processing',
  `Payment_id` varchar(255) DEFAULT NULL,
  `cashfree_order_id` varchar(255) DEFAULT NULL,
  `address` varchar(255) NOT NULL,
  `city` varchar(100) NOT NULL,
  `state` varchar(100) NOT NULL,
  `pincode` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`Order_id`, `User_id`, `Ecomm_product_id`, `Quantity`, `Total_amount`, `Order_date`, `Order_status`, `Payment_id`, `address`, `city`, `state`, `pincode`) VALUES
(1, 2, 1, 1, 14160.00, '2025-08-12 18:52:39', '', NULL, '', '', '', ''),
(2, 2, 1, 1, 14160.00, '2025-08-12 19:40:31', '', NULL, '', '', '', ''),
(3, 2, 1, 1, 14160.00, '2025-08-12 19:43:20', '', NULL, '', '', '', ''),
(4, 2, 1, 1, 14160.00, '2025-08-12 19:43:48', '', NULL, '', '', '', ''),
(5, 3, 1, 1, 14160.00, '2025-08-12 19:59:43', '', NULL, '', '', '', ''),
(6, 4, 1, 5, 70800.00, '2025-08-15 04:06:54', '', NULL, '', '', '', ''),
(7, 4, 1, 1, 14160.00, '2025-08-15 04:18:03', '', NULL, '', '', '', ''),
(8, 4, 1, 7, 99120.00, '2025-08-15 04:19:58', '', NULL, '', '', '', ''),
(9, 4, 1, 1, 14160.00, '2025-08-15 04:39:40', '', NULL, '', '', '', ''),
(10, 4, 1, 8, 113280.00, '2025-08-15 04:39:51', '', NULL, '', '', '', ''),
(11, 4, 1, 9, 127440.00, '2025-08-15 04:51:53', '', NULL, '', '', '', ''),
(12, 4, 1, 4, 56640.00, '2025-08-15 04:55:51', '', NULL, '', '', '', ''),
(13, 2, 1, 3, 42480.00, '2025-08-24 05:15:47', '', NULL, '', '', '', ''),
(14, 2, 1, 3, 42480.00, '2025-08-24 05:19:18', '', NULL, '', '', '', ''),
(15, 2, 1, 1, 14160.00, '2025-08-24 05:22:53', '', NULL, '', '', '', '');

-- --------------------------------------------------------

--
-- Table structure for table `otp_verifications`
--

CREATE TABLE `otp_verifications` (
  `id` int(11) NOT NULL,
  `email` varchar(100) NOT NULL,
  `otp` varchar(6) NOT NULL,
  `type` enum('registration','login') NOT NULL,
  `expires_at` datetime NOT NULL,
  `used` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `otp_verifications`
--

INSERT INTO `otp_verifications` (`id`, `email`, `otp`, `type`, `expires_at`, `used`, `created_at`) VALUES
(1, 'sunshinemarketing53@gmail.com', '720273', 'registration', '2025-08-10 11:02:16', 1, '2025-08-10 05:27:16'),
(2, 'sejallathigara1008@gmail.com', '274984', 'registration', '2025-08-13 03:55:59', 1, '2025-08-12 22:20:59'),
(3, 'd24dce133@charusat.edu.in', '763015', 'registration', '2025-08-13 05:03:06', 1, '2025-08-12 23:28:06'),
(5, 'amitlathigara44@gmail.com', '009148', 'registration', '2025-08-15 12:40:56', 1, '2025-08-15 07:05:56');

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `Payment_id` int(11) NOT NULL,
  `User_id` int(11) NOT NULL,
  `Order_id` int(11) DEFAULT NULL,
  `Payment_method` enum('Credit Card','Debit Card','UPI','Net Banking','Wallet') NOT NULL,
  `Amount` decimal(10,2) NOT NULL,
  `Payment_status` enum('Success','Failed','Pending') DEFAULT 'Pending',
  `Transaction_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `Transaction_id` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `shipping_details`
--

CREATE TABLE `shipping_details` (
  `Shipping_id` int(11) NOT NULL,
  `Order_id` int(11) NOT NULL,
  `Shipping_address` text NOT NULL,
  `City` varchar(100) DEFAULT NULL,
  `State` varchar(100) DEFAULT NULL,
  `Pincode` varchar(10) DEFAULT NULL,
  `Country` varchar(100) DEFAULT 'India',
  `Shipping_status` enum('Not Shipped','In Transit','Out for Delivery','Delivered') DEFAULT 'Not Shipped',
  `Tracking_number` varchar(100) DEFAULT NULL,
  `Estimated_delivery_date` date DEFAULT NULL,
  `Delivered_on` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sub_category`
--

CREATE TABLE `sub_category` (
  `Sub_cat_id` int(11) NOT NULL,
  `Master_cat_id` int(11) NOT NULL,
  `Sub_cat_name` varchar(100) NOT NULL,
  `Sub_cat_image` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `sub_category`
--

INSERT INTO `sub_category` (`Sub_cat_id`, `Master_cat_id`, `Sub_cat_name`, `Sub_cat_image`) VALUES
(1, 1, 'Mobile Phone', 'http://localhost:8000/uploads/subcategories/68983643ab46c_1754805827.png');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `U_id` int(11) NOT NULL,
  `Username` varchar(100) NOT NULL,
  `Email` varchar(100) NOT NULL,
  `Password` varchar(255) NOT NULL,
  `Address` text DEFAULT NULL,
  `Phone_number` varchar(15) DEFAULT NULL,
  `Role` enum('admin','seller','buyer') DEFAULT 'buyer',
  `email_verified` tinyint(1) DEFAULT 0,
  `status` enum('active','blocked','suspended') DEFAULT 'active',
  `token` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `last_login` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`U_id`, `Username`, `Email`, `Password`, `Address`, `Phone_number`, `Role`, `email_verified`, `status`, `token`, `created_at`, `updated_at`, `last_login`) VALUES
(1, 'admin', 'sunshinemarketing53@gmail.com', '$2y$12$A2z7GEifRE3sOpaVhw2G6.wyDGtyIWpC0JCV0Ce7zvEM9cd./a3M.', 'Ahmedabad', '8128086742', 'admin', 1, 'active', '757cf41bd5ee4cd9f16f43fa266bf5bbeae8c6b30ac7b8e12201af2f4b1adde0', '2025-08-10 05:34:12', '2025-08-11 13:12:34', '2025-08-11 13:12:34'),
(2, 'sejal', 'sejallathigara1008@gmail.com', '$2y$10$TE9HW6nZwX/PDhxNspJz7e37qAYYVuwYQi1/ONWMA1O7.E/jxVe2u', 'sbjdc', '1234456789', 'buyer', 1, 'active', NULL, '2025-08-12 22:22:21', '2025-08-24 08:45:01', '2025-08-24 08:45:01'),
(3, 'sejall', 'd24dce133@charusat.edu.in', '$2y$10$laaA2boSuOE.EAnpxyqmp.uw/vbMnkVB7uhNdV7t3L4/nO6W4Ph3.', 'dd ', '7894561230', 'buyer', 1, 'active', NULL, '2025-08-12 23:29:16', '2025-08-12 23:30:06', '2025-08-12 23:30:06'),
(4, 'amitlathigara', 'amitlathigara44@gmail.com', '$2y$10$K2UTgqOrDDSQhVpBYeIYDO7YG9Ne8JbUGD8QVYRAoSDWJu1CHloGO', 'sm sk', '1478529630', 'buyer', 1, 'active', NULL, '2025-08-15 07:07:18', '2025-08-15 08:23:58', '2025-08-15 08:23:58');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `cart`
--
ALTER TABLE `cart`
  ADD PRIMARY KEY (`Cart_id`),
  ADD UNIQUE KEY `Unique_code` (`Unique_code`),
  ADD KEY `User_id` (`User_id`),
  ADD KEY `Ecomm_product_id` (`Ecomm_product_id`);

--
-- Indexes for table `ecomm_product`
--
ALTER TABLE `ecomm_product`
  ADD PRIMARY KEY (`Ecomm_product_id`),
  ADD KEY `Master_cat_id` (`Master_cat_id`),
  ADD KEY `Sub_cat_id` (`Sub_cat_id`);

--
-- Indexes for table `ecomm_product_images`
--
ALTER TABLE `ecomm_product_images`
  ADD PRIMARY KEY (`Image_id`),
  ADD KEY `Ecomm_product_id` (`Ecomm_product_id`);

--
-- Indexes for table `email_verifications`
--
ALTER TABLE `email_verifications`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `token` (`token`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `idx_token` (`token`),
  ADD KEY `idx_expires_at` (`expires_at`);

--
-- Indexes for table `master_category`
--
ALTER TABLE `master_category`
  ADD PRIMARY KEY (`Master_cat_id`),
  ADD UNIQUE KEY `Master_cat_name` (`Master_cat_name`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`Order_id`),
  ADD KEY `User_id` (`User_id`),
  ADD KEY `Ecomm_product_id` (`Ecomm_product_id`);

--
-- Indexes for table `otp_verifications`
--
ALTER TABLE `otp_verifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_email_type` (`email`,`type`),
  ADD KEY `idx_expires_at` (`expires_at`),
  ADD KEY `idx_used` (`used`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`Payment_id`),
  ADD UNIQUE KEY `Transaction_id` (`Transaction_id`),
  ADD KEY `User_id` (`User_id`),
  ADD KEY `Order_id` (`Order_id`);

--
-- Indexes for table `shipping_details`
--
ALTER TABLE `shipping_details`
  ADD PRIMARY KEY (`Shipping_id`),
  ADD KEY `Order_id` (`Order_id`);

--
-- Indexes for table `sub_category`
--
ALTER TABLE `sub_category`
  ADD PRIMARY KEY (`Sub_cat_id`),
  ADD KEY `Master_cat_id` (`Master_cat_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`U_id`),
  ADD UNIQUE KEY `Email` (`Email`),
  ADD UNIQUE KEY `Phone_number` (`Phone_number`),
  ADD KEY `idx_email` (`Email`),
  ADD KEY `idx_phone` (`Phone_number`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_role` (`Role`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `cart`
--
ALTER TABLE `cart`
  MODIFY `Cart_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `ecomm_product`
--
ALTER TABLE `ecomm_product`
  MODIFY `Ecomm_product_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `ecomm_product_images`
--
ALTER TABLE `ecomm_product_images`
  MODIFY `Image_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `email_verifications`
--
ALTER TABLE `email_verifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `master_category`
--
ALTER TABLE `master_category`
  MODIFY `Master_cat_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `Order_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `otp_verifications`
--
ALTER TABLE `otp_verifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `Payment_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `shipping_details`
--
ALTER TABLE `shipping_details`
  MODIFY `Shipping_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `sub_category`
--
ALTER TABLE `sub_category`
  MODIFY `Sub_cat_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `U_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `cart`
--
ALTER TABLE `cart`
  ADD CONSTRAINT `cart_ibfk_1` FOREIGN KEY (`User_id`) REFERENCES `users` (`U_id`),
  ADD CONSTRAINT `cart_ibfk_2` FOREIGN KEY (`Ecomm_product_id`) REFERENCES `ecomm_product` (`Ecomm_product_id`);

--
-- Constraints for table `ecomm_product`
--
ALTER TABLE `ecomm_product`
  ADD CONSTRAINT `ecomm_product_ibfk_1` FOREIGN KEY (`Master_cat_id`) REFERENCES `master_category` (`Master_cat_id`),
  ADD CONSTRAINT `ecomm_product_ibfk_2` FOREIGN KEY (`Sub_cat_id`) REFERENCES `sub_category` (`Sub_cat_id`);

--
-- Constraints for table `ecomm_product_images`
--
ALTER TABLE `ecomm_product_images`
  ADD CONSTRAINT `ecomm_product_images_ibfk_1` FOREIGN KEY (`Ecomm_product_id`) REFERENCES `ecomm_product` (`Ecomm_product_id`) ON DELETE CASCADE;

--
-- Constraints for table `email_verifications`
--
ALTER TABLE `email_verifications`
  ADD CONSTRAINT `email_verifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`U_id`) ON DELETE CASCADE;

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`User_id`) REFERENCES `users` (`U_id`),
  ADD CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`Ecomm_product_id`) REFERENCES `ecomm_product` (`Ecomm_product_id`);

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`User_id`) REFERENCES `users` (`U_id`),
  ADD CONSTRAINT `payments_ibfk_2` FOREIGN KEY (`Order_id`) REFERENCES `orders` (`Order_id`);

--
-- Constraints for table `shipping_details`
--
ALTER TABLE `shipping_details`
  ADD CONSTRAINT `shipping_details_ibfk_1` FOREIGN KEY (`Order_id`) REFERENCES `orders` (`Order_id`);

--
-- Constraints for table `sub_category`
--
ALTER TABLE `sub_category`
  ADD CONSTRAINT `sub_category_ibfk_1` FOREIGN KEY (`Master_cat_id`) REFERENCES `master_category` (`Master_cat_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
