SELECT
    gl.name                                   ledger_name,
	decode(gjl.status,'P','POSTED','UNPOSTED') gl_status,
    to_char(gjl.effective_date, 'MM/DD/YYYY') account_date,
    gjl.period_name                           period_name,
    gjl.currency_code                         entered_currency,
    gjb.name                                  batch_name,
    gjb.description                           batch_description,
    gjh.name                                  header_name,
    gjh.description                           header_description,
    gcc.segment1
    || '.'
    || gcc.segment2
    || '.'
    || gcc.segment3
    || '.'
    || gcc.segment4
    || '.'
    || gcc.segment5
    || '.'
    || gcc.segment6
    || '.'
    || gcc.segment7                           code_combination,
    gjl.je_line_num                           journal_line_num,
    gjl.description						      line_description,
	xal.description							  subledger_line_description, 
    aca.vendor_name                           vendor_name,
	NULL									transaction_num,
    to_char(aca.check_number)                 payment_num,
    gjl.entered_dr                            journal_entered_debit,
    gjl.entered_cr                            journal_entered_credit,
    xal.entered_dr                            xla_entered_debit,
    xal.entered_cr                            xla_entered_credit,
    je_category,
    gjh.je_source,
	NULL trx_type_code,
	NULL project_name,
	NULL expenditure_type_name,
	NULL asset_description,
	gp.period_year FY,
	gp.quarter_num FQ,
	gp.period_num FN
FROM
    xla_transaction_entities xte,
    xla_ae_headers           xah,
    xla_ae_lines             xal, 
      -- xla_distribution_links xdl, 
    gl_import_references     gir,
    gl_je_lines              gjl,
    gl_je_headers            gjh,
    gl_je_batches            gjb,
    gl_code_combinations     gcc,
    gl_ledgers               gl,
    ap_checks_all            aca,
    xla_events               xe,
	gl_periods				 gp
WHERE
        1 = 1
    AND xte.entity_id = xah.entity_id
    AND xte.entity_code = 'AP_PAYMENTS'
    AND xte.ledger_id = gl.ledger_id
    AND xah.ae_header_id = xal.ae_header_id
    AND xal.gl_sl_link_id = gir.gl_sl_link_id
    AND xal.gl_sl_link_table = gir.gl_sl_link_table
    AND gir.je_header_id = gjl.je_header_id
    AND gir.je_line_num = gjl.je_line_num
    AND gjl.je_header_id = gjh.je_header_id
    AND gjb.je_source = 'Payables'
    AND gjb.je_batch_id = gjh.je_batch_id
    --AND gjl.status = 'P'
    AND xah.application_id = xe.application_id
    AND xah.event_id = xe.event_id
    AND xe.application_id = xte.application_id
    AND xe.entity_id = xte.entity_id
    AND gjl.code_combination_id = gcc.code_combination_id
    AND gjh.ledger_id = gl.ledger_id
    AND xte.source_id_int_1 = aca.check_id
    --AND gjh.status = 'P'
	AND TO_DATE(to_char(gp.end_date,'MM/DD/YYYY'), 'MM/DD/YYYY') = TO_DATE(:p_to_period, 'MM/DD/YYYY')
	AND gp.period_set_name = 'PHI Calendar'
    AND gl.name = :p_ledger
    AND gjl.currency_code = nvl(:p_currency, gjl.currency_code)
    AND ( gjl.effective_date BETWEEN TO_DATE(:p_from_period, 'MM/DD/YYYY') AND TO_DATE(:p_to_period, 'MM/DD/YYYY') )
    AND gcc.segment1 = nvl(:p_company, gcc.segment1)
    AND gcc.segment2 = nvl(:p_location, gcc.segment2)
    AND gcc.segment3 = nvl(:p_cost_centre, gcc.segment3)
    AND gcc.segment4 = nvl(:p_account, gcc.segment4)
    AND gcc.segment5 = nvl(:p_sub_account, gcc.segment5)
    AND gcc.segment6 = nvl(:p_intercompany, gcc.segment6)
    AND gcc.segment7 = nvl(:p_future, gcc.segment7)
