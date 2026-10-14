--Query to change the Global status to "Locked" once the one-time vendor reaches 180 days since expiry--

/*This CTE will return all the Group Level Suppliers (sup_id) present in the system*/
WITH grp_lvl_suppliers AS (
  SELECT 
  DISTINCT slvl.sup_id AS sup_id
  FROM t_sup_supplier_level AS slvl
  WHERE slvl.lvl_code = 'ult'
),

/*This CTE retrives the sup_id from t_sup_supplier whose one-time validity has expired 180 days*/
base_suppliers_original AS (
SELECT 
sup.sup_id AS sup_id
FROM dbo.t_sup_supplier AS sup
WHERE sup._sup_one_time_vendor_z = 1
AND sup._sup_onetime_date_expiration_z IS NOT NULL
AND sup.status_code = 'val'
AND sup._sup_onetime_date_expiration_z < DATEADD(DAY, -180, GETDATE())
AND sup.sup_id NOT IN (
SELECT sup_id FROM grp_lvl_suppliers
)),

/*Retrives the sup_id of the N child level suppliers of the suppliers present in base_suppliers CTE*/
child_suppliers AS (
--Level 1
SELECT 
sup1.sup_id AS sup_id
FROM dbo.t_sup_supplier AS sup1
INNER JOIN base_suppliers_original AS base ON sup1.sup_id_parent = base.sup_id
  
UNION ALL
  
--Level N
SELECT 
child.sup_id AS sup_id
FROM dbo.t_sup_supplier AS child
INNER JOIN child_suppliers AS cs ON child.sup_id_parent = cs.sup_id
),

/*Join the data of sup_id from base_suppliers and child_suppliers CTE*/
final_sup_ids AS (
  SELECT base1.sup_id AS sup_id FROM base_suppliers_original AS base1
  UNION
  SELECT child_sup.sup_id AS sup_id FROM child_suppliers AS child_sup
)

/*Update the supplier status_code to LOCKED for the required suppliers*/
UPDATE sup_lock
SET sup_lock.status_code = 'lck'
FROM t_sup_supplier AS sup_lock
INNER JOIN final_sup_ids AS final_sup ON final_sup.sup_id = sup_lock.sup_id
