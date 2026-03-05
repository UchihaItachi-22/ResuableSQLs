WITH mpa_data AS (
    SELECT
        aia.invoice_id as invoice_id,
        aia.invoice_num,
        aila.line_number AS inv_line_number,
        aila.amount AS invoice_line_amount,
        aila.def_acctg_start_date,
        aila.def_acctg_end_date,
        (
			(EXTRACT(YEAR FROM aila.def_acctg_end_date) - EXTRACT(YEAR FROM aila.def_acctg_start_date)) * 12 +
			(EXTRACT(MONTH FROM aila.def_acctg_end_date) - EXTRACT(MONTH FROM aila.def_acctg_start_date)) + 1
		) AS total_mpa_months,
        (aila.amount / (
			(EXTRACT(YEAR FROM aila.def_acctg_end_date) - EXTRACT(YEAR FROM aila.def_acctg_start_date)) * 12 +
			(EXTRACT(MONTH FROM aila.def_acctg_end_date) - EXTRACT(MONTH FROM aila.def_acctg_start_date)) + 1
		)) AS monthly_amortized_value,
        aida.invoice_distribution_id as invoice_distribution_id,
		CASE
			WHEN TO_DATE(:P_FROM_PERIOD, 'YYYY-MM-DD') <= aila.def_acctg_start_date THEN 0
			WHEN TO_DATE(:P_FROM_PERIOD, 'YYYY-MM-DD') > TO_DATE(aila.def_acctg_end_date, 'YYYY-MM-DD') THEN aila.amount
			ELSE
				ROUND(
					(
						(EXTRACT(YEAR FROM TO_DATE(:P_FROM_PERIOD, 'YYYY-MM-DD')) - EXTRACT(YEAR FROM aila.def_acctg_start_date)) * 12 +
						(EXTRACT(MONTH FROM TO_DATE(:P_FROM_PERIOD, 'YYYY-MM-DD')) - EXTRACT(MONTH FROM aila.def_acctg_start_date))
					) *
					(aila.amount / (
									(EXTRACT(YEAR FROM aila.def_acctg_end_date) - EXTRACT(YEAR FROM aila.def_acctg_start_date)) * 12 +
									(EXTRACT(MONTH FROM aila.def_acctg_end_date) - EXTRACT(MONTH FROM aila.def_acctg_start_date)) + 1
								))
				)
		END AS opening
    FROM
        ap_invoices_all aia,
        ap_invoice_lines_all aila,
        ap_invoice_distributions_all aida
    WHERE
        aia.invoice_id = aila.invoice_id
        AND aila.invoice_id = aida.invoice_id
        AND aila.line_number = aida.invoice_line_number
        AND aila.LINE_TYPE_LOOKUP_CODE = 'ITEM'
        AND aida.LINE_TYPE_LOOKUP_CODE = 'ITEM'
),
period_amortization AS (
    SELECT 
        aida.invoice_id,
        aida.invoice_distribution_id,
        SUM(xal.accounted_cr) AS period_balance
    FROM 
        xla_ae_lines xal,
        xla_ae_headers xah,
        xla_events xev,
        ap_invoice_distributions_all aida
    WHERE 
        xal.ae_header_id = xah.ae_header_id
        AND xah.event_id = xev.event_id
        AND xev.event_id = aida.accounting_event_id
        AND xal.accounting_class_code = 'ORA_AP_DEFER_ITEM_EXP'
        AND xev.event_status_code = 'P'
        AND (
            (SELECT start_date 
            FROM gl_periods 
            WHERE period_name = xal.period_name
            AND period_set_name = 'CT Corporate Ca' 
            AND period_name NOT LIKE 'Adj%')
            BETWEEN TO_DATE(:P_FROM_PERIOD, 'YYYY-MM-DD') 
                AND TO_DATE(:P_TO_PERIOD, 'YYYY-MM-DD')
        )
    GROUP BY 
        aida.invoice_id,
        aida.invoice_distribution_id
)

