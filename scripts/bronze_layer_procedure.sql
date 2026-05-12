-- CREATE STORED PROCEDURE
USE DataWarehouse;
GO

IF OBJECT_ID('bronze.load_bronze', 'P') IS NOT NULL
    DROP PROCEDURE bronze.load_bronze;
GO

CREATE PROCEDURE bronze.load_bronze
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @start_time DATETIME,
        @end_time DATETIME,
        @row_count INT;

    SET @start_time = GETDATE();

    PRINT '===== STARTING BRONZE LOAD =====';
    PRINT 'Start Time: ' + CAST(@start_time AS VARCHAR);

    BEGIN TRY
        
        -------------------------------------------------
        -- CRM CUSTOMER INFO
        -------------------------------------------------
        PRINT 'Loading CRM Customer Info...';

        TRUNCATE TABLE bronze.crm_cust_info;

        BULK INSERT bronze.crm_cust_info
        FROM 'C:\DataWarehouseProject\Datasets\source_crm\cust_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );

        SELECT @row_count = COUNT(*) FROM bronze.crm_cust_info;
        PRINT 'Rows Loaded: ' + CAST(@row_count AS VARCHAR);

        -------------------------------------------------
        -- CRM PRODUCT INFO
        -------------------------------------------------
        PRINT 'Loading CRM Product Info...';

        TRUNCATE TABLE bronze.crm_prd_info;

        BULK INSERT bronze.crm_prd_info
        FROM 'C:\DataWarehouseProject\Datasets\source_crm\prd_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );

        SELECT @row_count = COUNT(*) FROM bronze.crm_prd_info;
        PRINT 'Rows Loaded: ' + CAST(@row_count AS VARCHAR);


        -------------------------------------------------
        -- CRM SALES DETAILS
        -------------------------------------------------
        PRINT 'Loading CRM Sales Details...';

        TRUNCATE TABLE bronze.crm_sales_details;

        BULK INSERT bronze.crm_sales_details
        FROM 'C:\DataWarehouseProject\Datasets\source_crm\sales_details.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );

        SELECT @row_count = COUNT(*) FROM bronze.crm_sales_details;
        PRINT 'Rows Loaded: ' + CAST(@row_count AS VARCHAR);


        -------------------------------------------------
        -- ERP CUSTOMER
        -------------------------------------------------
        PRINT 'Loading ERP Customer...';

        TRUNCATE TABLE bronze.erp_cust_az12;

        BULK INSERT bronze.erp_cust_az12
        FROM 'C:\DataWarehouseProject\Datasets\source_erp\cust_az12.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );

        SELECT @row_count = COUNT(*) FROM bronze.erp_cust_az12;
        PRINT 'Rows Loaded: ' + CAST(@row_count AS VARCHAR);


        -------------------------------------------------
        -- ERP LOCATION
        -------------------------------------------------
        PRINT 'Loading ERP Location...';

        TRUNCATE TABLE bronze.erp_loc_a101;

        BULK INSERT bronze.erp_loc_a101
        FROM 'C:\DataWarehouseProject\Datasets\source_erp\loc_a101.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );

        SELECT @row_count = COUNT(*) FROM bronze.erp_loc_a101;
        PRINT 'Rows Loaded: ' + CAST(@row_count AS VARCHAR);


        -------------------------------------------------
        -- ERP PRODUCT
        -------------------------------------------------
        PRINT 'Loading ERP Product...';

        TRUNCATE TABLE bronze.erp_prd_p101;

        BULK INSERT bronze.erp_prd_p101
        FROM 'C:\DataWarehouseProject\Datasets\source_erp\PX_CAT_G1V2.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );

        SELECT @row_count = COUNT(*) FROM bronze.erp_prd_p101;
        PRINT 'Rows Loaded: ' + CAST(@row_count AS VARCHAR);


        -------------------------------------------------
        -- END TIME
        -------------------------------------------------
        SET @end_time = GETDATE();

        PRINT '===== LOAD COMPLETED SUCCESSFULLY =====';
        PRINT 'End Time: ' + CAST(@end_time AS VARCHAR);

        PRINT 'Duration (Seconds): ' + 
              CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR);

    END TRY

    BEGIN CATCH

        PRINT '===== ERROR IN LOAD =====';
        PRINT 'Error: ' + ERROR_MESSAGE();
        PRINT 'Line: ' + CAST(ERROR_LINE() AS VARCHAR);

    END CATCH

END;
GO

EXEC bronze.load_bronze;