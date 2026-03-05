SELECT
    cmr_po_distribution_id,
    received_qty,
    received_amout,
    received_amout_func_currency,
    invoiced_amt,
    invoice_amt_func_curr,
    invoice_variance_amt_func_curr,
    invoiced_qty,
    uninvoiced_qty,
    uninvoiced_amt,
    sold_to_business_unit_id,
    business_unit_name,
    leger_name,
    func_currency,
    category_code,
    category_name,
    inventory_item_id,
    item_code,
    description,
    deliver_to_inventory_org_id,
    destination_org,
    vendor_id,
    receipt_num,
    receipt_date,
    quantity_shipped,
    quantity_received,
    quantity_delivered,
    quantity_returned,
    quantity_accepted,
    quantity_rejected,
    po_unit_price,
    (quantity_shipped * po_unit_price) shipped_amt,
    (quantity_received * po_unit_price) received_amt,
    (quantity_delivered * po_unit_price) delivered_amt,
    (quantity_returned * po_unit_price) returned_amt,
    (quantity_accepted * po_unit_price) accepted_amt,
    (quantity_rejected * po_unit_price) rejected_amt,
    vendor_name,
    vendor_site_id,
    party_site_name,
    category_id,
    po_number,
    line_number,
    shipment_number,
    distribution_number,
    currency_code,
    line_type,
    po_price,
    price_func_currency,
    amt_func_curr,
    uom_code,
    uom_code1,
    currency_conversion_type,
    currency_conversion_rate,
    currency_conversion_date,
    po_quantity,
    po_amount,
    po_amount_func_currency