--ORDER BY gjl.period_name,gjb.name,gjh.name,gjl.je_line_num
UNION
SELECT
    gl.name                                   ledger_name,
	decode(gjl.status,'P','POSTED','UNPOSTED') gl_status,
    to_char(gjl.effective_date, 'MM/DD/YYYY') account_date,
    gjl.period_name                           period_name,
    gjl.currency_code                         entered_currency,
    gjb.name                                  batch_name,
    gjb.description                           batch_description,
    gjh.name                                  header_name,
    gjh.description                           header_description,
    gcc.segment1
    || '.'
    || gcc.segment2
    || '.'
    || gcc.segment3
    || '.'
    || gcc.segment4
    || '.'
    || gcc.segment5
    || '.'
    || gcc.segment6
    || '.'
    || gcc.segment7                           code_combination,
    gjl.je_line_num                           journal_line_num,
    gjl.description						      line_description,
	xal.description							  subledger_line_description,
    hp.party_name                             vendor_name,
    ap.invoice_num                            transaction_num,
    NULL					                  payment_num,
    gjl.entered_dr                            journal_entered_debit,
    gjl.entered_cr                            journal_entered_credit,
    xal.entered_dr                            xla_entered_debit,
    xal.entered_cr                            xla_entered_credit,
    je_category,
    gjh.je_source,
	NULL trx_type_code,
	NULL project_name,
	NULL expenditure_type_name,
	NULL asset_description,
	gp.period_year FY,
	gp.quarter_num FQ,
	gp.period_num FN
FROM
    xla_transaction_entities xte,
    xla_ae_headers           xah,
    xla_ae_lines             xal, 
              -- xla_distribution_links xdl, 
    gl_import_references     gir,
    gl_je_lines              gjl,
    gl_je_headers            gjh,
    gl_je_batches            gjb,
    gl_code_combinations     gcc,
    gl_ledgers               gl,
    ap_invoices_all          ap, 
             --  poz_suppliers ps, 
    hz_parties               hp,
	gl_periods				 gp 
               --,ap_invoice_lines_all apl 
WHERE
        1 = 1
    AND xte.entity_code IN ( 'AP_INVOICES' )
    AND xte.entity_id = xah.entity_id
    AND xte.ledger_id = gl.ledger_id
    AND xah.ae_header_id = xal.ae_header_id
    AND xal.gl_sl_link_id = gir.gl_sl_link_id
    AND xal.gl_sl_link_table = gir.gl_sl_link_table 
             --  AND xah.ae_header_id = xdl.ae_header_id 
             --  AND xal.ae_line_num = xdl.ae_line_num 
    AND gir.je_header_id = gjl.je_header_id
    AND gir.je_line_num = gjl.je_line_num
    AND gjl.je_header_id = gjh.je_header_id
    AND gjb.je_source = 'Payables'
    AND gjb.je_batch_id = gjh.je_batch_id
    AND gjl.code_combination_id = gcc.code_combination_id
    AND gjh.ledger_id = gl.ledger_id
    AND xte.source_id_int_1 = ap.invoice_id 
             --  AND ap.vendor_id = ps.vendor_id 
             --  AND ps.party_id = hp.party_id 
    AND ap.party_id = hp.party_id
              -- AND ap.invoice_id = apl.invoice_id 
    --AND gjh.status = 'P'
	AND TO_DATE(to_char(gp.end_date,'MM/DD/YYYY'), 'MM/DD/YYYY') = TO_DATE(:p_to_period, 'MM/DD/YYYY')
	AND gp.period_set_name = 'PHI Calendar'
	AND gl.name = :p_ledger
    AND gjl.currency_code = nvl(:p_currency, gjl.currency_code)
    AND ( gjl.effective_date BETWEEN TO_DATE(:p_from_period, 'MM/DD/YYYY') AND TO_DATE(:p_to_period, 'MM/DD/YYYY') )
    AND gcc.segment1 = nvl(:p_company, gcc.segment1)
    AND gcc.segment2 = nvl(:p_location, gcc.segment2)
    AND gcc.segment3 = nvl(:p_cost_centre, gcc.segment3)
    AND gcc.segment4 = nvl(:p_account, gcc.segment4)
    AND gcc.segment5 = nvl(:p_sub_account, gcc.segment5)
    AND gcc.segment6 = nvl(:p_intercompany, gcc.segment6)
    AND gcc.segment7 = nvl(:p_future, gcc.segment7)
