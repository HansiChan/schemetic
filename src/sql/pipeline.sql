SET 'execution.runtime-mode' = 'streaming';
SET 'table.dynamic-table-options.enabled' = 'true';
SET 'table.exec.sink.upsert-materialize' = 'NONE';
SET 'pipeline.name' = 'customer_hourly_order_metrics';

SET 'execution.checkpointing.interval' = '10s';
SET 'execution.checkpointing.mode' = 'EXACTLY_ONCE';

CREATE CATALOG ${CATALOG} WITH (
  'type' = 'paimon',
  'warehouse' = '${WAREHOUSE}',
  's3.endpoint' = '${S3_ENDPOINT}',
  's3.access-key' = '${S3_ACCESS_KEY}',
  's3.secret-key' = '${S3_SECRET_KEY}',
  's3.path.style.access' = '${S3_PATH_STYLE}'
);

USE CATALOG ${CATALOG};


CREATE DATABASE IF NOT EXISTS ods_ewallet;
USE ods_ewallet;


CREATE DATABASE IF NOT EXISTS dwd;


CREATE TABLE IF NOT EXISTS dwd.ewallet_outlet_types (
    id                              STRING,
    name                            STRING,
    is_leased_outlet                BOOLEAN,
    is_required_enter_payment       BOOLEAN,
    is_required_pos_reference       BOOLEAN,
    is_cage                         BOOLEAN,
    is_display_patron_photo         BOOLEAN,
    is_e_voucher_redemption         BOOLEAN,
    is_payment                      BOOLEAN,
    is_print_e_voucher_redemption_slip BOOLEAN,
    created_time                    TIMESTAMP(3),
    created_by                      STRING,
    modified_time                   TIMESTAMP(3),
    modified_by                     STRING,
    ods_ingested_at                 TIMESTAMP(3),
    ods_updated_at                  TIMESTAMP(3),
    dwd_create_at                   TIMESTAMP(3),
    dwd_update_at                   TIMESTAMP(3),
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'changelog-producer' = 'input',
    'merge-engine'       = 'deduplicate',
    'bucket'             = '1'
);

INSERT INTO dwd.ewallet_outlet_types
SELECT
    `Id`                            AS id,
    `Name`                          AS name,
    `IsLeasedOutlet`                AS is_leased_outlet,
    `IsRequiredEnterPayment`        AS is_required_enter_payment,
    `IsRequiredPOSReference`        AS is_required_pos_reference,
    `IsCage`                        AS is_cage,
    `IsDisplayPatronPhoto`          AS is_display_patron_photo,
    `IsEVoucherRedemption`          AS is_e_voucher_redemption,
    `IsPayment`                     AS is_payment,
    `IsPrintEVoucherRedemptionSlip` AS is_print_e_voucher_redemption_slip,
    `CreatedTime`                   AS created_time,
    `CreatedBy`                     AS created_by,
    `ModifiedTime`                  AS modified_time,
    `ModifiedBy`                    AS modified_by,
    `ods_ingested_at`               AS ods_ingested_at,
    `ods_updated_at`                AS ods_updated_at,
    CURRENT_TIMESTAMP               AS dwd_create_at,
    CURRENT_TIMESTAMP               AS dwd_update_at
FROM ods_ewallet.`OutletTypes`
WHERE `op` IS NULL OR `op` <> 'd';


CREATE TABLE IF NOT EXISTS dwd.ewallet_outlets (
    id                              STRING,
    name                            STRING,
    is_active                       BOOLEAN,
    code                            STRING,
    outlet_company                  STRING,
    property_id                     STRING,
    remarks                         STRING,
    shop_no                         STRING,
    contract                        STRING,
    payment_term                    STRING,
    segment_id                      STRING,
    vendor_code                     STRING,
    sys_start_time                  TIMESTAMP(3),
    sys_end_time                    TIMESTAMP(3),
    outlet_type_id                  STRING,
    addresses                       STRING,
    comp_revenue_code               STRING,
    company_name                    STRING,
    contact                         STRING,
    contract_effective_date         TIMESTAMP(3),
    contract_expiry_date            TIMESTAMP(3),
    crs_revenue_center_code         STRING,
    emails                          STRING,
    grant_id                        STRING,
    job_title                       STRING,
    payment_method_id               STRING,
    phone                           STRING,
    is_support_shiji                BOOLEAN,
    shiji_outlet_id                 STRING,
    vms_outlet_code                 STRING,
    created_time                    TIMESTAMP(3),
    created_by                      STRING,
    modified_time                   TIMESTAMP(3),
    modified_by                     STRING,
    ods_ingested_at                 TIMESTAMP(3),
    ods_updated_at                  TIMESTAMP(3),
    dwd_create_at                   TIMESTAMP(3),
    dwd_update_at                   TIMESTAMP(3),
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'changelog-producer' = 'input',
    'merge-engine'       = 'deduplicate',
    'bucket'             = '1'
);

