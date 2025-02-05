-- Step 1: Create Database
CREATE DATABASE restaurant_db;
USE restaurant_db;

-- Step 2: Create Tables

-- Customers Table
CREATE TABLE Customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15) UNIQUE NOT NULL,
    address TEXT
);

-- Restaurants Table
CREATE TABLE Restaurants (
    restaurant_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(255) NOT NULL,
    contact VARCHAR(15),
    rating DECIMAL(2,1) CHECK (rating >= 0 AND rating <= 5)
);

-- Menu Table
CREATE TABLE Menu (
    menu_id INT AUTO_INCREMENT PRIMARY KEY,
    restaurant_id INT,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (restaurant_id) REFERENCES Restaurants(restaurant_id) ON DELETE CASCADE
);

-- Orders Table
CREATE TABLE Orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    restaurant_id INT,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('Pending', 'Completed', 'Cancelled') DEFAULT 'Pending',
    total_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id) ON DELETE CASCADE,
    FOREIGN KEY (restaurant_id) REFERENCES Restaurants(restaurant_id) ON DELETE CASCADE
);

-- Order Items Table
CREATE TABLE Order_Items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    menu_id INT,
    quantity INT NOT NULL CHECK (quantity > 0),
    subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (menu_id) REFERENCES Menu(menu_id) ON DELETE CASCADE
);

-- Payments Table
CREATE TABLE Payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    payment_method ENUM('Credit Card', 'Debit Card', 'Cash', 'UPI') NOT NULL,
    status ENUM('Pending', 'Completed', 'Failed') DEFAULT 'Pending',
    amount DECIMAL(10,2) NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE
);

-- Delivery Table
CREATE TABLE Deliveries (
    delivery_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    driver_id INT,
    delivery_status ENUM('Out for Delivery', 'Delivered', 'Cancelled') DEFAULT 'Out for Delivery',
    delivery_time TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE
);

-- Drivers Table
CREATE TABLE Drivers (
    driver_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) UNIQUE NOT NULL,
    vehicle_number VARCHAR(50) UNIQUE NOT NULL,
    availability ENUM('Available', 'Unavailable') DEFAULT 'Available'
);
SHOW TABLES;

-- Step 3: Insert Sample Data

-- Insert into Customers
INSERT INTO Customers (name, email, phone, address) VALUES
('Alice Johnson', 'alice@example.com', '1234567890', '123 Main St'),
('Bob Smith', 'bob@example.com', '0987654321', '456 Elm St');

-- Insert into Restaurants
INSERT INTO Restaurants (name, location, contact, rating) VALUES
('Tasty Bites', 'Downtown', '555-1234', 4.5),
('Spicy Corner', 'Uptown', '555-5678', 4.2);

-- Insert into Menu
INSERT INTO Menu (restaurant_id, name, description, price) VALUES
(1, 'Burger', 'Delicious beef burger', 5.99),
(1, 'Pizza', 'Cheese burst pizza', 8.99),
(2, 'Pasta', 'Creamy Alfredo pasta', 7.50);

-- Insert into Orders
INSERT INTO Orders (customer_id, restaurant_id, total_price) VALUES
(1, 1, 14.98),
(2, 2, 7.50);

-- Insert into Order_Items
INSERT INTO Order_Items (order_id, menu_id, quantity, subtotal) VALUES
(1, 1, 2, 11.98),
(1, 2, 1, 8.99),
(2, 3, 1, 7.50);

-- Insert into Payments
INSERT INTO Payments (order_id, payment_method, status, amount) VALUES
(1, 'Credit Card', 'Completed', 14.98),
(2, 'Cash', 'Pending', 7.50);

-- Insert into Drivers
INSERT INTO Drivers (name, phone, vehicle_number, availability) VALUES
('John Doe', '2223334444', 'XYZ-1234', 'Available'),
('Jane Roe', '5556667777', 'ABC-5678', 'Unavailable');

-- Insert into Deliveries
INSERT INTO Deliveries (order_id, driver_id, delivery_status, delivery_time) VALUES
(1, 1, 'Delivered', '2025-02-01 15:00:00'),
(2, 2, 'Out for Delivery', NULL);

-- Step 4: Stored Procedures & Triggers

-- Stored Procedure to Insert New Order
DELIMITER //
CREATE PROCEDURE InsertNewOrder(
    IN cust_id INT, 
    IN rest_id INT, 
    IN total DECIMAL(10,2)
)
BEGIN
    -- Insert new order
    INSERT INTO Orders (customer_id, restaurant_id, total_price) 
    VALUES (cust_id, rest_id, total);

    -- Get the last inserted order_id
    SET @new_order_id = LAST_INSERT_ID();

    -- Assign a driver (assuming first available driver)
    SET @driver_id = (SELECT driver_id FROM Drivers WHERE availability = 'Available' LIMIT 1);

    -- Insert into Deliveries table
    IF @driver_id IS NOT NULL THEN
        INSERT INTO Deliveries (order_id, driver_id, delivery_status, delivery_time) 
        VALUES (@new_order_id, @driver_id, 'Out for Delivery', NULL);
    END IF;
