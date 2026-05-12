-- =========================
-- SILVER: CRM CUSTOMER INFO
-- =========================
IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;
GO

CREATE TABLE silver.crm_cust_info (
    cst_id             INT,
    cst_key            NVARCHAR(50),
    cst_firstname      NVARCHAR(50),
    cst_lastname       NVARCHAR(50),
    cst_marital_status NVARCHAR(50),
    cst_gndr           NVARCHAR(50),
    cst_create_date    DATE,
    dwh_create_date    DATETIME2 DEFAULT GETDATE()
);
GO

-- INSERT DATA INTO SILVER.CRM_CUST
INSERT INTO silver.crm_cust_info(
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date
)
SELECT cst_id, cst_key,
TRIM(cst_firstname) AS cst_firstname,
TRIM(cst_lastname) AS cst_lastname,
CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'SINGLE'
     WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'MARRIED'
	 ELSE 'n/a'
END cst_marital_status,
CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	 ELSE 'n/a'
END cst_gndr,
cst_create_date
FROM (
	SELECT *,
	ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
)t WHERE flag_last = 1
SELECT * from silver.crm_cust_info;

-- =========================
-- SILVER: CRM PRODUCT INFO
-- =========================
IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;
GO

CREATE TABLE silver.crm_prd_info (
    prd_id        INT,
    cat_id        NVARCHAR(50),
    prd_key       NVARCHAR(50),
    prd_nm        NVARCHAR(50),
    prd_cost      INT,
    prd_line      NVARCHAR(50),
    prd_start_dt  DATE,
    prd_end_dt    DATE,
    dwh_create_date    DATETIME2 DEFAULT GETDATE()
);
GO

-- INSERT DATA INTO SILVER.CRM_PRD
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
    SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
    prd_nm,
    ISNULL(prd_cost, 0) AS prd_cost,
    CASE 
        WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
        WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
        WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
        WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line,
    CAST(prd_start_dt AS DATE) AS prd_start_dt,
    DATEADD(
        DAY, 
        -1, 
        LEAD(CAST(prd_start_dt AS DATE)) OVER (
            PARTITION BY prd_key 
            ORDER BY prd_start_dt
        )
    ) AS prd_end_dt
FROM bronze.crm_prd_info;
SELECT * from silver.crm_prd_info;

-- =========================
-- SILVER: CRM SALES DETAILS
-- =========================
IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;
GO

CREATE TABLE silver.crm_sales_details (
    sls_ord_num   NVARCHAR(50),
    sls_prd_key   NVARCHAR(50),
    sls_cust_id   INT,
    sls_order_id  DATE,
    sls_due_dt    DATE,          -- Fixed from INT ? DATE
    sls_sales     INT,
    sls_quantity  INT,           -- Fixed spelling
    sls_price     INT,
    dwh_create_date    DATETIME2 DEFAULT GETDATE()
);
GO
-- INSTER INTO SILVER.CRM_SALES
INSERT INTO silver.crm_sales_details (
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_id,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
)
SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    TRY_CAST(sls_ord_num AS INT) AS sls_order_id,
    CASE 
        WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_due_dt AS VARCHAR(8)) AS DATE)
    END AS sls_due_dt,
    CASE 
        WHEN sls_sales IS NULL 
             OR sls_sales <= 0 
             OR sls_sales != sls_quantity * ABS(sls_price)
        THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,
    sls_quantity,
    CASE 
        WHEN sls_price IS NULL OR sls_price <= 0
        THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price
FROM bronze.crm_sales_details;

SELECT * from silver.crm_sales_details;

-- =========================
-- SILVER: ERP LOCATION
-- =========================
IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_a101;
GO

CREATE TABLE silver.erp_loc_a101 (
    cid    NVARCHAR(50),
    cntry  NVARCHAR(50),
    dwh_create_date    DATETIME2 DEFAULT GETDATE(),
);
GO
-- INSTER INTO SILVER.ERP_LOC
INSERT INTO silver.erp_loc_a101 (
    cid,
    cntry
)
SELECT 
    REPLACE(TRIM(cid), '-', '') AS cid,
    CASE 
        WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
        WHEN UPPER(TRIM(cntry)) IN ('US', 'USA') THEN 'United States'
        WHEN cntry IS NULL OR TRIM(cntry) = '' THEN 'n/a'
        ELSE TRIM(cntry)
    END
FROM bronze.erp_loc_a101;
SELECT * from silver.erp_loc_a101;

-- =========================
-- SILVER: ERP CUSTOMER
-- =========================
IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;
GO
CREATE TABLE silver.erp_cust_az12 (
    cid    NVARCHAR(50),
    bdate  DATE,
    gen    NVARCHAR(50),
    dwh_create_date    DATETIME2 DEFAULT GETDATE()
);
GO
-- INSTER INTO SILVER.ERP_CUST
INSERT INTO silver.erp_cust_az12 (
    cid,
    bdate,
    gen
)
SELECT 
    CASE 
        WHEN TRIM(cid) LIKE 'NAS%' THEN SUBSTRING(TRIM(cid), 4, LEN(cid))
        ELSE TRIM(cid)
    END,
    CASE 
        WHEN bdate > GETDATE() THEN NULL
        ELSE bdate
    END,
    CASE 
        WHEN gen IS NULL THEN 'n/a'
        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
        ELSE 'n/a'
    END
FROM bronze.erp_cust_az12;
SELECT * from silver.erp_cust_az12;

-- =========================
-- SILVER: ERP PRODUCT CATEGORY
-- =========================
IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;
GO

CREATE TABLE silver.erp_px_cat_g1v2 (
    pid           NVARCHAR(50),
    cat          NVARCHAR(50),
    subcat       NVARCHAR(50),
    maintenance  NVARCHAR(50),
    dwh_create_date    DATETIME2 DEFAULT GETDATE()
);
GO
-- INSTER INTO SILVER.ERP_PX_CAT
INSERT INTO silver.erp_px_cat_g1v2(
    pid,
    cat,
    subcat,
    maintenance
)
SELECT 
pid,
cat,
subcat,
maintenance
FROM bronze.erp_prd_p101;
SELECT * FROM silver.erp_px_cat_g1v2;