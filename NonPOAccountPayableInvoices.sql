SELECT
    aia.invoice_id,
    aia.invoice_num,
    aia.source,
    aia.invoice_date                                                   invoice_date,
    aia.invoice_currency_code,
    aia.invoice_type_lookup_code,
    psv.vendor_name,
    psv.segment1,
    pssam.vendor_site_code,
    hl.address1
    || ' '
    || hl.address2
    || ' '
    || hl.address3
    || ' '
    || hl.address4
    || ' '
    || hl.county                                                       address,
    hl.city,
    hl.state,
    hl.country,
    hl.postal_code,
    aia.invoice_amount,
    (
        SELECT
            segment1
        FROM
            gl_code_combinations
        WHERE
            code_combination_id = aida.dist_code_combination_id
    )                                                                  bu_name --hou.name
    ,
    (
        SELECT
            name
        FROM
            ap_terms_tl
        WHERE
                term_id = aia.terms_id
            AND language = userenv('LANG')
    )                                                                  terms_name,
    aia.payment_currency_code,
    ( (
        SELECT
            SUM(amount)
        FROM
            ap_invoice_lines_all
        WHERE
                invoice_id = aia.invoice_id
            AND line_type_lookup_code = 'PREPAY'
    ) * ( - 1 ) )                                                      applied_prepayments,
    (
        SELECT
            amount_remaining
        FROM
            ap_payment_schedules_all
        WHERE
            invoice_id = aia.invoice_id
    )                                                                  unpaid_amount,
    CASE
        WHEN EXISTS (
            SELECT
                invoice_id
            FROM
                ap_holds_all
            WHERE
                invoice_id = aia.invoice_id
        )
             OR 'Y' = (
            SELECT DISTINCT
                hold_flag
            FROM
                ap_payment_schedules_all
            WHERE
                    invoice_id = aia.invoice_id
                AND hold_flag = 'Y'
        ) THEN
            'Yes'
        ELSE
            'No'
    END                                                                invoice_holds,
    aia.terms_date                                                     terms_date,
    ( aia.last_update_date ),
    aila.line_number,
    aida.distribution_line_number,
    nvl(aia.voucher_num,
        to_char(aia.doc_sequence_value))                               voucher_id,
    aida.pjc_user_def_attribute1                                       fwo,
    aida.amount,
    nvl(aila.quantity_invoiced, 1)                                     quantity_invoiced,
    decode(aila.quantity_invoiced, NULL, aila.amount, aila.unit_price) unit_price,
    CASE
        WHEN aida.pjc_expenditure_type_id IS NOT NULL THEN
            nvl(aila.description,(psv.vendor_name
                                  || '-'
                                  ||(
                SELECT
                    description
                FROM
                    pjf_exp_types_tl
                WHERE
                    expenditure_type_id = aida.pjc_expenditure_type_id
            )))
        ELSE
            nvl(aila.description,(psv.vendor_name
                                  || '-'
                                  ||(
                SELECT
                    ffv.description
                FROM
                    fnd_flex_value_sets  ffvs, fnd_flex_values_vl   ffv, gl_code_combinations gcc
                WHERE
                        1 = 1
                    AND ffvs.flex_value_set_name = 'PGE_COST_ELEMENT'
                    AND ffvs.flex_value_set_id = ffv.flex_value_set_id
                    AND ffv.enabled_flag = 'Y'
                    AND gcc.segment5 = ffv.flex_value
                    AND gcc.code_combination_id = aida.dist_code_combination_id
            )))
    END                                                                AS description,
    (
        SELECT
            item_number
        FROM
            egp_system_items_b
        WHERE
                inventory_item_id = aila.inventory_item_id
            AND organization_id = (
                SELECT
                    organization_id
                FROM
                    inv_org_parameters
                WHERE
                    organization_code = 'PGE_ITEM_MASTER'
            )
    )                                                                  inventory_item_id,
    nvl(aila.unit_meas_lookup_code, 'EA')                              unit_meas_lookup_code,
    (
        SELECT
            cost_factor_id
        FROM
            ap_invoice_lines_interface
        WHERE
                invoice_id = aia.invoice_id
            AND line_number = aila.line_number
    )                                                                  cost_factor_id,
    sysdate                                                            last_run_date,
    ac.check_id,
    ac.check_date,
    ac.status_lookup_code,
    ac.check_number,
    ac.bank_account_name,
    ac.payment_reference_number,
    (
        SELECT
            meaning
        FROM
            fnd_lookup_values
        WHERE
                lookup_type = 'PAYMENT TYPE'
            AND lookup_code = ac.payment_type_flag
            AND enabled_flag = 'Y'
    )                                                                  payment_type_flag,
    ac.check_amount,
    ac.payment_method_code,
    ac.check_description,
    ac.stopped_date,
    ac.void_date,
    aia.created_by,
    aia.last_updated_by,
    aia.creation_date
FROM
    ap_invoices_all              aia,
    ap_invoice_lines_all         aila,
    ap_invoice_distributions_all aida,
    poz_suppliers_v              psv,
    poz_supplier_sites_all_m     pssam,
    hz_locations                 hl,
    hr_operating_units           hou,
    (
        SELECT
            aipa.invoice_id,
            aca.check_id,
            aca.check_date,
            aca.status_lookup_code,
            aca.check_number,
            aca.bank_account_name,
            iba.payment_reference_number,
            aca.payment_type_flag,
            aca.amount      check_amount,
            aca.payment_method_code,
            aca.description check_description,
            aca.stopped_date,
            aca.void_date
        FROM
            ap_invoice_payments_all aipa,
            ap_checks_all           aca,
            iby_payments_all        iba
        WHERE
                1 = 1
            AND aipa.reversal_inv_pmt_id IS NULL
            AND aipa.check_id = aca.check_id
            AND aca.payment_id = iba.payment_id (+)
    )                            ac
WHERE
        1 = 1
    AND aia.invoice_id = aila.invoice_id
    AND aia.invoice_id = ac.invoice_id (+)
    AND aila.invoice_id = aida.invoice_id
    AND aila.line_number = aida.invoice_line_number
    AND aia.vendor_id = psv.vendor_id
    AND aia.vendor_site_id = pssam.vendor_site_id
    AND psv.vendor_id = pssam.vendor_id
    AND aia.org_id = hou.organization_id
    AND pssam.location_id = hl.location_id
    AND aia.last_update_date >= nvl(TO_DATE(replace(substr(:p_timestamp, 1, 19),
                                                    'T',
                                                    ' '),
        'YYYY-MM-DD HH24:MI:SS'),
                                    aia.last_update_date)
    AND ( aila.po_header_id IS NULL
          OR aila.po_line_id IS NULL
          OR aila.rcv_transaction_id IS NULL )
    AND ( upper(aida.pjc_user_def_attribute1) LIKE 'F%'
          OR upper(aida.pjc_user_def_attribute1) LIKE 'M%' )
    AND ap_invoices_pkg.get_posting_status(aia.invoice_id) = 'Y'
    AND (
        SELECT
            ap_invoices_pkg.get_approval_status(aia.invoice_id, aia.invoice_amount, aia.payment_status_flag, aia.invoice_type_lookup_code
            ) approval_status
        FROM
            dual
    ) = 'APPROVED'
ORDER BY
    2