INSERT INTO dwd.ewallet_outlets
SELECT
    `Id`                            AS id,
    `Name`                          AS name,
    `IsActive`                      AS is_active,
    `Code`                          AS code,
    `OutletCompany`                 AS outlet_company,
    `PropertyId`                    AS property_id,
    `Remarks`                       AS remarks,
    `ShopNo`                        AS shop_no,
    `Contract`                      AS contract,
    `PaymentTerm`                   AS payment_term,
    `SegmentId`                     AS segment_id,
    `VendorCode`                    AS vendor_code,
    `SysStartTime`                  AS sys_start_time,
    `SysEndTime`                    AS sys_end_time,
    `OutletTypeId`                  AS outlet_type_id,
    `Addresses`                     AS addresses,
    `CompRevenueCode`               AS comp_revenue_code,
    `CompanyName`                   AS company_name,
    `Contact`                       AS contact,
    `ContractEffectiveDate`         AS contract_effective_date,
    `ContractExpiryDate`            AS contract_expiry_date,
    `CrsRevenueCenterCode`          AS crs_revenue_center_code,
    `Emails`                        AS emails,
    `GrantId`                       AS grant_id,
    `JobTitle`                      AS job_title,
    `PaymentMethodId`               AS payment_method_id,
    `Phone`                         AS phone,
    `IsSupportShiji`                AS is_support_shiji,
    `ShijiOutletId`                 AS shiji_outlet_id,
    `VMSOutletCode`                 AS vms_outlet_code,
    `CreatedTime`                   AS created_time,
    `CreatedBy`                     AS created_by,
    `ModifiedTime`                  AS modified_time,
    `ModifiedBy`                    AS modified_by,
    `ods_ingested_at`               AS ods_ingested_at,
    `ods_updated_at`                AS ods_updated_at,
    CURRENT_TIMESTAMP               AS dwd_create_at,
    CURRENT_TIMESTAMP               AS dwd_update_at
FROM ods_ewallet.`Outlets`
WHERE `op` IS NULL OR `op` <> 'd';

CREATE TABLE IF NOT EXISTS dwd.ewallet_payments (
    id                              BIGINT,
    patron_id                       STRING,
    amount                          DECIMAL(38, 10),
    status                          STRING,
    outlet                          STRING,
    pos_reference                   STRING,
    remark                          STRING,
    transaction_type                STRING,
    device_id                       STRING,
    outlet_code                     STRING,
    card_tier                       STRING,
    admin_fee                       DECIMAL(38, 10),
    outlet_property                 STRING,
    outlet_shop_no                  STRING,
    payment_amount                  DECIMAL(38, 10),
    payment_method                  STRING,
    remaining_amount                DECIMAL(38, 10),
    rounding                        DECIMAL(38, 10),
    created_time                    TIMESTAMP(3),
    created_by                      STRING,
    modified_time                   TIMESTAMP(3),
    modified_by                     STRING,
    ods_ingested_at                 TIMESTAMP(3),
    ods_updated_at                  TIMESTAMP(3),
    dwd_create_at                   TIMESTAMP(3),
    dwd_update_at                   TIMESTAMP(3),
    pt_created_date                 STRING,
    PRIMARY KEY (id, pt_created_date) NOT ENFORCED
) PARTITIONED BY (pt_created_date) WITH (
    'changelog-producer' = 'input',
    'merge-engine'       = 'deduplicate',
    'bucket'             = '2'
);

