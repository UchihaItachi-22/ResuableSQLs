SELECT  iop.organization_code
	   ,iop.organization_id
       ,esi.item_number
       ,esi.inventory_item_id
       ,ioqd.subinventory_code
       ,iil.segment1
       ,iil.segment2
       ,iil.segment3
       ,iil.segment4
       ,esi.inventory_item_status_code item_status
       ,sum (ioqd.transaction_quantity) on_hand_qty
       ,(sum (ioqd.transaction_quantity) - sum (nvl (ir.primary_reservation_quantity
                 ,0))) available_qty
       ,uomt.unit_of_measure uom
       ,to_char (max (ioqd.last_update_date)
                ,'DD-MM-YYYY') last_update_date
       ,max (ioqd.last_updated_by) last_updated_by
       ,round(trx_cost.avg_cost,5)
       ,sysdate last_run_date
FROM    inv_onhand_quantities_detail ioqd
       ,egp_system_items esi
       ,inv_org_parameters iop
       ,inv_units_of_measure_tl uomt
       ,inv_units_of_measure_b uomb
       ,inv_item_locations iil
       ,inv_reservations ir
       ,
        (
        SELECT  (cpc.unit_cost_average) avg_cost
               ,esi1.inventory_item_id
               ,c.inventory_org_id
               ,cpc.inventory_item_id csc_item_id
        FROM    cst_onhand_v a
               ,cst_item_cost_history_v b
               ,cst_costed_del_attr_onhand_v c
               ,egp_system_items_b esi1
               ,cst_perpavg_cost cpc
        WHERE   1 = 1
        AND     a.rec_trxn_id = b.transaction_id
        AND     b.val_unit_id = cpc.val_unit_id
        AND     cpc.inventory_item_id = a.inventory_item_id
        AND     a.inventory_item_id = b.inventory_item_id
        AND     esi1.inventory_item_id = a.inventory_item_id
        AND     sysdate BETWEEN nvl (cpc.eff_date
                                    ,sysdate)
                        AND     nvl (cpc.cost_end_date
                                    ,sysdate)
        AND     a.rec_trxn_id = c.rec_trxn_id
        AND     b.val_unit_id = c.val_unit_id
        AND     a.rec_trxn_id = cpc.transaction_id
        GROUP BY esi1.inventory_item_id
                ,cpc.unit_cost_average
                ,c.inventory_org_id
                ,cpc.inventory_item_id
        ) trx_cost
WHERE   1 = 1
AND     ioqd.inventory_item_id = esi.inventory_item_id
AND     ioqd.organization_id = esi.organization_id
AND     esi.organization_id = iop.organization_id
AND     uomt.unit_of_measure_id = uomb.unit_of_measure_id
AND     uomb.uom_code = ioqd.transaction_uom_code
AND     ir.inventory_item_id (+) = esi.inventory_item_id
AND     ir.organization_id (+) = esi.organization_id
AND     ioqd.organization_id = iil.organization_id (+)
AND     ioqd.subinventory_code = iil.subinventory_code (+)
AND     ioqd.locator_id = iil.inventory_location_id (+)
AND     ioqd.inventory_item_id = trx_cost.inventory_item_id (+)
AND     ioqd.organization_id = trx_cost.inventory_org_id (+)
AND     ioqd.inventory_item_id = trx_cost.csc_item_id (+)
GROUP BY iop.organization_code
        ,iop.organization_id
        ,esi.item_number
        ,esi.inventory_item_id
        ,ioqd.subinventory_code
        ,iil.segment1
        ,iil.segment2
        ,iil.segment3
        ,iil.segment4
        ,esi.inventory_item_status_code
        ,uomt.unit_of_measure
        ,trx_cost.avg_cost
ORDER BY 1
        ,3;