UNION
SELECT
    gl.name                                   ledger_name,
	decode(gjl.status,'P','POSTED','UNPOSTED') gl_status,
    to_char(gjl.effective_date, 'MM/DD/YYYY') account_date,
    gjl.period_name                           period_name,
    gjl.currency_code                         entered_currency,
    gjb.name                                  batch_name,
    gjb.description                           batch_description,
    gjh.name                                  header_name,
    gjh.description                           header_description,
    gcc.segment1
    || '.'
    || gcc.segment2
    || '.'
    || gcc.segment3
    || '.'
    || gcc.segment4
    || '.'
    || gcc.segment5
    || '.'
    || gcc.segment6
    || '.'
    || gcc.segment7                           code_combination,
    gjl.je_line_num                           journal_line_num,
    gjl.description						      line_description,
	xal.description							  subledger_line_description,
    NULL                                      vendor_name,
    fab.asset_number                          transaction_num,
	NULL									  payment_num,
    gjl.entered_dr                            journal_entered_debit,
    gjl.entered_cr                            journal_entered_credit,
    xal.entered_dr                            xla_entered_debit,
    xal.entered_cr                            xla_entered_credit,
    je_category,
    gjh.je_source,
	fth.transaction_type_code trx_type_code,
	NULL project_name,
	NULL expenditure_type_name,
	(select a.description from fa_additions_tl a where a.asset_id = fab.asset_id and a.LANGUAGE = 'US') asset_description,
	gp.period_year FY,
	gp.quarter_num FQ,
	gp.period_num FN
FROM
    xla_transaction_entities xte,
    xla_ae_headers           xah,
    xla_ae_lines             xal,
    xla_events               xe,
     --  xla_distribution_links xdl, 
    gl_import_references     gir,
    gl_je_lines              gjl,
    gl_je_headers            gjh,
    gl_je_batches            gjb,
    gl_code_combinations     gcc,
    gl_ledgers               gl, 
       --fa_deprn_summary fds, 
    fa_additions_b           fab,
	fa_transaction_headers fth,
	gl_periods				 gp
       --fa_asset_invoices fai		   
WHERE
        1 = 1 
       --AND xte.entity_code = 'DEPRECIATION'
    AND xte.entity_id = xah.entity_id
    AND xah.application_id = xe.application_id
    AND xe.application_id = xte.application_id
    AND xe.entity_id = xte.entity_id
    AND xah.event_id = xe.event_id
    AND xte.ledger_id = gl.ledger_id
    AND xah.ae_header_id = xal.ae_header_id
    AND xal.gl_sl_link_id = gir.gl_sl_link_id
    AND xal.gl_sl_link_table = gir.gl_sl_link_table 
    --   AND xah.ae_header_id = xdl.ae_header_id 
    --   AND xal.ae_line_num = xdl.ae_line_num 
    AND gir.je_header_id = gjl.je_header_id
    AND gir.je_line_num = gjl.je_line_num
    AND gjl.je_header_id = gjh.je_header_id
    AND gjb.je_source = 'Assets'
    AND gjb.je_batch_id = gjh.je_batch_id
    AND gjl.code_combination_id = gcc.code_combination_id
    AND gjh.ledger_id = gl.ledger_id
    AND xte.source_id_int_1 = fth.transaction_header_id 	--fab.asset_id -- fix by NGM
	AND fth.asset_id = fab.asset_id
       /* AND fds.event_id = xe.event_id
       AND fds.asset_id = fab.asset_id(+)
       AND fab.asset_id = fai.asset_id(+) */
    --AND gjh.status = 'P'
	AND TO_DATE(to_char(gp.end_date,'MM/DD/YYYY'), 'MM/DD/YYYY') = TO_DATE(:p_to_period, 'MM/DD/YYYY')
	AND gp.period_set_name = 'PHI Calendar'
	AND gl.name = :p_ledger
    AND gjl.currency_code = nvl(:p_currency, gjl.currency_code)
    AND ( gjl.effective_date BETWEEN TO_DATE(:p_from_period, 'MM/DD/YYYY') AND TO_DATE(:p_to_period, 'MM/DD/YYYY') )
    AND gcc.segment1 = nvl(:p_company, gcc.segment1)
    AND gcc.segment2 = nvl(:p_location, gcc.segment2)
    AND gcc.segment3 = nvl(:p_cost_centre, gcc.segment3)
    AND gcc.segment4 = nvl(:p_account, gcc.segment4)
    AND gcc.segment5 = nvl(:p_sub_account, gcc.segment5)
    AND gcc.segment6 = nvl(:p_intercompany, gcc.segment6)
    AND gcc.segment7 = nvl(:p_future, gcc.segment7)
