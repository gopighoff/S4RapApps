CLASS y_concur_sinv_mdr DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_apj_dt_exec_object .
    INTERFACES if_apj_rt_exec_object .
    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS Y_CONCUR_SINV_MDR IMPLEMENTATION.


  METHOD if_apj_dt_exec_object~get_parameters.

    et_parameter_def = VALUE #( datatype       = 'C'
                         changeable_ind = abap_true
                         ( selname       = 'UUID'
                           kind          = if_apj_dt_exec_object=>parameter
                           param_text    = 'Task UUID'
                           length        = 50
                           lowercase_ind = abap_true
                           mandatory_ind = abap_true ) ).

    et_parameter_val = VALUE #( sign   = 'I'
                                option = 'EQ'
                                ( selname = 'UUID' low = abap_true )
                              ).

  ENDMETHOD.


  METHOD if_apj_rt_exec_object~execute.



****************Getting TASK UUID Start*****************
    DATA lv_task_uuid TYPE zr_yso_hdr_e022-zuuid.

    LOOP AT it_parameters INTO DATA(ls_parameter).
      CASE ls_parameter-selname.
        WHEN 'UUID'.
          lv_task_uuid = ls_parameter-low.
      ENDCASE.
    ENDLOOP.
****************Getting TASK UUID End*******************



*******************Post Invoice Start*******************
    IF lv_task_uuid IS NOT INITIAL.

      SELECT * FROM yexp_report_e022
          WHERE
              z_task_uuid = @lv_task_uuid AND
              z_report_status = 'In Preparation'
          INTO
      TABLE @DATA(lt_yexp_report_e022).

      IF lt_yexp_report_e022 IS NOT INITIAL.

        LOOP AT lt_yexp_report_e022 INTO DATA(lwa_yexp_report_e022).
          IF lwa_yexp_report_e022-z_report_id IS NOT INITIAL AND lwa_yexp_report_e022-z_report_uuid IS NOT INITIAL.

            SELECT * FROM yexp_entry_e022
                WHERE
                    z_report_id = @lwa_yexp_report_e022-z_report_id AND
                    z_report_uuid = @lwa_yexp_report_e022-z_report_uuid AND
                    z_entry_status = 'In Preparation'
                INTO
            TABLE @DATA(lt_yexp_entry_e022).

            IF lt_yexp_entry_e022 IS NOT INITIAL.

              LOOP AT lt_yexp_entry_e022 INTO DATA(lwa_yexp_entry_e022).
                IF lwa_yexp_entry_e022 IS NOT INITIAL.

                  DATA ls_invoice TYPE STRUCTURE FOR ACTION IMPORT i_supplierinvoicetp~create.
                  DATA lt_invoice TYPE TABLE FOR ACTION IMPORT i_supplierinvoicetp~create.

                  DATA lv_sinv_id TYPE string.
                  DATA lv_sinv_fiscal TYPE string.
                  DATA(lv_cid) = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ).
                  GET TIME STAMP FIELD DATA(lv_timestamp).
                  DATA lv_current_date TYPE string.
                  lv_current_date = lv_timestamp.
                  lv_current_date = lv_current_date+0(8).

                  "Report Amount Fix
                  DATA lv_invoicegrossamount_value TYPE string.
                  DATA lv_invoicegrossamount_int TYPE decfloat34.

                  lv_invoicegrossamount_value = '0'.
                  lv_invoicegrossamount_int = '0'.

                  IF lwa_yexp_entry_e022-z_entry_approved_amt IS NOT INITIAL.
                    IF lwa_yexp_entry_e022-z_entry_approved_amt > 0.
                      lv_invoicegrossamount_value = lwa_yexp_entry_e022-z_entry_approved_amt.
                      REPLACE ALL OCCURRENCES OF ',' IN lv_invoicegrossamount_value WITH '.'.
                      lv_invoicegrossamount_int = CONV decfloat34( lv_invoicegrossamount_value ).
                    ENDIF.
                  ENDIF.

                  IF lv_invoicegrossamount_int <> 0.
                    ls_invoice-%cid = lv_cid.
                    ls_invoice-%param-supplierinvoiceiscreditmemo = abap_false.
                    ls_invoice-%param-companycode = '4710'.
                    ls_invoice-%param-invoicingparty = '0001000030'.
                    ls_invoice-%param-postingdate = lv_current_date.
                    ls_invoice-%param-documentdate = lv_current_date.
                    ls_invoice-%param-documentcurrency = 'ILS'.
                    ls_invoice-%param-invoicegrossamount = lv_invoicegrossamount_int.
                    ls_invoice-%param-taxdeterminationdate = lv_current_date.
                    ls_invoice-%param-taxiscalculatedautomatically = abap_true.
                    ls_invoice-%param-supplierinvoiceidbyinvcgparty = '234892848234902394829849284923'.

                    ls_invoice-%param-_glitems = VALUE #(
                     ( supplierinvoiceitem = '000001'
                     debitcreditcode = 'S'
                     glaccount = '0021720200'
                     companycode = '4710'
                     documentcurrency = 'ILS'
                     supplierinvoiceitemamount = lv_invoicegrossamount_int
                     supplierinvoiceitemtext = lwa_yexp_entry_e022-z_entry_description
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

****************EML LOG****************************************************************************
                    IF ls_failed IS NOT INITIAL AND ls_reported IS NOT INITIAL.
                      IF ls_reported-supplierinvoice IS NOT INITIAL.
                        IF ls_reported-supplierinvoice IS NOT INITIAL.
                          LOOP AT ls_reported-supplierinvoice INTO DATA(lwa_supplierinvoice_log).
                            IF lwa_supplierinvoice_log-%msg IS NOT INITIAL.
                              DATA(ls_get_msg) = lwa_supplierinvoice_log-%msg.
                              DATA(lv_msg) = ls_get_msg->if_message~get_text( ).
                              IF lv_msg IS NOT INITIAL.
                                TRY.
                                    DATA(lv_log_uuid) = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ).
                                  CATCH cx_uuid_error.
                                ENDTRY.

                                GET TIME STAMP FIELD DATA(lv_log_timestamp).
                                DATA(ls_yexp_log_e022) = VALUE yexp_log_e022(
                                  log_uuid                   = lv_log_uuid
                                  log_created_on             = lv_log_timestamp
                                  log_comments               = lv_msg
                                  log_state                  = 'Failure'
                                  z_task_uuid                = ''
                                  z_report_uuid              = ''
                                  z_entry_uuid               = lwa_yexp_entry_e022-z_entry_uuid
                                  z_created_by               = sy-uname
                                  z_created_at               = lv_log_timestamp
                                  z_last_changed_by          = sy-uname
                                  z_last_changed_at          = lv_log_timestamp
                                  z_local_last_changed_at    = lv_log_timestamp
                                ).

                                INSERT yexp_log_e022 FROM @ls_yexp_log_e022.
                                IF sy-subrc = 0.
                                  COMMIT WORK.
                                ENDIF.
                              ENDIF.
                              CLEAR: lv_msg, ls_get_msg.
                            ENDIF.
                          ENDLOOP.
                          CLEAR: lwa_supplierinvoice_log.
                        ENDIF.
                      ENDIF.
                    ENDIF.
