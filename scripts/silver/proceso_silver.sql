/* ============================================================================
   SCRIPT: silver_full_process.sql
   PURPOSE:
       Ejecutar el proceso completo de validación, transformación y carga de
       datos desde la capa Bronze hacia la capa Silver del Data Warehouse.

   ESTRUCTURA:
       1) Validaciones sobre Bronze
       2) Carga de tablas Silver
       3) Validaciones posteriores sobre Silver
       4) Resumen final de calidad

   NOTAS:
       - Este script está diseñado para auditoría y control de calidad.
       - Para la carga limpia sin checks, usar: silver_load.sql
   ============================================================================ */



/* ============================================================================
   1) VALIDACIONES SOBRE BRONZE
   ============================================================================ */

-- ============================================================
-- CLIENTES (crm_cust_info)
-- ============================================================

-- Duplicados o IDs nulos
SELECT cst_id, COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Espacios no deseados
SELECT cst_firstname FROM bronze.crm_cust_info WHERE cst_firstname != TRIM(cst_firstname);
SELECT cst_lastname  FROM bronze.crm_cust_info WHERE cst_lastname  != TRIM(cst_lastname);
SELECT cst_gndr      FROM bronze.crm_cust_info WHERE cst_gndr      != TRIM(cst_gndr);

-- Registros no más recientes por ID
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
    FROM bronze.crm_cust_info
) t
WHERE flag_last != 1;

-- Valores de estado civil
SELECT DISTINCT cst_marital_status FROM bronze.crm_cust_info;



-- ============================================================
-- PRODUCTOS (crm_prd_info)
-- ============================================================

-- Espacios no deseados
SELECT prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Costos inválidos
SELECT prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Fechas inconsistentes
SELECT *
FROM bronze.crm_prd_info
WHERE prd_start_dt > prd_end_dt;



-- ============================================================
-- VENTAS (crm_sales_details)
-- ============================================================

-- Espacios en sls_ord_num
SELECT *
FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

-- Relación con productos
SELECT *
FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

-- Relación con clientes
SELECT *
FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);

-- Fechas inválidas
SELECT sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 OR LENGTH(CAST(sls_order_dt AS VARCHAR)) != 8;

-- Reglas de negocio: sales = quantity * price
SELECT DISTINCT sls_sales, sls_quantity, sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0;



/* ============================================================================
   2) CARGA DE TABLAS SILVER
   ============================================================================ */

-- ============================================================
-- CLIENTES
-- ============================================================
INSERT INTO silver.crm_cust_info(
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date
)
SELECT
    cst_id,
    cst_key,
    TRIM(cst_firstname),
    TRIM(cst_lastname),
    CASE 
        WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
        WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
        ELSE 'n/a'
    END,
    CASE 
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        ELSE 'n/a'
    END,
    cst_create_date
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
    FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL
) t
WHERE flag_last = 1;



-- ============================================================
-- PRODUCTOS
-- ============================================================
INSERT INTO silver.crm_prd_info (
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
SELECT
    prd_id,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_'),
    SUBSTRING(prd_key, 7, LENGTH(prd_key)),
    prd_nm,
    COALESCE(prd_cost, 0),
    CASE UPPER(TRIM(prd_line))
        WHEN 'M' THEN 'Mountain'
        WHEN 'R' THEN 'Road'
        WHEN 'S' THEN 'Other Sales'
        WHEN 'T' THEN 'Touring'
        ELSE 'n/a'
    END,
    CAST(prd_start_dt AS DATE),
    CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - INTERVAL '1 day' AS DATE)
FROM bronze.crm_prd_info;



-- ============================================================
-- VENTAS
-- ============================================================
INSERT INTO silver.crm_sales_details (
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
)
SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    CASE 
        WHEN sls_order_dt <= 0 OR LENGTH(sls_order_dt::text) != 8 THEN NULL
        ELSE to_date(sls_order_dt::text, 'YYYYMMDD')
    END,
    CASE 
        WHEN sls_ship_dt <= 0 OR LENGTH(sls_ship_dt::text) != 8 THEN NULL
        ELSE to_date(sls_ship_dt::text, 'YYYYMMDD')
    END,
    CASE 
        WHEN sls_due_dt <= 0 OR LENGTH(sls_due_dt::text) != 8 THEN NULL
        ELSE to_date(sls_due_dt::text, 'YYYYMMDD')
    END,
    CASE 
        WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END,
    sls_quantity,
    CASE 
        WHEN sls_price IS NULL OR sls_price <= 0
            THEN sls_sales / COALESCE(sls_quantity, 0)
        ELSE sls_price
    END
FROM bronze.crm_sales_details;



/* ============================================================================
   3) VALIDACIONES SOBRE SILVER
   ============================================================================ */

-- CLIENTES: PK duplicadas o nulas
SELECT cst_id, COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- PRODUCTOS: fechas inconsistentes
SELECT *
FROM silver.crm_prd_info
WHERE prd_start_dt > prd_end_dt;

-- VENTAS: fechas inconsistentes
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- VENTAS: reglas de negocio
SELECT DISTINCT sls_sales, sls_quantity, sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0;



/* ============================================================================
   4) RESUMEN FINAL
   ============================================================================ */

SELECT 'crm_cust_info', COUNT(*) FROM silver.crm_cust_info;
SELECT 'crm_prd_info', COUNT(*) FROM silver.crm_prd_info;
SELECT 'crm_sales_details', COUNT(*) FROM silver.crm_sales_details;