UNION
SELECT
    gl.name                                   ledger_name,
	decode(gjl.status,'P','POSTED','UNPOSTED') gl_status,
    to_char(gjl.effective_date, 'MM/DD/YYYY') account_date,
    gjl.period_name                           period_name,
    gjl.currency_code                         entered_currency,
    gjb.name                                  batch_name,
    gjb.description                           batch_description,
    gjh.name                                  header_name,
    gjh.description                           header_description,
    gcc.segment1
    || '.'
    || gcc.segment2
    || '.'
    || gcc.segment3
    || '.'
    || gcc.segment4
    || '.'
    || gcc.segment5
    || '.'
    || gcc.segment6
    || '.'
    || gcc.segment7                           code_combination,
    gjl.je_line_num                           journal_line_num,
    gjl.description						      line_description,
	xal.description							  subledger_line_description,
    NULL                                      vendor_name,
    ppab.segment1                             transaction_num,
	NULL									  payment_num,
    gjl.entered_dr                            journal_entered_debit,
    gjl.entered_cr                            journal_entered_credit,
    xal.entered_dr                            xla_entered_debit,
    xal.entered_cr                            xla_entered_credit
				--,JE_CATEGORY
    ,
    ppet.name                                 je_category,
    gjh.je_source,
	NULL trx_type_code,
	ppat.name project_name,
	(SELECT pett1.expenditure_type_name FROM pjf_exp_types_tl pett1 WHERE pett1.language = 'US' AND pett1.expenditure_type_id = peia.expenditure_type_id) expenditure_type_name,
	NULL asset_description,
	gp.period_year FY,
	gp.quarter_num FQ,
	gp.period_num FN
FROM
	xla_transaction_entities xte,
    xla_ae_headers           xah,
    xla_ae_lines             xal,
    xla_distribution_links   xda,
    pjc_cost_dist_lines_all  pcdl,
    pjf_projects_all_b       ppab,
    pjc_exp_items_all        peia,
    pjf_projects_all_tl      ppat,
    pjf_proj_elements_b      ppeb,
    pjf_proj_elements_tl     ppet,
    gl_import_references     glir,
    gl_je_lines              gjl,
    gl_je_headers            gjh,
    gl_je_batches            gjb,
    gl_ledgers               gl,
    gl_code_combinations     gcc,
	gl_periods				 gp
WHERE
        1 = 1
    AND gjh.ledger_id = gl.ledger_id
    AND xte.ledger_id = gl.ledger_id
    AND gjl.code_combination_id = gcc.code_combination_id
    AND gjh.je_header_id = gjl.je_header_id
    AND gjh.je_source = 'Project Accounting'
    AND gjb.je_batch_id = glir.je_batch_id
    AND glir.je_header_id = gjl.je_header_id
    AND glir.je_line_num = gjl.je_line_num
    AND gjb.je_batch_id = gjh.je_batch_id
    AND xal.gl_sl_link_table = glir.gl_sl_link_table
    AND xal.gl_sl_link_id = glir.gl_sl_link_id
    AND xah.ae_header_id = xal.ae_header_id
    AND xah.entity_id = xte.entity_id
    AND pcdl.acct_event_id = xda.event_id (+)
    AND pcdl.expenditure_item_id = xda.source_distribution_id_num_1 (+)
    AND pcdl.line_num = xda.source_distribution_id_num_2 (+)
    AND xda.ae_header_id = xal.ae_header_id (+)
    AND xda.ae_line_num = xal.ae_line_num (+)
    AND peia.expenditure_item_id = pcdl.expenditure_item_id
    AND peia.project_id = ppab.project_id
    AND ppab.project_id = ppat.project_id
    AND ppab.project_id = ppeb.project_id
    AND ppeb.proj_element_id = ppet.proj_element_id
    --AND gjh.status = 'P'
	AND TO_DATE(to_char(gp.end_date,'MM/DD/YYYY'), 'MM/DD/YYYY') = TO_DATE(:p_to_period, 'MM/DD/YYYY')
	AND gp.period_set_name = 'PHI Calendar'
    AND gl.name = :p_ledger
    AND gjl.currency_code = nvl(:p_currency, gjl.currency_code)
    AND ( gjl.effective_date BETWEEN TO_DATE(:p_from_period, 'MM/DD/YYYY') AND TO_DATE(:p_to_period, 'MM/DD/YYYY') )
    AND gcc.segment1 = nvl(:p_company, gcc.segment1)
    AND gcc.segment2 = nvl(:p_location, gcc.segment2)
    AND gcc.segment3 = nvl(:p_cost_centre, gcc.segment3)
    AND gcc.segment4 = nvl(:p_account, gcc.segment4)
    AND gcc.segment5 = nvl(:p_sub_account, gcc.segment5)
    AND gcc.segment6 = nvl(:p_intercompany, gcc.segment6)
    AND gcc.segment7 = nvl(:p_future, gcc.segment7)
