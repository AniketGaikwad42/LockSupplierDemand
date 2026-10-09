WITH one_time_vendors AS (
SELECT 
sup.sup_id AS sup_id
FROM dbo.t_sup_supplier AS sup WHERE sup._sup_one_time_vendor_z = 1
AND sup.sup_id_from IS NULL
AND sup._sup_onetime_date_expiration_z IS NOT NULL
AND sup.status_code = 'val'
AND sup._sup_onetime_date_expiration_z < GETDATE()
)

SELECT *
FROM dbo.t_sup_approval AS approv
WHERE approv.sup_id IN ( SELECT sup_id FROM one_time_vendors)