FROM (
    SELECT
        b.cmr_po_distribution_id,

        DECODE(b.purchase_basis,'GOODS',
               SUM(NVL(b.source_doc_qty,0)),0) AS received_qty,

        DECODE(b.purchase_basis,'GOODS',
               SUM(NVL(b.source_doc_qty,0)) * b.po_price,
               SUM(NVL(b.transaction_amt,0))) AS received_amout,

        DECODE(b.purchase_basis,'GOODS',
               SUM(NVL(b.source_doc_qty,0)) * b.po_price,
               SUM(NVL(b.transaction_amt,0)))
        * NVL(b.currency_conversion_rate,1) AS received_amout_func_currency,

        SUM(NVL(b.invoiced_amt,0)) AS invoiced_amt,
        SUM(NVL(b.invoice_amt_func_curr,0)) AS invoice_amt_func_curr,
        SUM(NVL(b.invoice_variance_amt_func_curr,0)) AS invoice_variance_amt_func_curr,

        DECODE(b.purchase_basis,'GOODS',
               SUM(NVL(b.invoiced_qty,0)),0) AS invoiced_qty,

        DECODE(b.purchase_basis,'GOODS',
               SUM(NVL(b.source_doc_qty,0)) - SUM(NVL(b.invoiced_qty,0)),0) AS uninvoiced_qty,

        DECODE(b.purchase_basis,'GOODS',
               (SUM(NVL(b.source_doc_qty,0)) * b.po_price) - SUM(NVL(b.invoiced_amt,0)),
               (SUM(NVL(b.transaction_amt,0)) - SUM(NVL(b.invoiced_amt,0)))) AS uninvoiced_amt,

        b.sold_to_business_unit_id,
        fabu.bu_name AS business_unit_name,
        lgr.name AS leger_name,
        lgr.currency_code AS func_currency,
        ecv.category_code,
        ecv.category_name,
        b.inventory_item_id,
        esi.item_number AS item_code,
        NVL(esi.description,b.item_description) AS description,
        b.deliver_to_inventory_org_id,
        iod.organization_name AS destination_org,
        b.vendor_id,

        /* Receipt Number */
        (SELECT MAX(a1.receipt_num)
         FROM rcv_shipment_headers a1,
              rcv_shipment_lines a2
         WHERE a1.shipment_header_id = a2.shipment_header_id
           AND a2.po_line_id = (
               SELECT pla.po_line_id
               FROM po_headers_all pha,
                    po_lines_all pla
               WHERE pha.po_header_id = pla.po_header_id
                 AND pha.segment1 = b.po_number
                 AND pla.line_num = b.line_number
           )
        ) receipt_num,

        /* Receipt Date */
        (SELECT MAX(a1.gl_date)
         FROM rcv_shipment_headers a1,
              rcv_shipment_lines a2
         WHERE a1.shipment_header_id = a2.shipment_header_id
           AND a2.po_line_id = (
               SELECT pla.po_line_id
               FROM po_headers_all pha,
                    po_lines_all pla
               WHERE pha.po_header_id = pla.po_header_id
                 AND pha.segment1 = b.po_number
                 AND pla.line_num = b.line_number
           )
        ) receipt_date,

        /* Quantities */
        (SELECT SUM(a2.quantity_shipped)
         FROM rcv_shipment_lines a2
         WHERE a2.po_line_id IN (
             SELECT pla.po_line_id
             FROM po_headers_all pha,
                  po_lines_all pla
             WHERE pha.po_header_id = pla.po_header_id
               AND pha.segment1 = b.po_number
               AND pla.line_num = b.line_number
         )) quantity_shipped,

        (SELECT SUM(a2.quantity_received)
         FROM rcv_shipment_lines a2
         WHERE a2.po_line_id IN (
             SELECT pla.po_line_id
             FROM po_headers_all pha,
                  po_lines_all pla
             WHERE pha.po_header_id = pla.po_header_id
               AND pha.segment1 = b.po_number
               AND pla.line_num = b.line_number
         )) quantity_received,

        (SELECT SUM(a2.quantity_delivered)
         FROM rcv_shipment_lines a2
         WHERE a2.po_line_id IN (
             SELECT pla.po_line_id
             FROM po_headers_all pha,
                  po_lines_all pla
             WHERE pha.po_header_id = pla.po_header_id
               AND pha.segment1 = b.po_number
               AND pla.line_num = b.line_number
         )) quantity_delivered,

        (SELECT SUM(a2.quantity_returned)
         FROM rcv_shipment_lines a2
         WHERE a2.po_line_id IN (
             SELECT pla.po_line_id
             FROM po_headers_all pha,
                  po_lines_all pla
             WHERE pha.po_header_id = pla.po_header_id
               AND pha.segment1 = b.po_number
               AND pla.line_num = b.line_number
         )) quantity_returned,

        (SELECT SUM(a2.quantity_accepted)
         FROM rcv_shipment_lines a2
         WHERE a2.po_line_id IN (
             SELECT pla.po_line_id
             FROM po_headers_all pha,
                  po_lines_all pla
             WHERE pha.po_header_id = pla.po_header_id
               AND pha.segment1 = b.po_number
               AND pla.line_num = b.line_number
         )) quantity_accepted,

        (SELECT SUM(a2.quantity_rejected)
         FROM rcv_shipment_lines a2
         WHERE a2.po_line_id IN (
             SELECT pla.po_line_id
             FROM po_headers_all pha,
                  po_lines_all pla
             WHERE pha.po_header_id = pla.po_header_id
               AND pha.segment1 = b.po_number
               AND pla.line_num = b.line_number
         )) quantity_rejected,

        /* PO Unit Price */
        (SELECT MAX(unit_price)
         FROM po_lines_all
         WHERE po_line_id = (
             SELECT pla.po_line_id
             FROM po_headers_all pha,
                  po_lines_all pla
             WHERE pha.po_header_id = pla.po_header_id
               AND pha.segment1 = b.po_number
               AND pla.line_num = b.line_number
         )) po_unit_price,

        psv.vendor_name,
        b.vendor_site_id,
        pssv.vendor_site_code AS party_site_name,
        b.category_id,
        b.po_number,
        b.line_number,
        b.shipment_number,
        b.distribution_number,
        b.currency_code,

        DECODE(b.line_type,'GOODS','Goods','SERVICES','Services',b.line_type) AS line_type,

        b.po_price,
        b.po_price * NVL(b.currency_conversion_rate,1) AS price_func_currency,

        DECODE(b.purchase_basis,'SERVICES',
               SUM(NVL(b.transaction_amt,0)) - SUM(NVL(b.invoiced_amt,0)),
               (SUM(NVL(b.source_doc_qty,0)) - SUM(NVL(b.invoiced_qty,0)))
               * NVL(b.po_price,0))
        * NVL(b.currency_conversion_rate,1) AS amt_func_curr,

        uom_master.unit_of_measure AS uom_code,
        b.uom_code AS uom_code1,
        b.currency_conversion_type,
        NVL(b.currency_conversion_rate,1) AS currency_conversion_rate,
        b.currency_conversion_date,

        DECODE(b.purchase_basis,'GOODS',
               b.quantity_ordered - b.quantity_cancelled,0) AS po_quantity,

        DECODE(b.purchase_basis,'GOODS',
               (b.quantity_ordered - b.quantity_cancelled) * NVL(b.po_price,0),
               NVL(b.amount_ordered,0) - NVL(b.amount_cancelled,0)) AS po_amount,

        DECODE(b.purchase_basis,'GOODS',
               (b.quantity_ordered - b.quantity_cancelled) * NVL(b.po_price,0),
               NVL(b.amount_ordered,0) - NVL(b.amount_cancelled,0))
        * NVL(b.currency_conversion_rate,1) AS po_amount_func_currency

    FROM
        cmr_r_uninv_accr_dtls_v b,
        egp_system_items_vl esi,
        egp_categories_vl ecv,
        fun_all_business_units_v fabu,
        inv_organization_definitions_v iod,
        gl_ledgers lgr,
        poz_suppliers_v psv,
        poz_supplier_sites_all_m pssv,
        inv_units_of_measure_vl uom_master,
        hz_party_sites hps
    WHERE 1 = 1
      AND uom_master.uom_code(+) = b.uom_code
      AND b.sold_to_business_unit_id = fabu.bu_id
      AND fabu.primary_ledger_id = lgr.ledger_id
      AND b.inventory_item_id = esi.inventory_item_id(+)
      AND b.deliver_to_inventory_org_id = esi.organization_id(+)
      AND b.category_id = ecv.category_id(+)
      AND b.deliver_to_inventory_org_id = iod.organization_id
      AND b.vendor_id = psv.vendor_id
      AND b.vendor_site_id = pssv.vendor_site_id
      AND hps.party_site_id = pssv.party_site_id
    /*  AND NVL(b.vendor_id,-1) = NVL(:p_vendor_id,NVL(b.vendor_id,-1))
      AND NVL(psv.vendor_name,'X') = NVL(:p_supplier, NVL(psv.vendor_name,'X'))
      AND NVL(hps.party_site_name,'X') =
          NVL(:p_vendor_site_name, NVL(hps.party_site_name,'X')) */
    GROUP BY
        b.cmr_po_distribution_id,
        b.purchase_basis,
        b.po_price,
        b.sold_to_business_unit_id,
        fabu.bu_name,
        lgr.name,
        lgr.currency_code,
        ecv.category_code,
        ecv.category_name,
        b.inventory_item_id,
        esi.item_number,
        esi.description,
        b.item_description,
        b.deliver_to_inventory_org_id,
        iod.organization_name,
        b.vendor_id,
        psv.vendor_name,
        b.vendor_site_id,
        pssv.vendor_site_code,
        b.category_id,
        b.po_number,
        b.line_number,
        b.shipment_number,
        b.distribution_number,
        b.currency_code,
        b.line_type,
        b.uom_code,
        uom_master.unit_of_measure,
        b.currency_conversion_type,
        b.currency_conversion_date,
        b.currency_conversion_rate,
        b.quantity_ordered,
        b.quantity_cancelled,
        b.amount_ordered,
        b.amount_cancelled
);
