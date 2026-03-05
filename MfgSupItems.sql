SELECT  partyusageassignmentpeo.party_usage_code
       ,decode (partyusageassignmentpeo.party_usage_code
               ,'MANUFACTURER'
               ,partypeo.party_id
               ,NULL) manufacturer_id
       ,decode (partyusageassignmentpeo.party_usage_code
               ,'MANUFACTURER'
               ,partypeo.party_number
               ,NULL) manufacturer_number
       ,decode (partyusageassignmentpeo.party_usage_code
               ,'MANUFACTURER'
               ,partypeo.party_name
               ,NULL) manufacturer_name
	   ,decode (partyusageassignmentpeo.party_usage_code
               ,'MANUFACTURER'
               ,partypeo.comments
               ,NULL) manufacturer_description
	   ,decode (partyusageassignmentpeo.party_usage_code
               ,'MANUFACTURER'
               ,partypeo.last_update_date
               ,NULL) manufacturer_last_update_date
       ,ps.vendor_id supplier_id
       ,ps.segment1 supplier_number
       ,ps.vendor_name supplier_name
	   ,decode (partyusageassignmentpeo.party_usage_code
               ,'SUPPLIER'
               ,(SELECT meaning 
					FROM fnd_lookup_values 
					WHERE lookup_code  = a.status_code
					  AND lookup_type  = 'ORA_ACA_AML_STATUS'
					  AND enabled_flag = 'Y'
					  AND SYSDATE BETWEEN start_date_active and NVL(end_date_active,SYSDATE))
               ,NULL) preferred_supplier_flag
       ,c.tp_item_id mfg_sup_item_id
       ,c.tp_item_number mfg_sup_item_number
       ,c.tp_item_desc mfg_sup_item_desc
       ,b.item_number
       ,b.inventory_item_id
       ,a.item_relationship_id
       ,partyusageassignmentpeo.effective_start_date start_date
       ,partyusageassignmentpeo.effective_end_date end_date,
TO_CHAR(SYSDATE,'YYYY-MM-DD') KEY,
c.creation_date,
c.created_by,
c.last_updated_by,
c.last_update_date
FROM    hz_parties partypeo
       ,hz_party_usg_assignments partyusageassignmentpeo
       ,egp_item_relationships_b a
       ,egp_system_items_b b
       ,egp_trading_partner_items c
       ,poz_suppliers_v ps
WHERE   partypeo.party_id = partyusageassignmentpeo.party_id
AND     partypeo.party_id = ps.party_id (+)
AND     partyusageassignmentpeo.status_flag = 'A'
AND     partyusageassignmentpeo.party_usage_code IN ('MANUFACTURER','SUPPLIER')
AND     partypeo.party_id = c.trading_partner_id
AND     a.tp_item_id = c.tp_item_id
AND     a.inventory_item_id = b.inventory_item_id
AND     a.master_organization_id = b.organization_id
AND b.last_update_date >= NVL(TO_DATE(REPLACE(SUBSTR(:P_LAST_RUN_DATE,1,19),'T',' '),'YYYY-MM-DD HH24:MI:SS'),b.last_update_date)