END //
DELIMITER ;


-- Trigger to Prevent Orders from Customers with Unpaid Bills
DELIMITER //
CREATE TRIGGER PreventUnpaidOrders
BEFORE INSERT ON Orders
FOR EACH ROW
BEGIN
    DECLARE unpaid_count INT;
    SELECT COUNT(*) INTO unpaid_count FROM Payments WHERE customer_id = NEW.customer_id AND status = 'Pending';
    IF unpaid_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer has unpaid bills';
    END IF;
END //
DELIMITER ;

-- Trigger to Auto-Update Stock on Order
DELIMITER //
CREATE TRIGGER UpdateStockOnOrder
AFTER INSERT ON Order_Items
FOR EACH ROW
BEGIN
    UPDATE Menu SET stock = stock - NEW.quantity WHERE menu_id = NEW.menu_id;
END //
DELIMITER ;

-- Stored Procedure to Get Restaurant Revenue
DELIMITER //
CREATE PROCEDURE GetRestaurantRevenue(IN rest_id INT)
BEGIN
    SELECT SUM(total_price) AS total_revenue FROM Orders WHERE restaurant_id = rest_id;
END //
DELIMITER ;

-- checking this procedures works or not
-- checking stored procedure 
-- Check if the Procedure Exists
SHOW PROCEDURE STATUS WHERE Db = 'restaurant_db';
-- Call the Procedure to Test It
CALL InsertNewOrder(1, 1, 20.50);
--  Verify the Insertion
SELECT * FROM Orders ORDER BY order_id DESC;
SELECT * FROM Deliveries ORDER BY delivery_id DESC;

-- Checking Triggers For the PreventUnpaidOrders trigger:If they have an unpaid bill, you should get an error message:
-- "Customer has unpaid bills".
INSERT INTO Orders (customer_id, restaurant_id, total_price) VALUES (2, 1, 15.00);

-- For UpdateStockOnOrder trigger:
SELECT * FROM Menu WHERE menu_id = 1;
-- Insert an order item:
INSERT INTO Order_Items (order_id, menu_id, quantity, subtotal) VALUES (1, 1, 2, 11.98);
SELECT * FROM Menu WHERE menu_id = 1;

DROP PROCEDURE IF EXISTS InsertNewOrder;
DROP PROCEDURE IF EXISTS GetRestaurantRevenue;
SHOW TRIGGERS WHERE `Table` = 'Orders';
DROP TRIGGER IF EXISTS PreventUnpaidOrders;
DROP TRIGGER IF EXISTS UpdateStockOnOrder;

-- Step next: Running Queries & Performance Optimization


-- Step 5: Running Queries

-- Retrieve all customers
SELECT * FROM Customers;
SELECT * FROM drivers;
SELECT * FROM deliveries;
SELECT * FROM menu;
SELECT * FROM order_items;
SELECT * FROM orders;
SELECT * FROM payments;
SELECT * FROM restaurants;

-- Get all orders with customer details
SELECT Orders.order_id, Customers.name, Orders.total_price, Orders.status
FROM Orders
JOIN Customers ON Orders.customer_id = Customers.customer_id;

-- Find all menu items from a specific restaurant
SELECT name, price FROM Menu WHERE restaurant_id = 1;

-- Retrieve all completed payments
SELECT * FROM Payments WHERE status = 'Completed';

-- Check delivery status for an order
SELECT Orders.order_id, 
       COALESCE(Deliveries.delivery_status, 'Not Assigned') AS delivery_status
FROM Orders
LEFT JOIN Deliveries ON Orders.order_id = Deliveries.order_id;

-- Find available drivers
SELECT * FROM Drivers WHERE availability = 'Available';

-- Step 6: Advanced Queries & Performance Optimization

-- Find total orders and revenue per restaurant
SELECT Restaurants.name, COUNT(Orders.order_id) AS total_orders, SUM(Orders.total_price) AS total_revenue
FROM Orders
JOIN Restaurants ON Orders.restaurant_id = Restaurants.restaurant_id
GROUP BY Restaurants.name;

-- Get the most popular menu item

SELECT Menu.name, COUNT(Order_Items.menu_id) AS times_ordered
FROM Order_Items
JOIN Menu ON Order_Items.menu_id = Menu.menu_id
GROUP BY Menu.name
ORDER BY times_ordered DESC
LIMIT 1;

-- List customers who spent more than $50

SELECT Customers.name, SUM(Orders.total_price) AS total_spent
FROM Orders
FORCE INDEX (idx_customer_id)
JOIN Customers ON Orders.customer_id = Customers.customer_id
GROUP BY Customers.name
HAVING total_spent > 50;

SHOW INDEXES FROM Orders;

-- Create Indexes for faster lookups
CREATE INDEX idx_customer_id ON Orders(customer_id);
CREATE INDEX idx_restaurant_id ON Menu(restaurant_id);

-- Optimize Joins by Using EXPLAIN
EXPLAIN SELECT * FROM Orders JOIN Customers ON Orders.customer_id = Customers.customer_id;
