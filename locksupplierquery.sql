--Extracts all the sup_id of all the original supplier and change requests sup_id who are one time vendors and Active--
SELECT
sup.sup_id AS sup_id,
FROM dbo.t_sup_supplier AS sup
WHERE sup._sup_one_time_vendor_z = 1
AND sup._sup_onetime_date_expiration_z IS NOT NULL
AND sup.status_code = 'val'
AND sup._sup_onetime_date_expiration_z < GETDATE()