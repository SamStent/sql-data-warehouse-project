/* ============================================================================
   Carga Bronze Layer (PostgreSQL - pgAdmin COPY)
   ============================================================================
   Este script:
     - Trunca las tablas Bronze
     - Carga los CSV usando COPY (servidor PostgreSQL)
     - Requiere permisos de lectura en las carpetas origen
   ============================================================================
*/

-- ============================
-- TRUNCAR TABLAS BRONZE
-- ============================
TRUNCATE TABLE bronze.crm_cust_info;
TRUNCATE TABLE bronze.crm_prd_info;
TRUNCATE TABLE bronze.crm_sales_details;

TRUNCATE TABLE bronze.erp_loc_a101;
TRUNCATE TABLE bronze.erp_cust_az12;
TRUNCATE TABLE bronze.erp_px_cat_g1v2;

-- ============================
-- CARGA CRM
-- ============================

COPY bronze.crm_cust_info
FROM '/home/wuttkefederico/data/sql-data-warehouse-project/datasets/source_crm/cust_info.csv'
CSV HEADER;

COPY bronze.crm_prd_info
FROM '/home/wuttkefederico/data/sql-data-warehouse-project/datasets/source_crm/prd_info.csv'
CSV HEADER;

COPY bronze.crm_sales_details
FROM '/home/wuttkefederico/data/sql-data-warehouse-project/datasets/source_crm/sales_details.csv'
CSV HEADER;


-- ============================
-- CARGA ERP
-- ============================

COPY bronze.erp_loc_a101
FROM '/home/wuttkefederico/data/sql-data-warehouse-project/datasets/source_erp/LOC_A101.csv'
CSV HEADER;

COPY bronze.erp_cust_az12
FROM '/home/wuttkefederico/data/sql-data-warehouse-project/datasets/source_erp/CUST_AZ12.csv'
CSV HEADER;

COPY bronze.erp_px_cat_g1v2
FROM '/home/wuttkefederico/data/sql-data-warehouse-project/datasets/source_erp/PX_CAT_G1V2.csv'
CSV HEADER;
