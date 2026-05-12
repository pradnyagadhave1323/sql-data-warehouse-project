IF OBJECT_ID('silver.load_silver', 'P') IS NOT NULL
    DROP PROCEDURE silver.load_silver;
GO

CREATE PROCEDURE silver.load_silver
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @start_time DATETIME,
        @end_time DATETIME,
        @row_count INT;

    SET @start_time = GETDATE();

    PRINT '===== STARTING SILVER LOAD =====';
    PRINT 'Start Time: ' + CAST(@start_time AS VARCHAR);

    BEGIN TRY

    -------------------------------------------------
    -- CRM CUSTOMER INFO
    -------------------------------------------------
    PRINT 'Loading CRM Customer Info...';

    TRUNCATE TABLE silver.crm_cust_info;

    INSERT INTO silver.crm_cust_info (
        cst_id, cst_key, cst_firstname, cst_lastname,
        cst_marital_status, cst_gndr, cst_create_date
    )
    SELECT 
        cst_id,
        cst_key,
        TRIM(cst_firstname),
        TRIM(cst_lastname),
        CASE 
            WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'SINGLE'
            WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'MARRIED'
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
        ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS rn
        FROM bronze.crm_cust_info
        WHERE cst_id IS NOT NULL
    ) t WHERE rn = 1;

    SELECT @row_count = COUNT(*) FROM silver.crm_cust_info;
    PRINT 'Rows Loaded: ' + CAST(@row_count AS VARCHAR);


    -------------------------------------------------
    -- CRM PRODUCT INFO
    -------------------------------------------------
    PRINT 'Loading CRM Product Info...';

    TRUNCATE TABLE silver.crm_prd_info;

    INSERT INTO silver.crm_prd_info (
        prd_id, cat_id, prd_key, prd_nm,
        prd_cost, prd_line, prd_start_dt, prd_end_dt
    )
    SELECT 
        prd_id,
        REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_'),
        SUBSTRING(prd_key, 7, LEN(prd_key)),
        TRIM(prd_nm),
        ISNULL(prd_cost, 0),
        CASE 
            WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
            WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
            WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
            WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
            ELSE 'n/a'
        END,
        CAST(prd_start_dt AS DATE),
        DATEADD(DAY, -1,
            LEAD(CAST(prd_start_dt AS DATE)) OVER (
                PARTITION BY prd_key ORDER BY prd_start_dt
            )
        )
    FROM bronze.crm_prd_info;

    SELECT @row_count = COUNT(*) FROM silver.crm_prd_info;
    PRINT 'Rows Loaded: ' + CAST(@row_count AS VARCHAR);


    -------------------------------------------------
    -- CRM SALES DETAILS
    -------------------------------------------------
    PRINT 'Loading CRM Sales Details...';

    TRUNCATE TABLE silver.crm_sales_details;

    INSERT INTO silver.crm_sales_details (
        sls_ord_num, sls_prd_key, sls_cust_id,
        sls_order_id, sls_due_dt,
        sls_sales, sls_quantity, sls_price
    )
    SELECT
        TRIM(sls_ord_num),
        TRIM(sls_prd_key),
        sls_cust_id,
        TRY_CAST(sls_ord_num AS INT),
        CASE 
            WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
            ELSE CAST(CAST(sls_due_dt AS VARCHAR(8)) AS DATE)
        END,
        CASE 
            WHEN sls_sales IS NULL 
                 OR sls_sales <= 0 
                 OR sls_sales != sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
        END,
        sls_quantity,
        CASE 
            WHEN sls_price IS NULL OR sls_price <= 0
            THEN sls_sales / NULLIF(sls_quantity, 0)
            ELSE sls_price
        END
    FROM bronze.crm_sales_details;

    SELECT @row_count = COUNT(*) FROM silver.crm_sales_details;
    PRINT 'Rows Loaded: ' + CAST(@row_count AS VARCHAR);


    -------------------------------------------------
    -- ERP LOCATION
    -------------------------------------------------
    PRINT 'Loading ERP Location...';

    TRUNCATE TABLE silver.erp_loc_a101;

    INSERT INTO silver.erp_loc_a101 (cid, cntry)
    SELECT 
        REPLACE(TRIM(cid), '-', ''),
        CASE 
            WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
            WHEN UPPER(TRIM(cntry)) IN ('US', 'USA') THEN 'United States'
            WHEN cntry IS NULL OR TRIM(cntry) = '' THEN 'n/a'
            ELSE TRIM(cntry)
        END
    FROM bronze.erp_loc_a101;

    SELECT @row_count = COUNT(*) FROM silver.erp_loc_a101;
    PRINT 'Rows Loaded: ' + CAST(@row_count AS VARCHAR);


    -------------------------------------------------
    -- ERP CUSTOMER
    -------------------------------------------------
    PRINT 'Loading ERP Customer...';

    TRUNCATE TABLE silver.erp_cust_az12;

    INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
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

    SELECT @row_count = COUNT(*) FROM silver.erp_cust_az12;
    PRINT 'Rows Loaded: ' + CAST(@row_count AS VARCHAR);


    -------------------------------------------------
    -- ERP PRODUCT CATEGORY
    -------------------------------------------------
    PRINT 'Loading ERP Product Category...';

    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    INSERT INTO silver.erp_px_cat_g1v2 (pid, cat, subcat, maintenance)
    SELECT 
        TRIM(pid),
        TRIM(cat),
        TRIM(subcat),
        TRIM(maintenance)
    FROM bronze.erp_prd_p101;

    SELECT @row_count = COUNT(*) FROM silver.erp_px_cat_g1v2;
    PRINT 'Rows Loaded: ' + CAST(@row_count AS VARCHAR);


    -------------------------------------------------
    -- END
    -------------------------------------------------
    SET @end_time = GETDATE();

    PRINT '===== SILVER LOAD COMPLETED =====';
    PRINT 'End Time: ' + CAST(@end_time AS VARCHAR);
    PRINT 'Duration (Seconds): ' + 
          CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR);

    END TRY

    BEGIN CATCH
        PRINT '===== ERROR IN SILVER LOAD =====';
        PRINT ERROR_MESSAGE();
        PRINT ERROR_LINE();
    END CATCH

END;
GO

EXEC silver.load_silver;