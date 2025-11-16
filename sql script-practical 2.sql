-=practical 2

-- BrightLight Data Analytics - SQL JOIN Practice
-- CUSTOMERS_LARGE(CustomerID, CustomerName, Country)
-- PRODUCTS_LARGE(ProductID, ProductName, Price)
-- ORDERS_LARGE(OrderID, CustomerID, ProductID, Quantity, OrderDate)

-------------------------------------------------------------
-- 1. INNER JOIN: Orders with Customer and Product Names
-- Expected: OrderID, OrderDate, CustomerName, ProductName, Quantity
-------------------------------------------------------------
SELECT
    o.OrderID,
    o.OrderDate,
    c.CustomerName,
    p.ProductName,
    o.Quantity
FROM PRACTICAL2.JOINS.ORDERS_LARGE AS o
INNER JOIN CUSTOMERS_LARGE AS c
    ON o.CustomerID = c.CustomerID
INNER JOIN PRODUCTS_LARGE AS p
    ON o.ProductID = p.ProductID;

-------------------------------------------------------------
-- 2. INNER JOIN: Customers Who Placed Orders
-- Expected: CustomerID, CustomerName, Country, OrderID, OrderDate
-------------------------------------------------------------
SELECT
    c.CustomerID,
    c.CustomerName,
    c.Country,
    o.OrderID,
    o.OrderDate
FROM PRACTICAL2.JOINS.CUSTOMERS_LARGE AS c
INNER JOIN ORDERS_LARGE AS o
    ON c.CustomerID = o.CustomerID;

-------------------------------------------------------------
-- 3. LEFT JOIN: All Customers and Their Orders and include customers who have NOT placed any orders.
-- Expected: CustomerID, CustomerName, Country, OrderID, OrderDate, ProductID, Quantity
-------------------------------------------------------------
SELECT
    c.CustomerID,
    c.CustomerName,
    c.Country,
    o.OrderID,
    o.OrderDate,
    o.ProductID,
    o.Quantity
FROM PRACTICAL2.JOINS.CUSTOMERS_LARGE AS c
LEFT JOIN ORDERS_LARGE AS o
    ON c.CustomerID = o.CustomerID;

-------------------------------------------------------------
-- 4. LEFT JOIN: Product Order Count
-- Expected: ProductID, ProductName, TotalOrders
-------------------------------------------------------------
SELECT
    p.ProductID,
    p.ProductName,
    COUNT(o.OrderID) AS TotalOrders
FROM PRACTICAL2.JOINS.PRODUCTS_LARGE AS p
LEFT JOIN ORDERS_LARGE AS o
    ON p.ProductID = o.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY TotalOrders DESC;

-------------------------------------------------------------
-- 5. RIGHT JOIN: Orders with Product Info (Include Products Not Ordered)
-- Expected: OrderID, OrderDate, ProductID, ProductName, Price, Quantity

-------------------------------------------------------------
SELECT
    o.OrderID,
    o.OrderDate,
    p.ProductID,
    p.ProductName,
    p.Price,
    o.Quantity
FROM PRACTICAL2.JOINS.ORDERS_LARGE AS o
RIGHT JOIN PRODUCTS_LARGE AS p
    ON o.ProductID = p.ProductID;

-------------------------------------------------------------
-- 6. RIGHT JOIN: Customer Info with Orders (Include All Customers)
-- Expected: CustomerID, CustomerName, Country, OrderID, OrderDate, ProductID, Quantity

-------------------------------------------------------------
SELECT
    c.CustomerID,
    c.CustomerName,
    c.Country,
    o.OrderID,
    o.OrderDate,
    o.ProductID,
    o.Quantity
FROM PRACTICAL2.JOINS.ORDERS_LARGE AS o
RIGHT JOIN CUSTOMERS_LARGE AS c
    ON o.CustomerID = c.CustomerID;

-------------------------------------------------------------
-- 7. FULL OUTER JOIN: All Customers and All Orders
-- Expected: CustomerID, CustomerName, Country, OrderID, OrderDate, ProductID, Quantity

-------------------------------------------------------------
SELECT
    c.CustomerID,
    c.CustomerName,
    c.Country,
    o.OrderID,
    o.OrderDate,
    o.ProductID,
    o.Quantity
FROM PRACTICAL2.JOINS.CUSTOMERS_LARGE AS c
FULL OUTER JOIN ORDERS_LARGE AS o
    ON c.CustomerID = o.CustomerID;

-------------------------------------------------------------
-- 8. FULL OUTER JOIN: All Products and Orders
-- Expected: ProductID, ProductName, Price, OrderID, OrderDate, CustomerID, Quantity
-------------------------------------------------------------
SELECT
    p.ProductID,
    p.ProductName,
    p.Price,
    o.OrderID,
    o.OrderDate,
    o.CustomerID,
    o.Quantity
FROM PRACTICAL2.JOINS.PRODUCTS_LARGE AS p
FULL OUTER JOIN ORDERS_LARGE AS o
    ON p.ProductID = o.ProductID;
