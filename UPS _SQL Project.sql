#Task 1: Data Cleaning & Preparation


#Create database
CREATE DATABASE ups_logistics;
USE ups_logistics;

#Check Duplicate Orders

SELECT Order_ID, COUNT(*)
FROM orders
GROUP BY Order_ID
HAVING COUNT(*) > 1;


#Replace NULL Traffic Delay

SELECT *
FROM routes
WHERE Traffic_Delay_Min IS NULL;

#Standardize Date Format

UPDATE orders
SET Order_Date = STR_TO_DATE(Order_Date, '%Y-%m-%d'),
    Actual_Delivery_Date = STR_TO_DATE(Actual_Delivery_Date, '%Y-%m-%d');

SET SQL_SAFE_UPDATES = 0;

#● Ensure that no Actual_Delivery_Date is before Order_Date (flag such records).



SELECT *
FROM orders
WHERE Actual_Delivery_Date < Order_Date;



#Task 2: Delivery Delay Analysis

#  Calculate delivery delay (in days) for each order
SELECT 
    Order_ID,
    Order_Date,
    Actual_Delivery_Date,
    DATEDIFF(Actual_Delivery_Date, Order_Date) AS Delay_Days
FROM orders;

 
#Top 10 Delayed Routes (Average Delay)

SELECT 
    Route_ID,
    AVG(DATEDIFF(Actual_Delivery_Date, Order_Date)) AS Avg_Delay_Days
FROM orders
GROUP BY Route_ID
ORDER BY Avg_Delay_Days DESC
LIMIT 10;



#Rank Orders by Delay Within Each Warehouse

SELECT
    Order_ID,
    Warehouse_ID,
    DATEDIFF(Actual_Delivery_Date, Order_Date) AS Delay_Days,
    RANK() OVER (
        PARTITION BY Warehouse_ID
        ORDER BY DATEDIFF(Actual_Delivery_Date, Order_Date) DESC
    ) AS Delay_Rank
FROM orders;



#: TASK 3 Route Optimization Insights

#Route Performance Metrics

SELECT
    r.Route_ID,
    AVG(DATEDIFF(o.Actual_Delivery_Date, o.Order_Date)) AS Avg_Delivery_Days,
    r.Traffic_Delay_Min AS Avg_Traffic_Delay_Min,
    (r.Distance_KM / r.Average_Travel_Time_Min) AS Efficiency_Ratio
FROM routes r
JOIN orders o ON r.Route_ID = o.Route_ID
GROUP BY r.Route_ID, r.Traffic_Delay_Min, r.Distance_KM, r.Average_Travel_Time_Min;


#Find 3 Worst Efficiency Routes

SELECT
    Route_ID,
    (Distance_KM / Average_Travel_Time_Min) AS Efficiency_Ratio
FROM routes
ORDER BY Efficiency_Ratio ASC
LIMIT 3;



#Routes with >20% Delayed Shipments