UNION	
--Manual Entries block	Added by NGM
SELECT
    gl.name                                   ledger_name,
	decode(gjl.status,'P','POSTED','UNPOSTED') gl_status,
    to_char(gjl.effective_date, 'MM/DD/YYYY') account_date,
    gjl.period_name                           period_name,
    gjl.currency_code                         entered_currency,
    gjb.name                                  batch_name,
    gjb.description                           batch_description,
    gjh.name                                  header_name,
    gjh.description                           header_description,
    gcc.segment1
    || '.'
    || gcc.segment2
    || '.'
    || gcc.segment3
    || '.'
    || gcc.segment4
    || '.'
    || gcc.segment5
    || '.'
    || gcc.segment6
    || '.'
    || gcc.segment7                           code_combination,
    gjl.je_line_num                           journal_line_num,
    gjl.description                           line_description,
	NULL			  						  subledger_line_description,
    NULL                                      vendor_name,
    NULL                                      transaction_num,
	NULL									  payment_num,
    gjl.entered_dr                            journal_entered_debit,
    gjl.entered_cr                            journal_entered_credit,
    NULL                                      xla_entered_debit,
    NULL                                      xla_entered_credit,
    je_category,
    gjh.je_source,
	NULL trx_type_code,
	NULL project_name,
	NULL expenditure_type_name,
	NULL asset_description,
	gp.period_year FY,
	gp.quarter_num FQ,
	gp.period_num FN
FROM
    gl_je_lines          gjl,
    gl_je_headers        gjh,
    gl_je_batches        gjb,
    gl_code_combinations gcc,
    gl_ledgers           gl,
	gl_periods				 gp
WHERE
        1 = 1
    AND gjl.je_header_id = gjh.je_header_id
    AND gjb.je_source IN ( 'Manual', 'Spreadsheet' )
    AND gjb.je_batch_id = gjh.je_batch_id
    AND gjl.status = 'P'
    AND gjl.code_combination_id = gcc.code_combination_id
    AND gjh.ledger_id = gl.ledger_id
    --AND gjh.status = 'P'
	AND TO_DATE(to_char(gp.end_date,'MM/DD/YYYY'), 'MM/DD/YYYY') = TO_DATE(:p_to_period, 'MM/DD/YYYY')
	AND gp.period_set_name = 'PHI Calendar'
    AND gl.name = :p_ledger
    AND gjl.currency_code = nvl(:p_currency, gjl.currency_code)
    AND ( gjl.effective_date BETWEEN TO_DATE(:p_from_period, 'MM/DD/YYYY') AND TO_DATE(:p_to_period, 'MM/DD/YYYY') )
    AND gcc.segment1 = nvl(:p_company, gcc.segment1)
    AND gcc.segment2 = nvl(:p_location, gcc.segment2)
    AND gcc.segment3 = nvl(:p_cost_centre, gcc.segment3)
    AND gcc.segment4 = nvl(:p_account, gcc.segment4)
    AND gcc.segment5 = nvl(:p_sub_account, gcc.segment5)
    AND gcc.segment6 = nvl(:p_intercompany, gcc.segment6)
    AND gcc.segment7 = nvl(:p_future, gcc.segment7)