INSERT INTO dwd.ewallet_payments
SELECT
    `Id`                            AS id,
    `PatronId`                      AS patron_id,
    `Amount`                        AS amount,
    `Status`                        AS status,
    `Outlet`                        AS outlet,
    `POSReference`                  AS pos_reference,
    `Remark`                        AS remark,
    `TransactionType`               AS transaction_type,
    `DeviceId`                      AS device_id,
    `OutletCode`                    AS outlet_code,
    `CardTier`                      AS card_tier,
    `AdminFee`                      AS admin_fee,
    `OutletProperty`                AS outlet_property,
    `OutletShopNo`                  AS outlet_shop_no,
    `PaymentAmount`                 AS payment_amount,
    `PaymentMethod`                 AS payment_method,
    `RemainingAmount`               AS remaining_amount,
    `Rounding`                      AS rounding,
    `CreatedTime`                   AS created_time,
    `CreatedBy`                     AS created_by,
    `ModifiedTime`                  AS modified_time,
    `ModifiedBy`                    AS modified_by,
    `ods_ingested_at`               AS ods_ingested_at,
    `ods_updated_at`                AS ods_updated_at,
    CURRENT_TIMESTAMP               AS dwd_create_at,
    CURRENT_TIMESTAMP               AS dwd_update_at,
    `pt_created_date`               AS pt_created_date
FROM ods_ewallet.`Payments`
WHERE `op` IS NULL OR `op` <> 'd';


CREATE TABLE IF NOT EXISTS dwd.ewallet_point_payment_details (
    id                              STRING,
    patron_id                       STRING,
    reward_type                     STRING,
    transaction_type                STRING,
    point                           DECIMAL(38, 10),
    before_point                    DECIMAL(38, 10),
    after_point                     DECIMAL(38, 10),
    remark                          STRING,
    created_time                    TIMESTAMP(3),
    created_by                      STRING,
    modified_time                   TIMESTAMP(3),
    modified_by                     STRING,
    ods_ingested_at                 TIMESTAMP(3),
    ods_updated_at                  TIMESTAMP(3),
    dwd_create_at                   TIMESTAMP(3),
    dwd_update_at                   TIMESTAMP(3),
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'changelog-producer' = 'input',
    'merge-engine'       = 'deduplicate',
    'bucket'             = '1'
);

INSERT INTO dwd.ewallet_point_payment_details
SELECT
    `Id`                            AS id,
    `PatronId`                      AS patron_id,
    `RewardType`                    AS reward_type,
    `TransactionType`               AS transaction_type,
    `Point`                         AS point,
    `BeforePoint`                   AS before_point,
    `AfterPoint`                    AS after_point,
    `Remark`                        AS remark,
    `CreatedTime`                   AS created_time,
    `CreatedBy`                     AS created_by,
    `ModifiedTime`                  AS modified_time,
    `ModifiedBy`                    AS modified_by,
    `ods_ingested_at`               AS ods_ingested_at,
    `ods_updated_at`                AS ods_updated_at,
    CURRENT_TIMESTAMP               AS dwd_create_at,
    CURRENT_TIMESTAMP               AS dwd_update_at
FROM ods_ewallet.`PointPaymentDetails`
WHERE `op` IS NULL OR `op` <> 'd';


CREATE TABLE IF NOT EXISTS dwd.ewallet_properties (
    id                              STRING,
    name                            STRING,
    is_active                       BOOLEAN,
    shiji_iptv_interface_code       STRING,
    shiji_server_url                STRING,
    rs_property                     STRING,
    created_time                    TIMESTAMP(3),
    created_by                      STRING,
    ods_ingested_at                 TIMESTAMP(3),
    ods_updated_at                  TIMESTAMP(3),
    dwd_create_at                   TIMESTAMP(3),
    dwd_update_at                   TIMESTAMP(3),
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'changelog-producer' = 'input',
    'merge-engine'       = 'deduplicate',
    'bucket'             = '1'
);

INSERT INTO dwd.ewallet_properties
SELECT
    `Id`                            AS id,
    `Name`                          AS name,
    `IsActive`                      AS is_active,
    `ShijiIptvInterfaceCode`        AS shiji_iptv_interface_code,
    `ShijiServerUrl`                AS shiji_server_url,
    `RsProperty`                    AS rs_property,
    `CreatedTime`                   AS created_time,
    `CreatedBy`                     AS created_by,
    `ods_ingested_at`               AS ods_ingested_at,
    `ods_updated_at`                AS ods_updated_at,
    CURRENT_TIMESTAMP               AS dwd_create_at,
    CURRENT_TIMESTAMP               AS dwd_update_at
FROM ods_ewallet.`Properties`
WHERE `op` IS NULL OR `op` <> 'd';


CREATE TABLE IF NOT EXISTS dwd.ewallet_segments (
    id                              STRING,
    code                            STRING,
    name                            STRING,
    created_time                    TIMESTAMP(3),
    created_by                      STRING,
    modified_time                   TIMESTAMP(3),
    modified_by                     STRING,
    ods_ingested_at                 TIMESTAMP(3),
    ods_updated_at                  TIMESTAMP(3),
    dwd_create_at                   TIMESTAMP(3),
    dwd_update_at                   TIMESTAMP(3),
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'changelog-producer' = 'input',
    'merge-engine'       = 'deduplicate',
    'bucket'             = '1'
);

