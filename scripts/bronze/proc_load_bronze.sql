/*
================================================================================
Script: Load Bronze Layer (CSV → PostgreSQL Bronze Schema)
================================================================================
Propósito:
    Este script ejecuta la carga de la capa Bronze desde archivos CSV locales 
    hacia las tablas del esquema 'bronze' en PostgreSQL.

    Acciones realizadas:
      - Truncado de tablas Bronze antes de cada carga.
      - Carga de datos mediante COPY (server-side).
      - Registro de tiempos de carga con RAISE NOTICE.
      - Estructura modular para facilitar la extensión a nuevas tablas.

Notas importantes:
    - COPY requiere que los archivos CSV sean accesibles por el servidor PostgreSQL.
    - Para rutas locales del usuario, usar \copy desde psql en lugar de COPY.
    - Este script debe ejecutarse con permisos suficientes sobre el esquema Bronze.

Uso:
    Ejecutar directamente en psql:
        psql -U <usuario> -d <base_datos> -f load_bronze.sql

    O copiar el bloque DO $$ ... $$ dentro del editor SQL de PostgreSQL.

Autor:
    Federico Wuttke — Data Warehouse Project (Bronze Layer)
================================================================================
*/


DO $$
DECLARE
    start_time TIMESTAMP;
    end_time   TIMESTAMP;
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Loading Bronze Layer';
    RAISE NOTICE '==============================================';

    ------------------------------------------------------------
    -- CRM: cust_info
    ------------------------------------------------------------
    RAISE NOTICE '>> Truncating Table\: bronze.crm_cust_info';
    start_time := clock_timestamp();
    TRUNCATE TABLE bronze.crm_cust_info;

    RAISE NOTICE '>> Loading Data Into\: bronze.crm_cust_info';
    COPY bronze.crm_cust_info
    FROM '/home/wuttkefederico/data/sql-data-warehouse-project/datasets/source_crm/cust_info.csv'
    WITH (FORMAT csv, HEADER true);

    end_time := clock_timestamp();
    RAISE NOTICE '>> Load Duration\: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    ------------------------------------------------------------
    -- CRM: prd_info
    ------------------------------------------------------------
    RAISE NOTICE '>> Truncating Table\: bronze.crm_prd_info';
    start_time := clock_timestamp();
    TRUNCATE TABLE bronze.crm_prd_info;

    RAISE NOTICE '>> Loading Data Into\: bronze.crm_prd_info';
    COPY bronze.crm_prd_info
    FROM '/home/wuttkefederico/data/sql-data-warehouse-project/datasets/source_crm/prd_info.csv'
    WITH (FORMAT csv, HEADER true);

    end_time := clock_timestamp();
    RAISE NOTICE '>> Load Duration\: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

	------------------------------------------------------------
    -- CRM: sales_details
    ------------------------------------------------------------
    RAISE NOTICE '>> Truncating Table\: bronze.crm_sales_details';
    start_time := clock_timestamp();
    TRUNCATE TABLE bronze.crm_sales_details;

    RAISE NOTICE '>> Loading Data Into\: bronze.crm_sales_details';
    COPY bronze.crm_sales_details
    FROM '/home/wuttkefederico/data/sql-data-warehouse-project/datasets/source_crm/sales_details.csv'
    WITH (FORMAT csv, HEADER true);

    end_time := clock_timestamp();
    RAISE NOTICE '>> Load Duration\: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

	------------------------------------------------------------
    -- ERP: cust_az12
    ------------------------------------------------------------
    RAISE NOTICE '>> Truncating Table\: bronze.erp_cust_az12';
    start_time := clock_timestamp();
    TRUNCATE TABLE bronze.erp_cust_az12;

    RAISE NOTICE '>> Loading Data Into\: bronze.erp_cust_az12';
    COPY bronze.erp_cust_az12
    FROM '/home/wuttkefederico/data/sql-data-warehouse-project/datasets/source_erp/CUST_AZ12.csv'
    WITH (FORMAT csv, HEADER true);

    end_time := clock_timestamp();
    RAISE NOTICE '>> Load Duration\: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    ------------------------------------------------------------
    -- ERP: loc_a101
    ------------------------------------------------------------
    RAISE NOTICE '>> Truncating Table\: bronze.erp_loc_a101';
    start_time := clock_timestamp();
    TRUNCATE TABLE bronze.erp_loc_a101;

    RAISE NOTICE '>> Loading Data Into\: bronze.erp_loc_a101';
    COPY bronze.erp_loc_a101
    FROM '/home/wuttkefederico/data/sql-data-warehouse-project/datasets/source_erp/LOC_A101.csv'
    WITH (FORMAT csv, HEADER true);

    end_time := clock_timestamp();
    RAISE NOTICE '>> Load Duration\: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    ------------------------------------------------------------
    -- ERP: px_cat_g1v2
    ------------------------------------------------------------
    RAISE NOTICE '>> Truncating Table\: bronze.erp_px_cat_g1v2';
    start_time := clock_timestamp();
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;

    RAISE NOTICE '>> Loading Data Into\: bronze.erp_px_cat_g1v2';
    COPY bronze.erp_px_cat_g1v2
    FROM '/home/wuttkefederico/data/sql-data-warehouse-project/datasets/source_erp/PX_CAT_G1V2.csv'
    WITH (FORMAT csv, HEADER true);

    end_time := clock_timestamp();
    RAISE NOTICE '>> Load Duration\: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

END $$;
