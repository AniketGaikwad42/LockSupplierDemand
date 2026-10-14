--Query to change the site status to "Blocked" once the one-time vendor reaches 180 days since expiry--

/*This CTE will return all the Group Level Suppliers (sup_id) present in the system*/
WITH grp_lvl_suppliers AS (
  SELECT 
  DISTINCT slvl.sup_id AS sup_id
  FROM t_sup_supplier_level AS slvl
  WHERE slvl.lvl_code = 'ult'
),

/*This CTE retrives the sup_id from t_sup_supplier whose one time validity has passed since 180 days*/
base_suppliers AS (
SELECT 
sup.sup_id AS sup_id
FROM dbo.t_sup_supplier AS sup
WHERE sup._sup_one_time_vendor_z = 1
AND sup._sup_onetime_date_expiration_z IS NOT NULL
AND sup.status_code IN ('val','cri','crt')
AND sup._sup_onetime_date_expiration_z < DATEADD(DAY, -180, GETDATE())
AND sup.sup_id NOT IN (
SELECT sup_id FROM grp_lvl_suppliers
)),


/*This Recursive CTE retrives N child suppliers for the suppliers present in base_suppliers CTE*/
child_suppliers AS (
--Level 1
SELECT 
sup1.sup_id AS sup_id
FROM dbo.t_sup_supplier AS sup1
INNER JOIN base_suppliers AS base ON sup1.sup_id_parent = base.sup_id
  
UNION ALL
  
--Level N
SELECT 
child.sup_id AS sup_id
FROM dbo.t_sup_supplier AS child
INNER JOIN child_suppliers AS cs ON child.sup_id_parent = cs.sup_id
),

/*This CTE is used to combine the distinct sup_id from base_suppliers and child_suppliers CTE*/
final_sup_ids AS (
  SELECT base1.sup_id AS sup_id FROM base_suppliers AS base1
  UNION
  SELECT child_sup.sup_id AS sup_id FROM child_suppliers AS child_sup
)

/*Update the Regional status of supplier status to BLOCKED*/
UPDATE approv
SET approv.status_code_val = 'blk',
approv.status_code_new = 'blk'
FROM t_sup_approval AS approv
INNER JOIN final_sup_ids AS sup_final ON sup_final.sup_id = approv.sup_id

/*Udate the reason for closure to One Time Vendor - Validity Expired*/
UPDATE sup
SET sup_upd._creas_code = 'EXP',
sup_upd._sup_closure_reason_comment = 'One Time Vendor - Validity Expired'
FROM t_sup_supplier AS sup_upd 
INNER JOIN final_sup_ids AS final ON final.sup_id = sup_upd.sup_id