****************EML LOG****************************************************************************

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

                      IF lv_sinv_id IS NOT INITIAL AND lv_sinv_fiscal IS NOT INITIAL.
                        UPDATE yexp_entry_e022 SET z_entry_status = 'Completed', z_supplier_invoice_id = @lv_sinv_id, z_supplier_invoice_fiscal = @lv_sinv_fiscal WHERE z_entry_uuid = @lwa_yexp_entry_e022-z_entry_uuid.
                        IF sy-subrc = 0.
                          COMMIT WORK.
                        ENDIF.
                      ELSE.
                        TRY.
                            lv_log_uuid = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ).
                          CATCH cx_uuid_error.
                        ENDTRY.

                        GET TIME STAMP FIELD lv_log_timestamp.
                        ls_yexp_log_e022 = VALUE yexp_log_e022(
                          log_uuid                   = lv_log_uuid
                          log_created_on             = lv_log_timestamp
                          log_comments               = |Can't able to determine, supplier invoice id and fiscal year|
                          log_state                  = 'Failure'
                          z_task_uuid                = ''
                          z_report_uuid              = ''
                          z_entry_uuid               = lwa_yexp_entry_e022-z_entry_uuid
                          z_created_by               = sy-uname
                          z_created_at               = lv_log_timestamp
                          z_last_changed_by          = sy-uname
                          z_last_changed_at          = lv_log_timestamp
                          z_local_last_changed_at    = lv_log_timestamp
                        ).

                        INSERT yexp_log_e022 FROM @ls_yexp_log_e022.
                        IF sy-subrc = 0.
                          COMMIT WORK.
                        ENDIF.
                      ENDIF.
                    ENDIF.
                  ELSE.
                    UPDATE yexp_entry_e022 SET z_entry_status = 'Completed' WHERE z_entry_uuid = @lwa_yexp_entry_e022-z_entry_uuid.
                    IF sy-subrc = 0.
                      COMMIT WORK.
                    ENDIF.
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

                ENDIF.
              ENDLOOP.

            ENDIF.

            CLEAR: lt_yexp_entry_e022, lwa_yexp_entry_e022.

          ENDIF.
        ENDLOOP.

      ENDIF.

      CLEAR: lt_yexp_report_e022, lwa_yexp_report_e022.

    ENDIF.
*******************Post Invoice End*********************



*************Update Report Status Start*****************
    IF lv_task_uuid IS NOT INITIAL.

      SELECT * FROM yexp_report_e022
          WHERE
              z_task_uuid = @lv_task_uuid AND
              z_report_status = 'In Preparation'
          INTO
      TABLE @lt_yexp_report_e022.

      IF lt_yexp_report_e022 IS NOT INITIAL.

        LOOP AT lt_yexp_report_e022 INTO lwa_yexp_report_e022.

          SELECT * FROM yexp_entry_e022
              WHERE
                  z_report_id = @lwa_yexp_report_e022-z_report_id AND
                  z_report_uuid = @lwa_yexp_report_e022-z_report_uuid AND
                  z_entry_status = 'In Preparation'
              INTO
          TABLE @lt_yexp_entry_e022.

          IF lt_yexp_entry_e022 IS INITIAL.
            UPDATE yexp_report_e022 SET z_report_status = 'Completed' WHERE z_report_id = @lwa_yexp_report_e022-z_report_id AND z_report_uuid = @lwa_yexp_report_e022-z_report_uuid.
            IF sy-subrc = 0.
              COMMIT WORK.
            ENDIF.
          ENDIF.

        ENDLOOP.

      ENDIF.
    ENDIF.
*************Update Report Status End*******************



****************Store Response Start********************
    IF lv_task_uuid IS NOT INITIAL.
      UPDATE yexp_get_e022 SET z_task_process_step = '04' WHERE z_task_uuid = @lv_task_uuid. "04-Scheduled Post Invoice Mass Data Run Finished
      IF sy-subrc = 0.
        COMMIT WORK.
      ENDIF.
    ENDIF.
****************Store Response End*********************

  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.
  ENDMETHOD.
ENDCLASS.
