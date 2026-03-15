# UPS Logistics Delivery Performance Analysis

## Project Overview
This project analyzes logistics delivery performance using SQL.

The goal is to identify delivery delays, optimize routes, and evaluate warehouse and delivery agent efficiency.

## Tools Used
- SQL
- MySQL
- Data Analysis

## Key Analysis

### 1 Data Cleaning
- Checked duplicate orders
- Handled NULL traffic delay values
- Standardized date formats

### 2 Delivery Delay Analysis
- Calculated delivery delay
- Identified top delayed routes
- Ranked orders by delay

### 3 Route Optimization
- Calculated route efficiency
- Identified worst performing routes

### 4 Warehouse Performance
- Ranked warehouses by processing time
- Identified bottleneck warehouses

### 5 Delivery Agent Performance
- Ranked agents by on-time delivery
- Compared top vs bottom agents

### 6 Shipment Tracking Analysis
- Identified delay reasons
- Found orders with multiple delays

### 7 KPI Reporting
- On-time delivery percentage
- Average delivery delay by region

## Example Query

```sql
SELECT 
Order_ID,
DATEDIFF(Actual_Delivery_Date, Order_Date) AS Delay_Days
FROM orders;
