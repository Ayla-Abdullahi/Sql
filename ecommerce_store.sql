DROP DATABASE IF EXISTS ecommerce_store; -- deletes the database if it already exists
CREATE DATABASE ecommerce_store CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
USE ecommerce_store;
-- Character set =utf8mb4 = supports emojis and all language

CREATE TABLE users (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(80) NOT NULL,
  last_name VARCHAR(80) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  phone VARCHAR(30),
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('customer','admin') NOT NULL DEFAULT 'customer',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;
-- the role Enum part restricts the user to either customer or admin
-- TIMESTAMP DEFAULT CURRENT_TIMESTAMP → automatically saves the date & time the record was created or updated.


-- ADDRESSES (one user can have many addresses)

DROP TABLE IF EXISTS addresses;
CREATE TABLE addresses (
  address_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  label VARCHAR(50), -- e.g., 'home', 'work'
  street VARCHAR(255) NOT NULL,
  city VARCHAR(100) NOT NULL,
  state VARCHAR(100),
  postal_code VARCHAR(20),
  country VARCHAR(100) NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;
-- ON DELETE CASCADE means that if a user is deleted, all their addresses are automatically deleted too.


-- SUPPLIERS

DROP TABLE IF EXISTS suppliers;
CREATE TABLE suppliers (
  supplier_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  contact_email VARCHAR(255),
  contact_phone VARCHAR(50),
  address TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- CATEGORIES

DROP TABLE IF EXISTS categories;
CREATE TABLE categories (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL UNIQUE,
  description TEXT,
  parent_id INT DEFAULT NULL, -- for hierarchical categories
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (parent_id) REFERENCES categories(category_id) ON DELETE SET NULL
) ENGINE=InnoDB;
-- the parent_id allows nested catergories


-- PRODUCTS

DROP TABLE IF EXISTS products;
CREATE TABLE products (
  product_id INT AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(64) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(12,2) NOT NULL CHECK (price >= 0),
  cost_price DECIMAL(12,2) DEFAULT NULL CHECK (cost_price >= 0),
  supplier_id INT DEFAULT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id) ON DELETE SET NULL
) ENGINE=InnoDB;
-- sku is a stock keeping unit (unique product code).
-- Each product can optionally link to a supplier.
-- ON DELETE SET NULL → if a supplier is deleted, products stay but with no supplier.

-- PRODUCT <-> CATEGORY (many-to-many)

DROP TABLE IF EXISTS product_categories;
CREATE TABLE product_categories (
  product_id INT NOT NULL,
  category_id INT NOT NULL,
  PRIMARY KEY (product_id, category_id),
  FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- PRODUCT IMAGES

DROP TABLE IF EXISTS product_images;
CREATE TABLE product_images (
  image_id INT AUTO_INCREMENT PRIMARY KEY,
  product_id INT NOT NULL,
  image_url VARCHAR(1024) NOT NULL,
  alt_text VARCHAR(255),
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- INVENTORY (stock tracking)

DROP TABLE IF EXISTS inventory;
CREATE TABLE inventory (
  inventory_id INT AUTO_INCREMENT PRIMARY KEY,
  product_id INT NOT NULL,
  quantity INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  warehouse_location VARCHAR(255),
  last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
  UNIQUE (product_id)
) ENGINE=InnoDB;

-- ORDERS

DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
  order_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  shipping_address_id INT NOT NULL,
  billing_address_id INT DEFAULT NULL,
  order_status ENUM('pending','processing','shipped','delivered','cancelled','returned') NOT NULL DEFAULT 'pending',
  subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
  shipping_fee DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (shipping_fee >= 0),
  tax DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (tax >= 0),
  total DECIMAL(12,2) NOT NULL CHECK (total >= 0),
  placed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE RESTRICT,
  FOREIGN KEY (shipping_address_id) REFERENCES addresses(address_id) ON DELETE RESTRICT,
  FOREIGN KEY (billing_address_id) REFERENCES addresses(address_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ORDER ITEMS (many-to-many with extra attributes)

DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
  order_id BIGINT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(12,2) NOT NULL CHECK (unit_price >= 0), -- price at time of order
  discount DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (discount >= 0),
  PRIMARY KEY (order_id, product_id),
  FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- PAYMENTS

DROP TABLE IF EXISTS payments;
CREATE TABLE payments (
  payment_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT NOT NULL,
  payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  payment_method ENUM('card','mpesa','paypal','bank_transfer') NOT NULL,
  status ENUM('pending','completed','failed','refunded') NOT NULL DEFAULT 'pending',
  amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
  transaction_reference VARCHAR(255) UNIQUE,
  paid_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
) ENGINE=InnoDB;


-- PRODUCT REVIEWS
DROP TABLE IF EXISTS reviews;
CREATE TABLE reviews (
  review_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  product_id INT NOT NULL,
  user_id INT NOT NULL,
  rating TINYINT NOT NULL CHECK (rating >=1 AND rating <=5),
  title VARCHAR(255),
  body TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  UNIQUE (product_id, user_id) -- one review per user per product
) ENGINE=InnoDB;


-- SIMPLE AUDIT: product_price_history (optional)
-- tracks historical price changes

DROP TABLE IF EXISTS product_price_history;
CREATE TABLE product_price_history (
  history_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  product_id INT NOT NULL,
  old_price DECIMAL(12,2) NOT NULL,
  new_price DECIMAL(12,2) NOT NULL,
  changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  changed_by INT, -- user/admin who changed price
  FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
  FOREIGN KEY (changed_by) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;


-- Index suggestions (common query patterns)

CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_inventory_product ON inventory(product_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);

-- Insertion commands


-- USERS (10 customers + 2 admins)

INSERT INTO users (first_name, last_name, email, phone, password_hash, role)
VALUES
('Wiltord', 'Ichingwa', 'wiltord@example.com', '0711111111', 'passhash1', 'customer'),
('Shalom', 'Wambui', 'shalom@example.com', '0711111112', 'passhash2', 'customer'),
('Kelvin', 'Gethurware', 'kelvin@example.com', '0711111113', 'passhash3', 'customer'),
('Kigoro', 'Njoroge', 'kigoro@example.com', '0711111114', 'passhash4', 'customer'),
('Sammy', 'Kibet', 'sammy@example.com', '0711111115', 'passhash5', 'customer'),
('Abdullahi', 'Hassan', 'abdullahi@example.com', '0711111116', 'passhash6', 'customer'),
('Simon', 'Mutua', 'simon@example.com', '0711111117', 'passhash7', 'customer'),
('Linda', 'Chebet', 'linda@example.com', '0711111118', 'passhash8', 'customer'),
('Peter', 'Otieno', 'peter@example.com', '0711111119', 'passhash9', 'customer'),
('Fatma', 'Ahmed', 'fatma@example.com', '0711111120', 'passhash10', 'customer');

-- Admins
INSERT INTO users (first_name, last_name, email, phone, password_hash, role)
VALUES
('Ayla', 'Abdullahi', 'ayla.admin@example.com', '0722222221', 'adminpass1', 'admin'),
('Usman', 'Ali', 'usman.admin@example.com', '0722222222', 'adminpass2', 'admin');


-- SUPPLIERS (3 suppliers)

INSERT INTO suppliers (name, contact_email, contact_phone, address)
VALUES
('TechWorld Ltd', 'info@techworld.com', '0711111131', 'Nairobi, Kenya'),
('HomeStyle Supplies', 'contact@homestyle.com', '0722222242', 'Mombasa, Kenya'),
('Fashion Hub', 'support@fashionhub.com', '0733333353', 'Kisumu, Kenya');


-- CATEGORIES (5 categories)

INSERT INTO categories (name, description)
VALUES
('Electronics', 'Phones, laptops, and gadgets'),
('Home Appliances', 'Appliances for home use'),
('Fashion', 'Clothing and accessories'),
('Books', 'Educational and entertainment books'),
('Sports', 'Sporting goods and equipment');


-- PRODUCTS (5 per category = 25 total)

-- Electronics
INSERT INTO products (sku, name, description, price, supplier_id) VALUES
('ELEC001', 'Samsung Galaxy S23', 'Smartphone with AMOLED display', 10950.00, 1),
('ELEC002', 'iPhone 14', 'Apple smartphone with iOS', 111200.00, 1),
('ELEC003', 'Dell XPS 13', 'Lightweight laptop', 21500.00, 1),
('ELEC004', 'HP Pavilion', 'Budget-friendly laptop', 900.00, 1),
('ELEC005', 'Sony WH-1000XM4', 'Noise cancelling headphones', 350.00, 1);

-- Home Appliances
INSERT INTO products (sku, name, description, price, supplier_id) VALUES
('HOME001', 'Samsung Refrigerator', 'Double-door fridge', 800.00, 2),
('HOME002', 'LG Washing Machine', 'Front load washing machine', 700.00, 2),
('HOME003', 'Philips Blender', 'Kitchen blender', 120.00, 2),
('HOME004', 'Ramtons Microwave', '20L microwave oven', 180.00, 2),
('HOME005', 'Electric Kettle', '1.7L stainless steel kettle', 50.00, 2);

-- Fashion
INSERT INTO products (sku, name, description, price, supplier_id) VALUES
('FASH001', 'Men T-Shirt', 'Cotton T-shirt', 20.00, 3),
('FASH002', 'Women Dress', 'Casual dress', 35.00, 3),
('FASH003', 'Sneakers', 'Running shoes', 70.00, 3),
('FASH004', 'Leather Jacket', 'Black leather jacket', 150.00, 3),
('FASH005', 'Cap', 'Adjustable baseball cap', 15.00, 3);

-- Books
INSERT INTO products (sku, name, description, price, supplier_id) VALUES
('BOOK001', 'Data Structures in C', 'Programming book', 25.00, NULL),
('BOOK002', 'Think Python', 'Beginner Python book', 30.00, NULL),
('BOOK003', 'Rich Dad Poor Dad', 'Finance and personal growth', 18.00, NULL),
('BOOK004', 'Atomic Habits', 'Self improvement book', 22.00, NULL),
('BOOK005', 'The Alchemist', 'Fiction novel', 15.00, NULL);

-- Sports
INSERT INTO products (sku, name, description, price, supplier_id) VALUES
('SPORT001', 'Football', 'Standard size 5 ball', 25.00, 2),
('SPORT002', 'Tennis Racket', 'Professional racket', 80.00, 2),
('SPORT003', 'Yoga Mat', 'Non-slip mat', 20.00, 2),
('SPORT004', 'Dumbbell Set', 'Adjustable dumbbells', 120.00, 2),
('SPORT005', 'Cycling Helmet', 'Safety helmet', 45.00, 2);


-- PRODUCT CATEGORIES MAPPING

INSERT INTO product_categories (product_id, category_id) VALUES
-- Electronics
(1,1),(2,1),(3,1),(4,1),(5,1),
-- Home Appliances
(6,2),(7,2),(8,2),(9,2),(10,2),
-- Fashion
(11,3),(12,3),(13,3),(14,3),(15,3),
-- Books
(16,4),(17,4),(18,4),(19,4),(20,4),
-- Sports
(21,5),(22,5),(23,5),(24,5),(25,5);

-- INVENTORY

INSERT INTO inventory (product_id, quantity) VALUES
(1, 50),(2, 40),(3, 30),(4, 25),(5, 60),
(6, 15),(7, 20),(8, 50),(9, 35),(10, 70),
(11, 100),(12, 60),(13, 45),(14, 20),(15, 150),
(16, 200),(17, 180),(18, 170),(19, 160),(20, 190),
(21, 80),(22, 25),(23, 90),(24, 30),(25, 40);
-- Addresses for all the users 
INSERT INTO addresses (user_id, street, city, country, postal_code)
VALUES
(1, 'Moi Avenue', 'Nairobi', 'Kenya', '00100'),
(2, 'Tom Mboya Street', 'Nairobi', 'Kenya', '00100'),
(3, 'Mama Ngina Drive', 'Mombasa', 'Kenya', '80100'),
(4, 'Kenyatta Avenue', 'Nakuru', 'Kenya', '20100'),
(5, 'Eldoret Road', 'Eldoret', 'Kenya', '30100'),
(6, 'Kisumu Central', 'Kisumu', 'Kenya', '40100'),
(7, 'Thika Superhighway', 'Thika', 'Kenya', '10200'),
(8, 'Nyeri Town', 'Nyeri', 'Kenya', '10100'),
(9, 'Machakos Road', 'Machakos', 'Kenya', '90100'),
(10, 'Kericho Street', 'Kericho', 'Kenya', '20200');

-- order items
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES
-- Order 1: Ayla bought iPhone 14
(1, 2, 1, 111200.00),

-- Order 2: Wiltord bought Samsung Galaxy S23
(2, 1, 1, 10950.00),

-- Order 3: Shalom bought Philips Blender
(3, 8, 1, 120.00),
(3, 10, 1, 60.00),  -- Suppose discounted combo

-- Order 4: Kelvin bought Sneakers
(4, 13, 1, 70.00),

-- Order 5: Kigoro bought Women Dress
(5, 12, 1, 35.00);

-- forgot to insert a certain column

-- orders insertion
INSERT INTO orders 
(user_id, shipping_address_id, billing_address_id, order_status, subtotal, shipping_fee, tax, total, placed_at) 
VALUES
(1, 1, 1, 'delivered', 1100.00, 50.00, 50.00, 1200.00, '2025-08-30 12:10:00'),
(2, 2, 2, 'pending', 900.00, 30.00, 20.00, 950.00, '2025-08-31 15:20:00'),
(3, 3, 3, 'shipped', 160.00, 10.00, 10.00, 180.00, '2025-09-01 10:30:00'),
(4, 4, 4, 'processing', 60.00, 5.00, 5.00, 70.00, '2025-09-02 09:45:00'),
(5, 5, 5, 'delivered', 30.00, 3.00, 2.00, 35.00, '2025-09-03 14:00:00');


-- payments linked to orders
INSERT INTO payments (order_id, payment_method, status, amount, transaction_reference, paid_at, payment_date)
VALUES
(1, 'mpesa', 'completed', 1200.00, 'TXN12345', '2025-09-01 10:05:00', '2025-09-01 10:05:00'),
(2, 'card', 'pending', 950.00, 'TXN12346', '2025-09-02 15:40:00', '2025-09-02 15:40:00'),
(3, 'mpesa', 'completed', 180.00, 'TXN12347', '2025-09-03 11:50:00', '2025-09-03 11:50:00'),
(4, 'bank_transfer', 'completed', 70.00, 'TXN12348', '2025-09-04 09:25:00', '2025-09-04 09:25:00'),
(5, 'paypal', 'completed', 35.00, 'TXN12349', '2025-09-05 14:15:00', '2025-09-05 14:15:00');

-- product images insertion


INSERT INTO product_images (product_id, image_url, alt_text, is_primary)
VALUES
(1, 'https://www.theverge.com/21250695/best-laptops','laptop', TRUE),
(2, 'https://pixabay.com/images/search/phone/','phone back view', TRUE),
(3, 'https://www.ifixit.com/Guide/Samsung+Galaxy+S24+Ultra+Back+Cover+Replacement/175691', FALSE),
(8, 'https://www.cubavera.com/products/ombre-embroidery-panel-shirt-white-cuwsf020ds-112', 'Casual Shirt', TRUE),
(13, 'https://images.unsplash.com/photo-1541963463532-d68292c34b19?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8Ym9va3xlbnwwfHwwfHx8MA%3D%3D', 'Bestseller Book', TRUE);

INSERT INTO reviews (product_id, user_id, rating, title, body, created_at)
VALUES
(1, 2, 5, 'Excellent Laptop', 'This laptop is super fast and lightweight, perfect for work and gaming.', NOW()),
(3, 5, 4, 'Good Phone but...', 'Great display and camera, but the battery drains quickly.', NOW() - INTERVAL 2 DAY),
(5, 4, 3, 'Average Headphones', 'Sound quality is decent but uncomfortable for long use.', NOW() - INTERVAL 5 DAY),
(7, 3, 5, 'Amazing Shoes', 'Fit perfectly and the design is stylish, highly recommended!', NOW() - INTERVAL 1 WEEK),
(2, 6, 2, 'Disappointing TV', 'The screen resolution is not as advertised and the sound is poor.', NOW() - INTERVAL 10 DAY);

INSERT INTO product_price_history (product_id, old_price, new_price, changed_at, changed_by)
VALUES
(1, 950.00, 899.00, NOW() - INTERVAL 15 DAY, 1),
(3, 520.00, 499.00, NOW() - INTERVAL 10 DAY, 2),
(5, 75.00, 70.00, NOW() - INTERVAL 7 DAY, 3),
(7, 120.00, 110.00, NOW() - INTERVAL 20 DAY, 1),
(2, 1500.00, 1400.00, NOW() - INTERVAL 30 DAY, 4);


Select * from order_items;
