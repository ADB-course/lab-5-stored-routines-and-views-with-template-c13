-- (i) A Procedure called PROC_LAB5
-- Define the delimiter to allow for multiple statements in the procedure
DELIMITER $$

-- Create the PROC_LAB5 procedure in the classicmodels database
CREATE PROCEDURE classicmodels.PROC_LAB5()
BEGIN
    -- Variable declarations
    DECLARE finished INT DEFAULT 0;                -- Flag to indicate when cursor fetching is done
    DECLARE employee_details TEXT DEFAULT '';      -- Variable to store concatenated employee details
    DECLARE emp_name VARCHAR(255);                  -- Variable to hold the employee name
    DECLARE emp_sales DECIMAL(10, 2);              -- Variable to hold the total sales for each employee
    DECLARE start_time DATETIME DEFAULT NOW();     -- Capture the start time of the procedure
    DECLARE end_time DATETIME;                     -- Variable to hold the end time of the procedure

    -- Declare a cursor to fetch employee names and their total sales
    DECLARE emp_cursor CURSOR FOR
        SELECT CONCAT(e.first_name, ' ', e.last_name) AS full_name, SUM(od.priceEach * od.quantityOrdered) AS total_sales
        FROM employees e
        JOIN customers c ON e.employee_id = c.salesRepEmployeeNumber
        JOIN orders o ON c.customerNumber = o.customerNumber
        JOIN orderdetails od ON o.orderNumber = od.orderNumber
        GROUP BY e.employee_id;

    -- Handler to set finished flag when no more rows are found
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;

    -- Open the cursor to start fetching data
    OPEN emp_cursor;

    -- Loop to fetch each row from the cursor
    LOOP
        FETCH emp_cursor INTO emp_name, emp_sales; -- Fetch the next employee name and their total sales
        IF finished THEN                            -- Check if fetching is complete
            LEAVE LOOP;                            -- Exit the loop if no more rows are available
        END IF;
        -- Concatenate employee details to the employee_details variable
        SET employee_details = CONCAT(employee_details, emp_name, ' - Total Sales: $', FORMAT(emp_sales, 2), CHAR(10));
    END LOOP;

    -- Close the cursor after fetching all data
    CLOSE emp_cursor;

    -- Capture the end time after processing
    SET end_time = NOW();
    
    -- Log the execution details into the procedure_log table
    INSERT INTO procedure_log (procedure_name, execution_time, execution_duration)
    VALUES ('PROC_LAB5', end_time, TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000);

    -- Return the concatenated employee sales details
    SELECT employee_details AS "Employee Sales Details";
END $$

-- Reset the delimiter back to the default
DELIMITER ;

-- (ii) A Function called FUNC_LAB5
-- Create the FUNC_LAB5 function in the classicmodels database
CREATE FUNCTION classicmodels.FUNC_LAB5(department_id INT)
RETURNS VARCHAR(255)                             -- Function returns a string
DETERMINISTIC                                     -- Function behavior is deterministic
BEGIN
    DECLARE total_sales DECIMAL(10, 2);          -- Variable to hold the total sales for the specified department
    DECLARE sales_message VARCHAR(255);           -- Variable to store the result message
    
    -- Calculate the total sales for the specified department
    SELECT SUM(od.priceEach * od.quantityOrdered) INTO total_sales
    FROM employees e
    JOIN customers c ON e.employee_id = c.salesRepEmployeeNumber
    JOIN orders o ON c.customerNumber = o.customerNumber
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    WHERE e.department_id = department_id;

    -- Check if total_sales is NULL (no sales found for this department)
    IF total_sales IS NULL THEN
        SET sales_message = 'No sales data found for the specified department.';
    ELSE
        SET sales_message = CONCAT('Total Sales for Department ', department_id, ': $', FORMAT(total_sales, 2));
    END IF;

    -- Return the result message
    RETURN sales_message;
END;

-- (iii) A View called VIEW_LAB5
-- Define the VIEW_LAB5 view to retrieve and display employee sales data
CREATE VIEW classicmodels.VIEW_LAB5 AS
SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    d.department_name,
    SUM(od.priceEach * od.quantityOrdered) AS total_sales,
    (SELECT MAX(od.priceEach * od.quantityOrdered) FROM orderdetails od WHERE od.orderNumber IN (SELECT o.orderNumber FROM orders o WHERE o.customerNumber IN (SELECT c.customerNumber FROM customers c WHERE c.salesRepEmployeeNumber = e.employee_id))) AS max_sale,
    (SELECT MIN(od.priceEach * od.quantityOrdered) FROM orderdetails od WHERE od.orderNumber IN (SELECT o.orderNumber FROM orders o WHERE o.customerNumber IN (SELECT c.customerNumber FROM customers c WHERE c.salesRepEmployeeNumber = e.employee_id))) AS min_sale
FROM 
    employees e
JOIN 
    departments d ON e.department_id = d.department_id
JOIN 
    customers c ON e.employee_id = c.salesRepEmployeeNumber
JOIN 
    orders o ON c.customerNumber = o.customerNumber
JOIN 
    orderdetails od ON o.orderNumber = od.orderNumber
GROUP BY 
    e.employee_id;