-- Main query starts here
SELECT DISTINCT 
     gl.name AS ledger_name,
     hou.name AS bu_name,
     psv.vendor_name AS supplier_name,
     pssam.vendor_site_code AS supplier_site,
     TO_CHAR(aia.invoice_date, 'DD-MM-YYYY') AS invoice_date,
     TO_CHAR(aia.gl_date, 'DD-MM-YYYY') AS gl_date,
     aia.invoice_id AS invoice_id,
     aia.invoice_num AS invoice_number,
     aia.invoice_currency_code AS currency_code,
     aia.invoice_amount AS invoice_amount,
     aila.line_number AS inv_line_number,
     aila.amount AS invoice_line_amount,
     aila.description AS line_description,
     aida.distribution_line_number AS distribution_line_number,
     aida.amount AS distribution_amount,
     TO_CHAR(aila.def_acctg_start_date, 'DD-MM-YYYY') AS mpa_start_date,
     TO_CHAR(aila.def_acctg_end_date, 'DD-MM-YYYY') AS mpa_end_date,
     ROUND(MONTHS_BETWEEN(TO_DATE(aila.def_acctg_end_date, 'yyyy/mm/dd'),
                          TO_DATE(aila.def_acctg_start_date, 'yyyy/mm/dd') - 1)) AS diff,
	(
    (EXTRACT(YEAR FROM aila.def_acctg_end_date) - EXTRACT(YEAR FROM aila.def_acctg_start_date)) * 12 +
    (EXTRACT(MONTH FROM aila.def_acctg_end_date) - EXTRACT(MONTH FROM aila.def_acctg_start_date)) + 1
) AS diff12,
    (
        SELECT concatenated_segments
        FROM gl_code_combinations
        WHERE code_combination_id = aila.def_acctg_accrual_ccid
    ) AS accrual_account,
    (
        SELECT gl_flexfields_pkg.get_concat_description(chart_of_accounts_id, code_combination_id)
        FROM gl_code_combinations_v
        WHERE code_combination_id = aila.def_acctg_accrual_ccid
    ) AS accrual_account_description,
    (
        SELECT concatenated_segments
        FROM gl_code_combinations
        WHERE code_combination_id = aida.dist_code_combination_id
    ) AS expense_account,
    (
        SELECT gl_flexfields_pkg.get_concat_description(chart_of_accounts_id, code_combination_id)
        FROM gl_code_combinations_v
        WHERE code_combination_id = aida.dist_code_combination_id
    ) AS expense_account_description,
    aia.invoice_currency_code AS invoice_currency_code,
    gl.currency_code AS ledger_currency,
    DECODE(aia.invoice_currency_code, gl.currency_code, 1,
        NVL((SELECT conversion_rate 
            FROM gl_daily_rates 
            WHERE from_currency = aia.invoice_currency_code 
              AND to_currency = gl.currency_code
              AND conversion_date = aila.def_acctg_start_date
              AND conversion_type = 'Corporate'
              AND ROWNUM = 1
        ), 1)
    ) AS conversion_rate,
	mpa_data.opening opening_balance,
    round(NVL(pa.period_balance, 0)) AS period_balance
FROM
    ap_invoices_all aia,
    ap_invoice_lines_all aila,
    ap_invoice_distributions_all aida,
    poz_suppliers_v psv,
    poz_supplier_sites_all_m pssam,
    hz_locations hl,
    hr_operating_units hou,
    gl_ledgers gl,
    xla_transaction_entities xte,
    xla_events xev,
    xla_ae_headers xah,
    xla_ae_lines xal,
    gl_import_references gir,
	mpa_data,
	period_amortization pa
WHERE
    aia.invoice_id = aila.invoice_id
	AND mpa_data.invoice_distribution_id = aida.invoice_distribution_id
	AND mpa_data.invoice_id = aida.invoice_id 
	AND pa.invoice_distribution_id(+) = aida.invoice_distribution_id
	AND pa.invoice_id(+) = aida.invoice_id
    AND aila.invoice_id = aida.invoice_id
    AND aila.line_number = aida.invoice_line_number
	AND aila.LINE_TYPE_LOOKUP_CODE = 'ITEM'
    AND aida.LINE_TYPE_LOOKUP_CODE = 'ITEM'
    AND aia.vendor_id = psv.vendor_id
    AND aia.vendor_site_id = pssam.vendor_site_id
    AND psv.vendor_id = pssam.vendor_id
    AND pssam.location_id = hl.location_id
    AND aia.org_id = hou.organization_id
    AND gl.ledger_id = hou.set_of_books_id
    AND aida.invoice_id = xte.source_id_int_1
    AND xev.event_id = aida.accounting_event_id
    AND xev.event_status_code = 'P'
    AND xah.entity_id = xte.entity_id
    AND xev.event_id = xah.event_id
    AND xal.ae_header_id = xah.ae_header_id
    AND xal.gl_sl_link_id = gir.gl_sl_link_id
    AND gir.gl_sl_link_table = xal.gl_sl_link_table
    AND XTE.ENTITY_CODE = 'AP_INVOICES'
    AND xal.ACCOUNTING_CLASS_CODE IN ('ORA_AP_DEFER_ITEM_EXP')
    AND gl.name = :P_LEDGER_NAME
    AND (hou.name IN (:P_BU_NAME) OR 'All' IN (:P_BU_NAME || 'All'))
    AND (psv.vendor_name IN (:P_VENDOR_NAME) OR 'All' IN (:P_VENDOR_NAME || 'All'))
    AND TO_DATE(aila.def_acctg_start_date,'YYYY-MM-DD') <= TO_DATE(:P_TO_PERIOD, 'YYYY-MM-DD')
	AND TO_DATE(aila.def_acctg_end_date,'YYYY-MM-DD') >= TO_DATE(:P_FROM_PERIOD, 'YYYY-MM-DD')
ORDER BY aia.invoice_num