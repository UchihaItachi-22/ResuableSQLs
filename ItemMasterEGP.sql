SELECT
-- Item Details
TO_CHAR(SYSDATE,'YYYY-MM-DD') KEY,
esib.inventory_item_id,
esib.organization_id,
esib.primary_uom_code,
esib.item_type,
esib.product_family_item_id,
esib.preprocessing_lead_time,
esib.full_lead_time,
esib.consigned_flag,
esib.inspection_required_flag,
esib.item_number,
esib.item_catalog_group_id,
esib.inventory_item_status_code,
egptl.long_description,
esib.purchasing_enabled_flag purchasable,
ecb.category_code commodity,
esib.list_price_per_unit price,
'USD' currency,
null delivery_instructions,
null item_specifications,
null item_family,
null item_group,
esib.item_number pge_part_number ,
stock_enabled_flag inventory_designation,
esib.minimum_order_quantity,
esib.fixed_lot_multiplier order_increment,
null images,
-- Inventory Organization Details
invorg.organization_code,
--Eff data
(SELECT ffv.description FROM fnd_flex_value_sets ffvs, fnd_flex_values_vl ffv 
 WHERE ffvs.flex_value_set_name = 'MAXIMO_PARENT_CLASS_VS1' 
   AND ffvs.flex_value_set_id = ffv.flex_value_set_id
   AND ffv.flex_value = eib.attribute_char1
   AND ffv.enabled_flag = 'Y'
   AND SYSDATE BETWEEN nvl(ffv.start_date_active,sysdate-1) AND nvl(ffv.end_date_active,sysdate+1)) parent_class,
(SELECT ffv.description FROM fnd_flex_value_sets ffvs, fnd_flex_values_vl ffv 
 WHERE ffvs.flex_value_set_name = 'MAXIMO_CHILD_CLASS_VS1' 
   AND ffvs.flex_value_set_id = ffv.flex_value_set_id
   AND ffv.flex_value = eib.attribute_char2
   AND ffv.enabled_flag = 'Y'
   AND SYSDATE BETWEEN nvl(ffv.start_date_active,sysdate-1) AND nvl(ffv.end_date_active,sysdate+1)) child_class,
-- Perpetual Cost Details
trx_cost.eff_date PC_Effective_Date,
trx_cost.cost_date Cost_Date,
trx_cost.item_number PC_Inventory_Item,
trx_cost.quantity_onhand PC_Quantity_On_hand,
trx_cost.quantity_new PC_New_Quantity,
trx_cost.unit_cost_new PC_New_Unit_Cost, 
trx_cost.avg_cost unit_cost_average,
trx_cost.created_by PC_Created_By,
trx_cost.creation_date PC_Created_Date,
trx_cost.last_update_date PC_Last_Updated_Date,
trx_cost.last_updated_by PC_Last_Update_By,
SYSDATE last_run_date,
esib.creation_date,
esib.last_update_date
FROM 
egp_system_items_b esib,
egp_system_items_tl egptl,
inv_org_parameters invorg,
egp_item_categories eic,
egp_categories_b ecb,
egp_category_sets_b ecsb,
(select * from ego_item_eff_b 
where organization_id = 300000003984053
and context_code = 'Maximo Item Classification') eib,
(SELECT  round(cpc.unit_cost_average,5) avg_cost
       ,esi1.inventory_item_id
       ,esi1.organization_id
       ,cpc.inventory_item_id csc_item_id
       ,cpc.eff_date
       ,cpc.cost_date
       ,esi1.item_number
       ,cpc.quantity_onhand
	   ,cpc.quantity_new
       ,round(cpc.unit_cost_new,5) unit_cost_new
       ,cpc.created_by
       ,cpc.creation_date
       ,max (cpc.last_updated_by) last_updated_by
       ,max (cpc.last_update_date) last_update_date
FROM    egp_system_items_b esi1
       ,cst_perpavg_cost cpc
       ,CST_COST_INV_ORGS ccio
WHERE   1 = 1
AND ccio.cost_org_id = cpc.cost_org_id
AND cpc.val_unit_id = 300000004563734
AND ccio.inv_org_id = esi1.organization_id
AND     cpc.inventory_item_id = esi1.inventory_item_id 
AND     sysdate BETWEEN nvl (cpc.eff_date
                            ,sysdate)
                AND     nvl (cpc.cost_end_date
                            ,sysdate)
GROUP BY esi1.inventory_item_id
,esi1.organization_id
        ,cpc.unit_cost_average
        ,cpc.inventory_item_id
        ,cpc.eff_date
        ,cpc.cost_date
        ,esi1.item_number
        ,cpc.quantity_onhand
		,cpc.quantity_new
        ,cpc.unit_cost_new
        ,cpc.created_by
        ,cpc.creation_date) trx_cost
WHERE 1=1
AND esib.inventory_item_id 					 = egptl.inventory_item_id
AND esib.inventory_item_id     = eib.inventory_item_id(+)
AND esib.organization_id 					 = egptl.organization_id
AND esib.organization_id 					 = invorg.organization_id
AND esib.inventory_item_id 					 = eic.inventory_item_id(+)
AND esib.organization_id 					 = eic.organization_id(+)
AND eic.category_id  						 = ecb.category_id(+)
AND eic.category_set_id 					 = ecsb.category_set_id(+)
AND esib.inventory_item_id 					 = trx_cost.inventory_item_id (+)
AND esib.organization_id 					 = trx_cost.organization_id (+)
AND esib.inventory_item_id 					 = trx_cost.csc_item_id (+)
AND invorg.organization_code in 
('E0010'
,'G0010'
,'G0011'
,'G0020'
,'G0040'
,'G0041'
,'G0042'
,'G0050'
,'G0060'
,'G0070'
,'G0100')
AND esib.last_update_date >= NVL(TO_DATE(REPLACE(SUBSTR(:P_LAST_RUN_DATE,1,19),'T',' '),'YYYY-MM-DD HH24:MI:SS'),esib.last_update_date)