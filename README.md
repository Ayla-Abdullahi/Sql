E-commerce Store Database
This project provides a complete and well-structured relational database schema for a typical e-commerce platform. The ecommerce_store.sql file contains all the necessary SQL commands to create the database, define the tables, establish relationships, and populate the database with sample data.

Overview
The database is designed to manage core e-commerce entities and their relationships, including:

Users: Customers and administrators.

Products: Items for sale with details like price, inventory, and images.

Orders: Transactions made by users, including shipping details.

Suppliers & Categories: Product sourcing and organization.

Reviews & Payments: User feedback and transaction records.

The schema is built with referential integrity in mind, ensuring data consistency and accuracy across all tables.

Schema Highlights
Logical Structure: The database is organized into normalized tables, each with a single responsibility (e.g., users for user information, products for product details).

Strong Constraints:

Primary & Foreign Keys: Used extensively to define clear relationships between tables.

UNIQUE Constraints: Enforces uniqueness on critical fields like email and sku.

NOT NULL & CHECK: Prevents invalid data from being inserted, such as negative prices or out-of-range ratings.

Efficient Data Types: The use of ENUM for fields like order_status and role restricts values to a predefined set, which is both space-efficient and prevents data entry errors.

Automated Timestamps: Columns like created_at and updated_at automatically record the time of creation and modification, which is a key best practice for auditing and tracking changes.

Many-to-Many Relationships: Correctly modeled using dedicated junction tables (product_categories, order_items).

How to Use
To set up this database and get started, simply follow these steps:

Ensure you have a MySQL server running and have the necessary credentials to connect.

Open your terminal or command prompt.

Navigate to the directory where the ecommerce_store.sql file is located.

Execute the following command, replacing <username> (root) with your MySQL username:

mysql -u <username> -p < ecommerce_store.sql

You will be prompted to enter your password. Once authenticated, the script will automatically create the ecommerce_store database and populate it with all the tables, relationships, and sample data.

| **Table Name**            | **Description**                                   | **Key Relationships**               |
| --------------------------| ------------------------------------------------- | ----------------------------------- |
| **users**                 | Stores customer and administrator information.    | –                                   |
| **addresses**             | Stores user addresses for shipping and billing.   | users (One-to-Many)                 |
| **suppliers**             | Manages information about product suppliers.      | –                                   |
| **categories**            | Organizes products into a hierarchical structure. | Self-referencing (One-to-Many)      |
| **products**              | Main table for all e-commerce products.           | suppliers (One-to-Many)             |
| **product_categories**    | Links products to one or more categories.         | products, categories (Many-to-Many) |
| **product_images**        | Stores image URLs for each product.               | products (One-to-Many)              |
| **inventory**             | Tracks the stock quantity for each product.       | products (One-to-One)               |
| **orders**                | Records placed by users.                          | users, addresses (One-to-Many)      |
| **order_items**           | Details on products within an order.              | orders, products (Many-to-Many)     |
| **payments**              | Records payment transactions for orders.          | orders (One-to-Many)                |
| **reviews**               | Stores user reviews and ratings for products.     | products, users (Many-to-Many)      |
| **product_price_history** | Tracks historical changes in product prices.      | products, users (One-to-Many)       |


