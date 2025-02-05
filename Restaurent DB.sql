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