UNION	
--Receipt Accounting block Added by NGM
SELECT
    gl.name                                   ledger_name,
	decode(gjl.status,'P','POSTED','UNPOSTED') gl_status,
    to_char(gjl.effective_date, 'MM/DD/YYYY') account_date,
    gjl.period_name                           period_name,
    gjl.currency_code                         entered_currency,
    gjb.name                                  batch_name,
    gjb.description                           batch_description,
    gjh.name                                  header_name,
    gjh.description                           header_description,
    gcc.segment1
    || '.'
    || gcc.segment2
    || '.'
    || gcc.segment3
    || '.'
    || gcc.segment4
    || '.'
    || gcc.segment5
    || '.'
    || gcc.segment6
    || '.'
    || gcc.segment7                           code_combination,
    gjl.je_line_num                           journal_line_num,
    gjl.description                           line_description,
	xal.description			  				  subledger_line_description,
    (SELECT vendor_name FROM poz_suppliers_v WHERE vendor_id = 
	(select vendor_id from cmr_purchase_order_dtls where CMR_PO_DISTRIBUTION_ID = cmre.CMR_PO_DISTRIBUTION_ID and active_flag = 'Y')) vendor_name,
    (SELECT segment1 FROM po_headers_all WHERE po_header_id = 
	(select po_header_id from cmr_purchase_order_dtls where CMR_PO_DISTRIBUTION_ID = cmre.CMR_PO_DISTRIBUTION_ID and active_flag = 'Y')) transaction_num,
	cmrt.Receipt_number						  payment_num,
    gjl.entered_dr                            journal_entered_debit,
    gjl.entered_cr                            journal_entered_credit,
    xal.entered_dr                            xla_entered_debit,
    xal.entered_cr                            xla_entered_credit,
    je_category,
    gjh.je_source,
	NULL trx_type_code,
	NULL project_name,
	NULL expenditure_type_name,
	NULL asset_description,
	gp.period_year FY,
	gp.quarter_num FQ,
	gp.period_num FN
FROM   xla_transaction_entities xte, 
       xla_ae_headers xah, 
       xla_ae_lines xal, 
   --  xla_distribution_links xdl, 
       gl_import_references gir, 
       gl_je_lines gjl, 
       gl_je_headers gjh, 
       gl_je_batches gjb, 
       gl_code_combinations gcc, 
       gl_ledgers gl, 
       xla_events xlae, 
       cmr_rcv_distributions crd,
       cmr_rcv_events cmre,
	   cmr_rcv_transactions cmrt,
	   gl_periods		    gp			   
   --  cmr_purchase_order_dtls cmrd	
    -- poz_suppliers_v poz			   
WHERE  1 = 1 
       AND xte.ledger_id = gl.ledger_id 
       AND xah.ae_header_id = xal.ae_header_id 
       AND xal.application_id = xah.application_id 
       AND xal.gl_sl_link_id = gir.gl_sl_link_id 
       AND xal.gl_sl_link_table = gir.gl_sl_link_table 
    --   AND xah.ae_header_id = xdl.ae_header_id 
    --   AND xal.ae_line_num = xdl.ae_line_num 
       AND gir.je_header_id = gjl.je_header_id 
       AND gir.je_line_num = gjl.je_line_num 
       AND gjl.je_header_id = gjh.je_header_id 
       AND gjb.je_source = 'Receipt Accounting' 
       AND gjb.je_batch_id = gjh.je_batch_id 
       AND gjl.code_combination_id = gcc.code_combination_id 
       AND gjh.ledger_id = gl.ledger_id 
       AND xah.application_id = xlae.application_id 
       AND xah.event_id = xlae.event_id 
       AND xlae.application_id = xte.application_id 
       AND xlae.entity_id = xte.entity_id 
       AND xte.source_id_int_1 = crd.cmr_sub_ledger_id
       AND crd.accounting_event_id = cmre.accounting_event_id
	   --AND xah.event_id = cmre.event_id
	   AND cmre.cmr_rcv_transaction_id = cmrt.cmr_rcv_transaction_id
	   AND TO_DATE(to_char(gp.end_date,'MM/DD/YYYY'), 'MM/DD/YYYY') = TO_DATE(:p_to_period, 'MM/DD/YYYY')
	   AND gp.period_set_name = 'PHI Calendar'
       AND gl.name = :p_ledger
       AND gjl.currency_code = nvl(:p_currency, gjl.currency_code)
       AND ( gjl.effective_date BETWEEN TO_DATE(:p_from_period, 'MM/DD/YYYY') AND TO_DATE(:p_to_period, 'MM/DD/YYYY') )
       AND gcc.segment1 = nvl(:p_company, gcc.segment1)
       AND gcc.segment2 = nvl(:p_location, gcc.segment2)
       AND gcc.segment3 = nvl(:p_cost_centre, gcc.segment3)
       AND gcc.segment4 = nvl(:p_account, gcc.segment4)
       AND gcc.segment5 = nvl(:p_sub_account, gcc.segment5)
       AND gcc.segment6 = nvl(:p_intercompany, gcc.segment6)
       AND gcc.segment7 = nvl(:p_future, gcc.segment7)	
ORDER BY
    period_name,
    batch_name,
    header_name,
    journal_line_num