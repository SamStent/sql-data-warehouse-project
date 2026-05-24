/* ============================================================================
   SCRIPT: proc_load_silver.sql
   PURPOSE:
       Carga de datos limpios desde la capa Bronze hacia la capa Silver.
       Este script contiene ÚNICAMENTE las instrucciones INSERT INTO para
       poblar las tablas Silver del Data Warehouse.

   TABLAS INCLUIDAS:
       - silver.crm_cust_info
       - silver.crm_prd_info
       - silver.crm_sales_details

   NOTAS:
       - Las transformaciones aplicadas provienen de los análisis previos
         realizados sobre la capa Bronze.
       - Para validaciones, checks y diagnósticos, consultar el script:
         silver_full_process.sql
   ============================================================================ */


-- ============================================================================
-- 1) CARGA TABLA: silver.crm_cust_info
-- ============================================================================
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
    END AS cst_marital_status,
    CASE 
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        ELSE 'n/a'
    END AS cst_gndr,
    cst_create_date
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
    FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL
) t
WHERE flag_last = 1;



-- ============================================================================
-- 2) CARGA TABLA: silver.crm_prd_info
-- ============================================================================
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
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
    SUBSTRING(prd_key, 7, LENGTH(prd_key)) AS prd_key,
    prd_nm,
    COALESCE(prd_cost, 0),
    CASE UPPER(TRIM(prd_line))
        WHEN 'M' THEN 'Mountain'
        WHEN 'R' THEN 'Road'
        WHEN 'S' THEN 'Other Sales'
        WHEN 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line,
    CAST(prd_start_dt AS DATE),
    CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - INTERVAL '1 day' AS DATE)
FROM bronze.crm_prd_info;



-- ============================================================================
-- 3) CARGA TABLA: silver.crm_sales_details
-- ============================================================================
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



-- ============================================================================
-- 4) CARGA TABLA: silver.erp_cust_az12
-- ============================================================================
INSERT INTO silver.erp_cust_az12 (
	cid,
	bdate,
	gen
)
SELECT
	CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid)) -- Quita el prefijo 'NAS' si existe
		ELSE cid
	END AS cid,
	CASE WHEN bdate > CURRENT_TIMESTAMP THEN NULL -- Cambia nacimientos futuros a NULL
		ELSE bdate
	END AS bdate,
	CASE WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
		 WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
		 ELSE 'n/a'
	END AS gen
FROM bronze.erp_cust_az12;



-- ============================================================================
-- 4) CARGA TABLA: silver.erp_loc_a101
-- ============================================================================
INSERT INTO silver.erp_loc_a101 (
	cid,
	cntry
)
SELECT
	REPLACE(cid, '-', '') AS cid,
	CASE WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
		 WHEN UPPER(TRIM(cntry)) IN ('US', 'USA') THEN 'United States'
		 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
		 ELSE TRIM(cntry)
	END AS cntry
FROM bronze.erp_loc_a101;



-- ============================================================================
-- 4) CARGA TABLA: silver.erp_px_cat_g1v2
-- ============================================================================
INSERT INTO silver.erp_px_cat_g1v2 (
	id,
	cat,
	subcat,
	maintenance
)
SELECT
	id,
	cat,
	subcat,
	maintenance
FROM bronze.erp_px_cat_g1v2;
