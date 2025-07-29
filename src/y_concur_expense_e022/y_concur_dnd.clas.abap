CLASS y_concur_dnd DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS Y_CONCUR_DND IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

*    DELETE FROM yexp_entry_e022.
*    DELETE FROM yexp_entry_ed22.
*    DELETE FROM yexp_report_e022.
*    DELETE FROM yexp_report_ed22.
*    DELETE FROM yexp_get_e022.
*    DELETE FROM zyexp_get_e022_d.

***    DATA(CreatedOn) = '2022-02-18T14:20:19.963'.
***    CreatedOn       = CreatedOn+0(10).
***    REPLACE ALL OCCURRENCES OF `-` IN CreatedOn WITH ``.
***    OUT->WRITE( CreatedOn ).
**
***    SELECT SINGLE * FROM yexp_get_e022 WHERE z_task_uuid = '5B082B7721831EEF88B2B6FE725F5270' INTO @DATA(lwa_yexp_get_e022).
**
***    DATA(raw_from) = lwa_yexp_get_e022-z_filter_from.
***    DATA(raw_to)   = lwa_yexp_get_e022-z_filter_to.
***    DATA(converted_from) = raw_from+0(4) && '-' && raw_from+4(2) && '-' && raw_from+6(2).
***    DATA(converted_to) = raw_to+0(4) && '-' && raw_to+4(2) && '-' && raw_to+6(2).
***
**
****************************Tasks*************************************
**
*   GET TIME STAMP FIELD DATA(lv_timestamp).
*   DATA lv_subrc TYPE i.
**   DATA(lv_task_uuid) = cl_system_uuid=>create_uuid_x16_static( ).
**
**   DATA(ls_task) = VALUE yexp_get_e022(
**    z_task_uuid                = lv_task_uuid
**    z_task_id                  = 'Task-1'
**    z_filter_by                = 'Report Date'
**    z_filter_from              = '20240101'
**    z_filter_to                = '20240501'
**    z_report_id                = '54F0C66E9D324AD2B61C'
**    z_task_status              = 'Reports Retrieved From Concur'
**    z_task_process_step        = '00'
**    z_created_by               = sy-uname
**    z_created_at               = lv_timestamp
**    z_last_changed_by          = sy-uname
**    z_last_changed_at          = lv_timestamp
**    z_local_last_changed_at    = lv_timestamp
**    ).
**
**    INSERT yexp_get_e022 FROM @ls_task.
**    lv_subrc = sy-subrc.
**    COMMIT WORK.
**
****************************Reports*************************************
*
*  DATA(lv_report_id) = 'F30453FB05114A389301'.
*  DATA(lv_report_uuid) = cl_system_uuid=>create_uuid_x16_static( ).
**
**  DATA(ls_expense_report) = VALUE yexp_report_e022(
**    z_report_uuid               = lv_report_uuid
**    z_report_id                 = lv_report_id
**    z_task_uuid                 = lv_task_uuid
**    z_report_name               = 'April Expenses (04/01/2022)'
**    z_report_createdon          = '20240601'
**    z_report_lastchangedon      = '20240601'
**    z_report_submittedon        = '20240601'
**    z_owner_id                  = 'ana.mata@tentamus.com'
**    z_owner_name                = 'Ana Mata'
**    z_report_approvalcode       = 'A_ACCO'
**    z_report_approvalname       = 'Approved & In Accounting Review'
**    z_transaction_currency      = 'USD'
**    z_total_amt                 = '8401.22000000'
**    z_total_claimed_amt         = '8401.22000000'
**    z_created_by                = sy-uname
**    z_created_at                = lv_timestamp
**    z_last_changed_by           = sy-uname
**    z_last_changed_at           = lv_timestamp
**    z_local_last_changed_at     = lv_timestamp
**                              ).
**    INSERT yexp_report_e022 FROM @ls_expense_report.
**    lv_subrc = sy-subrc.
**    COMMIT WORK.
**
****************************Entries*************************************
*
*    DATA(lv_transaction_date) = '2024-04-03T00:00:00'.
*    lv_transaction_date = lv_transaction_date+0(10).
*    REPLACE ALL OCCURRENCES OF `-` IN lv_transaction_date WITH ``.
*
*    DATA(lv_lastmodified_date) = '2024-05-01T13:11:41'.
*    lv_lastmodified_date = lv_lastmodified_date+0(10).
*    REPLACE ALL OCCURRENCES OF `-` IN lv_lastmodified_date WITH ``.
*
*    DATA(DATA_V) = 'null'.
*
*    DATA(ls_yexp_entry_e022) = VALUE yexp_entry_e022(
*      z_entry_uuid               = cl_system_uuid=>create_uuid_x16_static( )
*      z_report_uuid              = lv_report_uuid
*      z_report_id                = 'F30453FB05114A389301'
*      z_entry_id                 = 'gWpAwUO$ph9hp1ko9NdYMl$sSL9GeMRnDxgEw'
*      z_entry_status             = 'In Preparation'
*      z_entry_description        = DATA_V
*      z_entry_typecode           = 'BANKF'
*      z_entry_typename           = 'Bank Fees'
*      z_entry_spend_categorycode = 'FEESD'
*      z_entry_spend_categoryname = 'Fees/Dues'
*      z_entry_transaction_date   = lv_transaction_date
*      z_entry_transaction_curr   = 'USD'
*      z_entry_transaction_amt    = '2.65'
*      z_entry_approved_amt       = '2.65'
*      z_entry_last_modified      = lv_lastmodified_date
*      z_entry_vendor_description = 'INTERNATIONAL TRANSACTION'
*      z_created_by               = sy-uname
*      z_created_at               = lv_timestamp
*      z_last_changed_by          = sy-uname
*      z_last_changed_at          = lv_timestamp
*      z_local_last_changed_at    = lv_timestamp
*    ).
*
*    INSERT yexp_entry_e022 FROM @ls_yexp_entry_e022.
*    lv_subrc = sy-subrc.
*    COMMIT WORK.
*
*
**    DATA ls_invoice TYPE STRUCTURE FOR ACTION IMPORT i_supplierinvoicetp~create.
**    DATA lt_invoice TYPE TABLE FOR ACTION IMPORT i_supplierinvoicetp~create.
**
**    TRY.
**        DATA(lv_cid) = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ).
**      CATCH cx_uuid_error.
**    ENDTRY.
**
**    ls_invoice-%cid = lv_cid.
**    ls_invoice-%param-supplierinvoiceiscreditmemo = abap_false.
**    ls_invoice-%param-companycode = '4710'.
**    ls_invoice-%param-invoicingparty = '0001000030'.
**    ls_invoice-%param-postingdate = '20240611'.
**    ls_invoice-%param-documentdate = '20240611'.
**    ls_invoice-%param-documentcurrency = 'ILS'.
**    ls_invoice-%param-invoicegrossamount = 100.
**    ls_invoice-%param-taxdeterminationdate = '20240611'.
**    ls_invoice-%param-taxiscalculatedautomatically = abap_true.
**    ls_invoice-%param-supplierinvoiceidbyinvcgparty = 'INV0001'.
**
**    ls_invoice-%param-_glitems = VALUE #(
**     ( supplierinvoiceitem = '000001'
**     debitcreditcode = 'S'
**     glaccount = '0021720200'
**     companycode = '4710'
**     documentcurrency = 'ILS'
**     supplierinvoiceitemamount = 100
**      )
**    ).
**
**    INSERT ls_invoice INTO TABLE lt_invoice.
**
**    MODIFY ENTITIES OF i_supplierinvoicetp
**    ENTITY supplierinvoice
**    EXECUTE create FROM lt_invoice
**    FAILED DATA(ls_failed)
**    REPORTED DATA(ls_reported)
**    MAPPED DATA(ls_mapped).
**
**    IF ls_failed IS NOT INITIAL.
**      DATA lo_message TYPE REF TO if_message.
**      lo_message = ls_reported-supplierinvoice[ 1 ]-%msg.
**    ENDIF.
**
**    COMMIT ENTITIES
**     RESPONSE OF i_supplierinvoicetp
**     FAILED DATA(ls_commit_failed)
**     REPORTED DATA(ls_commit_reported).
**
**    IF ls_commit_reported IS NOT INITIAL.
**      LOOP AT ls_commit_reported-supplierinvoice ASSIGNING FIELD-SYMBOL(<ls_invoice>).
**        IF <ls_invoice>-supplierinvoice IS NOT INITIAL AND
**        <ls_invoice>-supplierinvoicefiscalyear IS NOT INITIAL.
**        ELSE.
**        ENDIF.
**      ENDLOOP.
**    ENDIF.
**
**    IF ls_commit_failed IS NOT INITIAL.
**      LOOP AT ls_commit_reported-supplierinvoice ASSIGNING <ls_invoice>.
**      ENDLOOP.
**    ENDIF.
**

