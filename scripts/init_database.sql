/* 
===========================================================
  SCRIPT DE INICIALIZACIÓN DEL DATA WAREHOUSE (POSTGRESQL)
===========================================================

Este script realiza los siguientes pasos:

1. Crea la base de datos 'DataWarehouse' si no existe.
2. Cambia el contexto para trabajar dentro de esa base.
3. Crea los schemas 'bronze', 'silver' y 'gold', 
   utilizando 'IF NOT EXISTS' para evitar errores si ya existen.
4. Verifica que los schemas fueron creados correctamente.

Este setup sigue la arquitectura Medallion adaptada a PostgreSQL.
===========================================================
*/

-- 1) Crear la base de datos (solo ejecutar una vez)
CREATE DATABASE "DataWarehouse";

-- 2) Conectarse a la base de datos
\c DataWarehouse;

-- 3) Crear schemas del Medallion Architecture
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

-- 4) Verificar que los schemas existen
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name IN ('bronze', 'silver', 'gold');

