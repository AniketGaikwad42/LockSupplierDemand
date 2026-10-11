--Extracts all the sup_id of all the original supplier and change requests sup_id who are one time vendors and Active--
WITH grp_lvl_suppliers AS (
  SELECT 
  DISTINCT slvl.sup_id AS sup_id
  FROM t_sup_supplier_level AS slvl
  WHERE slvl.lvl_code = 'ult'
),

base_suppliers AS (
SELECT 
sup.sup_id AS sup_id
FROM dbo.t_sup_supplier AS sup
WHERE sup._sup_one_time_vendor_z = 1
AND sup._sup_onetime_date_expiration_z IS NOT NULL
AND sup.status_code IN ('val','cri','crt')
AND sup._sup_onetime_date_expiration_z < GETDATE()
AND sup.sup_id NOT IN (
SELECT sup_id FROM grp_lvl_suppliers
)),

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

final_sup_ids AS (
  SELECT base1.sup_id AS sup_id FROM base_suppliers AS base1
  UNION
  SELECT child_sup.sup_id AS sup_id FROM child_suppliers AS child_sup
)
 
UPDATE approv
SET approv.status_code_val = 'pay',
approv.status_code_new = 'pay'
FROM t_sup_approval AS approv
INNER JOIN final_sup_ids AS sup_final ON sup_final.sup_id = approv.sup_id