*DATA(lv_report_id) = 'D22CD95ADD944F3E89B3'.
*
*DATA ls_invoice TYPE STRUCTURE FOR ACTION IMPORT i_supplierinvoicetp~create.
*DATA lt_invoice TYPE TABLE FOR ACTION IMPORT i_supplierinvoicetp~create.
*
*DATA lt_processed_entries TYPE TABLE OF yexp_entry_e022.
*DATA lwa_processed_entries LIKE LINE OF lt_processed_entries.
*
*SELECT * FROM yexp_entry_e022 WHERE z_report_id = @lv_report_id INTO TABLE @DATA(lt_yexp_entry_e022).
*
*IF lt_yexp_entry_e022 IS NOT INITIAL.
*
*    SORT lt_yexp_entry_e022 BY z_entry_vendor_description.
*
*    DATA lv_previous_vendor TYPE string.
*    DATA lv_current_vendor TYPE string.
*
*    LOOP AT lt_yexp_entry_e022 INTO DATA(lwa_yexp_entry_e022).
*
*        lv_current_vendor = lwa_yexp_entry_e022-z_entry_vendor_description.
*
*        IF lv_current_vendor <> lv_previous_vendor.
*            lv_previous_vendor = lv_current_vendor.
*        ELSE.
*        ENDIF.
*
*        CLEAR: lv_current_vendor, lv_previous_vendor.
*
*    ENDLOOP.
*
*ENDIF.

    DATA ls_invoice TYPE STRUCTURE FOR ACTION IMPORT i_supplierinvoicetp~create.
    DATA lt_invoice TYPE TABLE FOR ACTION IMPORT i_supplierinvoicetp~create.

    DATA lv_sinv_id TYPE string.
    DATA lv_sinv_fiscal TYPE string.
    DATA(lv_cid) = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ).
    GET TIME STAMP FIELD DATA(lv_timestamp).
    DATA lv_current_date TYPE string.
    lv_current_date = lv_timestamp.
    lv_current_date = lv_current_date+0(8).

    ls_invoice-%cid = lv_cid.
    ls_invoice-%param-supplierinvoiceiscreditmemo = abap_false.
    ls_invoice-%param-companycode = '4710'.
    ls_invoice-%param-invoicingparty = '0001000030'.
    ls_invoice-%param-postingdate = lv_current_date.
    ls_invoice-%param-documentdate = lv_current_date.
    ls_invoice-%param-documentcurrency = 'ILS'.
    ls_invoice-%param-invoicegrossamount = 100.
    ls_invoice-%param-taxdeterminationdate = lv_current_date.
    ls_invoice-%param-taxiscalculatedautomatically = abap_true.
    ls_invoice-%param-supplierinvoiceidbyinvcgparty = 'INV0001'.

    ls_invoice-%param-_glitems = VALUE #(
     ( supplierinvoiceitem = '000001'
     debitcreditcode = 'S'
     glaccount = '0021720200'
     companycode = '4710'
     documentcurrency = 'ILS'
     supplierinvoiceitemamount = 100
     supplierinvoiceitemtext = 'Test'
      )
    ).

    INSERT ls_invoice INTO TABLE lt_invoice.

    MODIFY ENTITIES OF i_supplierinvoicetp
    ENTITY supplierinvoice
    EXECUTE create FROM lt_invoice
    FAILED DATA(ls_failed)
    REPORTED DATA(ls_reported)
    MAPPED DATA(ls_mapped).

    DATA: ls_temp_key TYPE STRUCTURE FOR KEY OF i_supplierinvoicetp.