SELECT
    Route_ID,
    COUNT(*) AS Total_Shipments,
    SUM(CASE 
        WHEN Actual_Delivery_Date > Expected_Delivery_Date 
        THEN 1 ELSE 0 END) AS Delayed_Shipments,
    (SUM(CASE 
        WHEN Actual_Delivery_Date > Expected_Delivery_Date 
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS Delay_Percentage
FROM orders
GROUP BY Route_ID;



#Task 4 : Warehouse Performance

DESCRIBE warehouses;

#Top 3 Warehouses (Highest Avg Processing Time)

SELECT
    Warehouse_ID,
    Processing_Time_Min
FROM warehouses
ORDER BY Processing_Time_Min DESC
LIMIT 3;


# Total vs Delayed Shipments per Warehouse


SELECT
    Warehouse_ID,
    COUNT(*) AS Total_Shipments,
    SUM(CASE 
        WHEN Actual_Delivery_Date > Expected_Delivery_Date 
        THEN 1 ELSE 0 END) AS Delayed_Shipments
FROM orders
GROUP BY Warehouse_ID;

#Bottleneck Warehouses (Using CTE)



WITH  global_avg 
AS (
    SELECT 
        AVG(Processing_Time_Min) AS avg_time
    FROM warehouses
)

SELECT
    w.Warehouse_ID,
    w.Processing_Time_Min,
    g.avg_time AS Global_Average_Time
FROM warehouses w
JOIN global_avg g
    ON w.Processing_Time_Min > g.avg_time;

#Rank Warehouses by On-Time %

SELECT Warehouse_ID, OnTime_Percentage,
 RANK() OVER (ORDER BY OnTime_Percentage DESC) AS Warehouse_Rank
FROM (
    SELECT
        Warehouse_ID,
        (SUM(CASE 
            WHEN Actual_Delivery_Date <= Expected_Delivery_Date 
            THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS OnTime_Percentage
    FROM orders
    GROUP BY Warehouse_ID
) AS warehouse_stats;





#Task 5: Delivery Agent Performance 

DESCRIBE orders;
DESCRIBE deliveryagents;

#Rank Agents (Per Route) by On-Time %

SELECT
    Agent_ID,
    Route_ID,
    On_Time_Percentage,
    RANK() OVER (
        PARTITION BY Route_ID
        ORDER BY On_Time_Percentage DESC
    ) AS Agent_Rank
FROM deliveryagents;

# Find agents with on-time % < 80%. 

SELECT
    Agent_ID,
    Route_ID,
    On_Time_Percentage
FROM deliveryagents
WHERE On_Time_Percentage < 80;

#Compare Average Speed of Top 5 vs Bottom 5 Agents

SELECT AVG(Avg_Speed_KM_HR) AS Avg_Speed_Top5
FROM (
    SELECT Avg_Speed_KM_HR
    FROM deliveryagents
    ORDER BY On_Time_Percentage DESC
    LIMIT 5
) AS top_agents;



SELECT AVG(Avg_Speed_KM_HR) AS Avg_Speed_Bottom5
FROM (
    SELECT Avg_Speed_KM_HR
    FROM deliveryagents
    ORDER BY On_Time_Percentage ASC
    LIMIT 5
) AS bottom_agents;






#Task 6: Shipment Tracking Analytics

DESCRIBE `shipment tracking table`;

#For Each Order, List the Last Checkpoint and Time

SELECT 
    Order_ID,
    Checkpoint,
    Checkpoint_Time
FROM `shipment tracking table` st1
WHERE Checkpoint_Time = (
    SELECT MAX(Checkpoint_Time)
    FROM `shipment tracking table` st2
    WHERE st1.Order_ID = st2.Order_ID
);


#Most Common Delay Reasons (Excluding 'None')

SELECT 
    Delay_Reason,
    COUNT(*) AS Occurrences
FROM `shipment tracking table`
WHERE Delay_Reason IS NOT NULL
AND Delay_Reason <> 'None'
GROUP BY Delay_Reason
ORDER BY Occurrences DESC;


#Orders with More Than 2 Delayed Checkpoints

SELECT 
    Order_ID,
    COUNT(*) AS Delayed_Checkpoints
FROM `shipment tracking table`
WHERE Delay_Reason IS NOT NULL
AND Delay_Reason <> 'None'
GROUP BY Order_ID
HAVING COUNT(*) > 2;




#Task 7: Advanced KPI Reporting

#Average Delivery Delay per Region

SELECT
    r.Start_Location,
    AVG(DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date)) AS Avg_Delay_Days
FROM orders o
JOIN routes r 
ON o.Route_ID = r.Route_ID
GROUP BY r.Start_Location
ORDER BY Avg_Delay_Days DESC;


#On-Time Delivery %

SELECT
    (SUM(CASE 
        WHEN Actual_Delivery_Date <= Expected_Delivery_Date 
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS OnTime_Delivery_Percentage
FROM orders;


#Average Traffic Delay per Route


SELECT
    Route_ID,
    AVG(Traffic_Delay_Min) AS Avg_Traffic_Delay_Min
FROM routes
GROUP BY Route_ID
ORDER BY Avg_Traffic_Delay_Min DESC;



















