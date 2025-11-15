-- Bad SQL file for testing SQLFluff

SELECT * FROM users WHERE id=1;

select a,b,c from table1 where name='test'

-- Missing semicolon
SELECT COUNT(*) FROM orders

-- Inconsistent capitalization
Select product_id, Product_Name FROM Products where status = 'active';

-- Too many columns in one line
SELECT id, name, email, phone, address, city, state, zip, country, created_at, updated_at, deleted_at FROM customers WHERE active = 1;