INSERT INTO dwd.ewallet_segments
SELECT
    `Id`                            AS id,
    `Code`                          AS code,
    `Name`                          AS name,
    `CreatedTime`                   AS created_time,
    `CreatedBy`                     AS created_by,
    `ModifiedTime`                  AS modified_time,
    `ModifiedBy`                    AS modified_by,
    `ods_ingested_at`               AS ods_ingested_at,
    `ods_updated_at`                AS ods_updated_at,
    CURRENT_TIMESTAMP               AS dwd_create_at,
    CURRENT_TIMESTAMP               AS dwd_update_at
FROM ods_ewallet.`Segments`
WHERE `op` IS NULL OR `op` <> 'd';


CREATE TABLE IF NOT EXISTS dwd.ewallet_transaction_details (
    id                              STRING,
    balance_detail_id               STRING,
    before_detail_balance           DECIMAL(38, 10),
    amount                          DECIMAL(38, 10),
    expiry_date                     TIMESTAMP(3),
    compor_id                       STRING,
    transaction_type                STRING,
    channel                         STRING,
    pos_reference                   STRING,
    outlet                          STRING,
    remark                          STRING,
    payment_detail_id               STRING,
    payment_id                      BIGINT,
    after_detail_balance            DECIMAL(38, 10),
    source_system                   STRING,
    dollar_type_id                  STRING,
    exception_balance               DECIMAL(38, 10),
    patron_id                       STRING,
    source_key                      STRING,
    device_id                       STRING,
    after_balance                   DECIMAL(38, 10),
    before_balance                  DECIMAL(38, 10),
    outlet_code                     STRING,
    property                        STRING,
    display_source_key              STRING,
    source_system_extra_reference   STRING,
    segment_code                    STRING,
    created_time                    TIMESTAMP(3),
    created_by                      STRING,
    ods_ingested_at                 TIMESTAMP(3),
    ods_updated_at                  TIMESTAMP(3),
    dwd_create_at                   TIMESTAMP(3),
    dwd_update_at                   TIMESTAMP(3),
    pt_created_date                 STRING,
    PRIMARY KEY (id, pt_created_date) NOT ENFORCED
) PARTITIONED BY (pt_created_date) WITH (
    'changelog-producer' = 'input',
    'merge-engine'       = 'deduplicate',
    'bucket'             = '2'
);

INSERT INTO dwd.ewallet_transaction_details
SELECT
    `Id`                            AS id,
    `BalanceDetailId`               AS balance_detail_id,
    `BeforeDetailBalance`           AS before_detail_balance,
    `Amount`                        AS amount,
    `ExpiryDate`                    AS expiry_date,
    `ComporId`                      AS compor_id,
    `TransactionType`               AS transaction_type,
    `Channel`                       AS channel,
    `POSReference`                  AS pos_reference,
    `Outlet`                        AS outlet,
    `Remark`                        AS remark,
    `PaymentDetailId`               AS payment_detail_id,
    `PaymentId`                     AS payment_id,
    `AfterDetailBalance`            AS after_detail_balance,
    `SourceSystem`                  AS source_system,
    `DollarTypeId`                  AS dollar_type_id,
    `ExceptionBalance`              AS exception_balance,
    `PatronId`                      AS patron_id,
    `SourceKey`                     AS source_key,
    `DeviceId`                      AS device_id,
    `AfterBalance`                  AS after_balance,
    `BeforeBalance`                 AS before_balance,
    `OutletCode`                    AS outlet_code,
    `Property`                      AS property,
    `DisplaySourceKey`              AS display_source_key,
    `SourceSystemExtraReference`    AS source_system_extra_reference,
    `SegmentCode`                   AS segment_code,
    `CreatedTime`                   AS created_time,
    `CreatedBy`                     AS created_by,
    `ods_ingested_at`               AS ods_ingested_at,
    `ods_updated_at`                AS ods_updated_at,
    CURRENT_TIMESTAMP               AS dwd_create_at,
    CURRENT_TIMESTAMP               AS dwd_update_at,
    `pt_created_date`               AS pt_created_date
FROM ods_ewallet.`TransactionDetails`
WHERE `op` IS NULL OR `op` <> 'd';