******************************MESSAGE START**********************************************

    DATA lv_msg TYPE string.

    IF ls_failed IS NOT INITIAL AND ls_reported IS NOT INITIAL.
      IF ls_reported-supplierinvoice IS NOT INITIAL.
        IF ls_reported-supplierinvoice IS NOT INITIAL.
          LOOP AT ls_reported-supplierinvoice INTO DATA(lwa_supplierinvoice_log).
            IF lwa_supplierinvoice_log-%msg IS NOT INITIAL.
              DATA(ls_get_msg) = lwa_supplierinvoice_log-%msg.
              lv_msg = ls_get_msg->if_message~get_text( ).
            ENDIF.
          ENDLOOP.
        ENDIF.
      ENDIF.
    ENDIF.
******************************MESSAGE END************************************************

    IF ls_failed IS INITIAL.

      COMMIT ENTITIES BEGIN
          RESPONSE OF i_supplierinvoicetp
          FAILED DATA(ls_save_failed)
          REPORTED DATA(ls_save_reported).

      IF ls_save_reported IS NOT INITIAL.
        IF ls_save_reported-supplierinvoice IS NOT INITIAL.
          LOOP AT ls_save_reported-supplierinvoice INTO DATA(lwa_supplierinvoice).
            IF lwa_supplierinvoice-supplierinvoice IS NOT INITIAL.
              lv_sinv_id = lwa_supplierinvoice-supplierinvoice.
            ENDIF.
            IF lwa_supplierinvoice-supplierinvoicefiscalyear IS NOT INITIAL.
              lv_sinv_fiscal = lwa_supplierinvoice-supplierinvoicefiscalyear.
            ENDIF.
          ENDLOOP.
        ENDIF.
      ENDIF.

      COMMIT ENTITIES END.

      COMMIT WORK.

    ENDIF.

    CLEAR: lt_invoice,
           ls_invoice,
           lv_current_date,
           lv_timestamp,
           lv_cid,
           lv_sinv_fiscal,
           lv_sinv_id,
           ls_save_reported,
           ls_save_failed,
           ls_mapped,
           ls_reported,
           ls_failed.

*    TRY.
*        DATA(lv_log_uuid) = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ).
*      CATCH cx_uuid_error.
*    ENDTRY.
*
*    GET TIME STAMP FIELD DATA(lv_timestamp).
*    DATA lv_current_date TYPE string.
*    lv_current_date = lv_timestamp.
*    lv_current_date = lv_current_date+0(8).
*
*    DATA(ls_yexp_log_e022) = VALUE yexp_log_e022(
*      log_uuid                   = lv_log_uuid
*      log_created_on             = lv_current_date
*      log_comments               = 'Log Creation Succeed'
*      log_state                  = 'Success'
*      z_task_uuid                = ''
*      z_report_uuid              = ''
*      z_entry_uuid               = ''
*      z_created_by               = sy-uname
*      z_created_at               = lv_timestamp
*      z_last_changed_by          = sy-uname
*      z_last_changed_at          = lv_timestamp
*      z_local_last_changed_at    = lv_timestamp
*    ).
*
*    INSERT yexp_log_e022 FROM @ls_yexp_log_e022.
*    IF sy-subrc = 0.
*      COMMIT WORK.
*    ENDIF.

    DATA(debugger) = 'Hello'.

  ENDMETHOD.
ENDCLASS.
