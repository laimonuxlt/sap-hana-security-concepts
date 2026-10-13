-- PART1
-- Check if roles were created
SELECT ROLE_SCHEMA_NAME, ROLE_NAME
FROM ROLES
WHERE ROLE_SCHEMA_NAME = 'SECURITY_CONCEPTS_LAIMONAS_SAMALIUS_HDI_DB_1'
  AND (ROLE_NAME LIKE '%analyst_role%'
    OR ROLE_NAME LIKE '%developer_role%'
    OR ROLE_NAME LIKE '%app_service_role%')
ORDER BY ROLE_NAME;

-- Part2
-- Verify the granted roles by grantee (partner)
SELECT GRANTEE, ROLE_NAME, IS_GRANTABLE
FROM GRANTED_ROLES
WHERE GRANTEE = 'P080469';

-- Verify the granted privileges by grantee (partner)
SELECT GRANTEE, PRIVILEGE
FROM GRANTED_PRIVILEGES
WHERE GRANTEE = 'P080469';

-- Privileges my each role has
SELECT GRANTEE AS ROLE_NAME, PRIVILEGE, OBJECT_TYPE, SCHEMA_NAME, OBJECT_NAME
FROM GRANTED_PRIVILEGES
WHERE GRANTEE_SCHEMA_NAME = 'SECURITY_CONCEPTS_LAIMONAS_SAMALIUS_HDI_DB_1'
  AND GRANTEE IN ('analyst_role', 'developer_role', 'app_service_role')
ORDER BY GRANTEE, PRIVILEGE;


-- Privileges partners my each role has
SELECT GRANTEE AS ROLE_NAME, PRIVILEGE, OBJECT_TYPE, SCHEMA_NAME, OBJECT_NAME
FROM GRANTED_PRIVILEGES
WHERE GRANTEE_SCHEMA_NAME = 'MYSCHEMA_1'
  AND GRANTEE IN ('analyst_role', 'developer_role', 'app_service_role')
ORDER BY GRANTEE, PRIVILEGE;


-- Part3
-- Step 3.1:
-- Test 1: Query a calculation view
SELECT * FROM "MYSCHEMA_1"."CV_SALES_SECURED"
LIMIT 10;

-- Test 2: Count records
SELECT COUNT(*) AS TOTAL_RECORDS
FROM "MYSCHEMA_1"."CV_SALES_SECURED";

--Step 3.2: Verify Row-Level Security (Analytic Privilege)
-- Query the secured view and check what data you can see
SELECT REGION, COUNT(*) AS ROW_COUNT, SUM(TOTAL_SALES) AS TOTAL_AMOUNT
FROM "MYSCHEMA_1"."CV_SALES_SECURED"
GROUP BY REGION
ORDER BY REGION;

-- If privilege filters for EMEA region, you should only see EMEA data
-- Try to see all regions (this should still only show filtered data)
SELECT DISTINCT REGION
FROM "MYSCHEMA_1"."CV_SALES_SECURED"
ORDER BY REGION;


-- Step 3.3: Test Restricted Operations (Negative Testing)
-- This should FAIL with "insufficient privilege" error
-- Expected error: insufficient privilege
INSERT INTO "MYSCHEMA_1".PRODUCTS VALUES (11, 'Desk Lamp', 'Furniture', 39.99, 75, '2024-03-25');


-- This should FAIL with "insufficient privilege" error
-- Expected error: insufficient privilege
UPDATE "MYSCHEMA_1".PRODUCTS 
SET "PRICE" = 100.99
WHERE "ID" = 1;

-- This should FAIL with "insufficient privilege" error
-- Expected error: insufficient privilege
UPDATE "MYSCHEMA_1"."CV_SALES_SECURED"
SET PRICE = 100.99
WHERE "PRODUCT_ID" = 1;


-- This should FAIL - no DDL access
-- Expected error: insufficient privilege
CREATE TABLE "MYSCHEMA_1"."TEST_TABLE" ( ID INTEGER);

CALL SYS.GET_INSUFFICIENT_PRIVILEGE_ERROR_DETAILS('3F02A92566C4E44A9F10C9AE23CA2C3B', ?);




