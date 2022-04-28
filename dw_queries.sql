USE cis467_final_project;

SET sql_mode = (SELECT REPLACE(@@SQL_MODE, "ONLY_FULL_GROUP_BY", ""));

DROP TABLE IF EXISTS dw;
CREATE TABLE dw AS
SELECT 
 Orders.CustomerID, Customers.CompanyName AS CustomerName, Customers.Country AS CustomersCountry, Customers.PostalCode, 
    Shippers.ShipperID, Shippers.CompanyName As ShipperName, orders.shipCountry, Orders.OrderID,
    STR_TO_DATE(Orders.OrderDate,"%m/%d/%Y") AS OrderDate,
    STR_TO_DATE(Orders.RequiredDate,"%m/%d/%Y") AS RequiredDate,
    STR_TO_DATE(Orders.ShippedDate,"%m/%d/%Y") AS ShippedDate,
    CASE WHEN DATEDIFF(STR_TO_DATE(Orders.ShippedDate,"%m/%d/%Y"), STR_TO_DATE(Orders.RequiredDate,"%m/%d/%Y")) > 0  THEN 
    DATEDIFF(STR_TO_DATE(Orders.ShippedDate,"%m/%d/%Y"), STR_TO_DATE(Orders.RequiredDate,"%m/%d/%Y")) ELSE 0 END AS delayedDate,
    CONCAT(FirstName, ' ', LastName) AS EmployeesName, STR_TO_DATE(Employees.BirthDate,"%m/%d/%Y") AS EmployeesBirth,
 ROUND(sum(Order_Details.UnitPrice*Quantity*Discount/100*100), 2) AS sum_Discount, MAX(Discount) AS max_Discount ,Orders.Freight, 
    Round(sum((Order_Details.UnitPrice*Quantity*(1-Discount)/100)*100), 2) AS sum_ExtendedPrice,
    Employees.EmployeeID, employeeterritories.TerritoryID
FROM employeeterritories 
 JOIN Shippers JOIN 
   (
    (Employees  JOIN 
     (Customers  JOIN Orders ON Customers.CustomerID = Orders.CustomerID) 
    ON Employees.EmployeeID = Orders.EmployeeID) 
    JOIN Order_Details ON Orders.OrderID = Order_Details.OrderID) 
 ON Shippers.ShipperID = Orders.ShipVia
ON employeeterritories.EmployeeID = Employees.EmployeeID
GROUP BY orderID;

SELECT * FROM dw;



# 01 Freight Weight

# The freight weight for orders with an above-average cost

SELECT Freight, OrderID, sum_ExtendedPrice
FROM cis467_final_project.dw
WHERE sum_ExtendedPrice>
	(SELECT AVG(sum_ExtendedPrice)
    FROM cis467_final_project.dw)
ORDER BY sum_ExtendedPrice DESC;

# Average freight for orders above average price
SELECT AVG(Freight) as average_freight
FROM cis467_final_project.dw
WHERE sum_ExtendedPrice>
	(SELECT AVG(sum_ExtendedPrice)
    FROM cis467_final_project.dw)
ORDER BY sum_ExtendedPrice DESC;



# 02 Locations

# Where did our customers come from? 
# The distribution of the shipments’ destination? Do they overlap? 
# How many times does each shipper ship outside of the USA?

SET sql_mode = (SELECT REPLACE(@@SQL_MODE, "ONLY_FULL_GROUP_BY", ""));

SELECT COUNT(DISTINCT CustomerID) AS numberOfCustomer, CustomersCountry, shipCountry, 
CASE WHEN CustomersCountry = shipCountry THEN "TRUE"
	 ELSE "FALSE"
     END AS isOverlap
FROM cis467_final_project.dw
GROUP BY CustomersCountry
ORDER BY COUNT(DISTINCT CustomerID) DESC;

SELECT ShipperName, count(OrderID) AS shipInternational
FROM dw
WHERE shipCountry <> 'USA'
GROUP BY shipperName WITH ROLLUP
ORDER BY shipInternational;



# 03 Total Extended Price and Number of Orders

# Which customers are spending the most (DESC) on all orders? 
# How many orders per customer?

SELECT PostalCode, SUM(sum_ExtendedPrice) AS totalExtendedPrice
FROM cis467_final_project.dw
GROUP BY PostalCode
ORDER BY sum_ExtendedPrice DESC;

SELECT COUNT(DISTINCT orderid) AS number_of_orders, PostalCode
FROM cis467_final_project.dw
GROUP BY PostalCode
ORDER BY number_of_orders DESC;



# 04 Shippers

# Which shipper takes the least amount of time on average to ship an order? (ascending)
# Which shipper had the most delayed shipments? (DESC)

SELECT OrderID, OrderDate, RequiredDate, ShippedDate, ShipperName, 
DATEDIFF(ShippedDate, OrderDate) AS days_PreShip
FROM dw
GROUP BY OrderID
ORDER BY days_PreShip DESC;



#5 Target Customers

# Which customer spent the most money?

SELECT CustomerID, CustomerName, sum(sum_ExtendedPrice) AS total_CustomerSpend
FROM dw
GROUP BY CustomerID
ORDER BY total_CustomerSpend DESC;



# 06 Orders and Territories

# How many orders does each employee receive? 
# Who received the most orders? How old are these employees? 
# Where are their territories?

SELECT EmployeesName, COUNT(OrderID) AS sum_Order, TIMESTAMPDIFF(YEAR, EmployeesBirth, "1999-01-01") AS Employees_age, TerritoryID
FROM dw
GROUP BY EmployeesName
ORDER BY COUNT(OrderID) DESC;



# 07

# What is the maximum discount per item per order? 
# How much money each customer saves because of the discount?

SELECT dw.OrderID, max_Discount, ROUND(AVG(UnitPrice),2) AS avg_UnitPrice, ROUND(AVG(Quantity),0) AS avg_Quantity
FROM dw JOIN order_details
ON dw.OrderID = order_details.OrderID
WHERE max_Discount > 0
GROUP BY dw.OrderID
ORDER BY max_Discount DESC;



# 08 Orders in Time Period

# How many orders in each month and each year? 

SELECT  CONCAT(YEAR(OrderDate), '-', MONTH(OrderDate)) AS Order_year_month,  COUNT(OrderID) AS Order_num 
FROM dw
GROUP BY CONCAT(YEAR(OrderDate), '-', MONTH(OrderDate));
