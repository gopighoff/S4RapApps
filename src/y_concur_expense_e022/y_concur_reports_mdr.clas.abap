CLASS y_concur_reports_mdr DEFINITION
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



CLASS Y_CONCUR_REPORTS_MDR IMPLEMENTATION.


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



****************Getting Access Token Start**************
    IF lv_task_uuid IS NOT INITIAL.

      SELECT SINGLE * FROM yexp_get_e022 WHERE z_task_uuid = @lv_task_uuid INTO @DATA(lwa_yexp_get_e022).

      IF lwa_yexp_get_e022 IS NOT INITIAL.

        TYPES: BEGIN OF ts_parse,
                 expires_in         TYPE string,
                 scope              TYPE string,
                 token_type         TYPE string,
                 access_token       TYPE string,
                 refresh_token      TYPE string,
                 refresh_expires_in TYPE string,
                 geolocation        TYPE string,
                 id_token           TYPE string,
               END OF ts_parse.

        DATA:lt_parse         TYPE ts_parse,
             lv_refresh_token TYPE string,
             lv_access_token  TYPE string,
             lv_uuid          TYPE yconfig_e022-z_uuid,
             lv_response_code TYPE i.

        lv_response_code = 500.

        SELECT SINGLE * FROM zr_yconfig_e022 INTO @DATA(lwa_zr_yconfig_e022).

        IF lwa_zr_yconfig_e022-zclientid IS INITIAL OR
           lwa_zr_yconfig_e022-zclientsecret IS INITIAL OR
           lwa_zr_yconfig_e022-zgranttype IS INITIAL OR
           lwa_zr_yconfig_e022-zrefreshtoken IS INITIAL.
          TRY.
              DATA(lv_log_uuid) = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ).
            CATCH cx_uuid_error.
          ENDTRY.

          GET TIME STAMP FIELD DATA(lv_log_timestamp).
          DATA(ls_yexp_log_e022) = VALUE yexp_log_e022(
            log_uuid                   = lv_log_uuid
            log_created_on             = lv_log_timestamp
            log_comments               = 'Access Token Generation Failed. Please Maintain Client Credential Details in Configuration Object'
            log_state                  = 'Failure'
            z_task_uuid                = lv_task_uuid
            z_report_uuid              = ''
            z_entry_uuid               = ''
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

        IF lwa_zr_yconfig_e022-zclientid IS NOT INITIAL AND
          lwa_zr_yconfig_e022-zclientsecret IS NOT INITIAL AND
          lwa_zr_yconfig_e022-zgranttype IS NOT INITIAL AND
          lwa_zr_yconfig_e022-zrefreshtoken IS NOT INITIAL.

          TRY.
              DATA(lo_http_destination) = cl_http_destination_provider=>create_by_comm_arrangement( comm_scenario = 'Y_CONFIG_E022' ).
              DATA(lo_web_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_http_destination ).
              DATA(lo_web_http_post_request) = lo_web_http_client->get_http_request( ).
              lo_web_http_post_request->set_content_type( content_type = 'application/x-www-form-urlencoded' ).
              DATA(client_id) = lwa_zr_yconfig_e022-zclientid.
              DATA(client_secret) = lwa_zr_yconfig_e022-zclientsecret.
              DATA(grant_type) = lwa_zr_yconfig_e022-zgranttype.
              DATA(refresh_token) = lwa_zr_yconfig_e022-zrefreshtoken.
              DATA(payload) = 'client_id=' && client_id && '&client_secret=' && client_secret && '&grant_type=' && grant_type && '&refresh_token=' && refresh_token.
              lo_web_http_post_request->set_text( payload ).
              DATA(lo_web_http_post_response) = lo_web_http_client->execute( if_web_http_client=>post ).
              DATA(lv_response) = lo_web_http_post_response->get_text( ).
              lv_response_code = lo_web_http_post_response->get_status( )-code.

              IF lv_response_code <> 200.
                TRY.
                    lv_log_uuid = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ).
                  CATCH cx_uuid_error.
                ENDTRY.

                GET TIME STAMP FIELD lv_log_timestamp.
                ls_yexp_log_e022 = VALUE yexp_log_e022(
                  log_uuid                   = lv_log_uuid
                  log_created_on             = lv_log_timestamp
                  log_comments               = 'Access Token Generation Failed. Received responce Code : ' && lv_response_code
                  log_state                  = 'Failure'
                  z_task_uuid                = lv_task_uuid
                  z_report_uuid              = ''
                  z_entry_uuid               = ''
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

              IF lv_response_code = 200.

                xco_cp_json=>data->from_string( lv_response )->apply( VALUE #(
                              ( xco_cp_json=>transformation->boolean_to_abap_bool )
                            ) )->write_to( REF #( lt_parse ) ).

                IF lt_parse IS NOT INITIAL.
                  IF lt_parse-refresh_token IS NOT INITIAL.
                    lv_refresh_token = lt_parse-refresh_token.
                  ENDIF.

                  IF lt_parse-access_token IS NOT INITIAL.
                    lv_access_token = lt_parse-access_token.
                  ENDIF.
                ENDIF.
              ENDIF.
            CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
          ENDTRY.

        ENDIF.

      ENDIF.

      CLEAR: lv_response_code,
             lwa_zr_yconfig_e022,
             lv_response,
             lo_web_http_post_response,
             payload,
             grant_type,
             client_secret,
             client_id,
             lo_web_http_post_request,
             lo_web_http_client,
             lo_http_destination.
    ENDIF.
****************Getting Access Token End****************



****************Setup auth Start************************
    IF lv_refresh_token IS NOT INITIAL AND lv_access_token IS NOT INITIAL.
      DATA(lv_auth_type) = 'Bearer'.
      CONCATENATE lv_auth_type lv_access_token INTO DATA(lv_auth) SEPARATED BY space.
    ENDIF.
****************Setup auth Start************************



****************Getting Reports start*******************
    IF lv_auth IS NOT INITIAL AND lv_refresh_token IS NOT INITIAL AND lv_access_token IS NOT INITIAL.




****************BY REPORT ID****************************
      IF lwa_yexp_get_e022-z_filter_by = 'Report ID'.
        TRY.
            lo_http_destination = cl_http_destination_provider=>create_by_comm_arrangement( comm_scenario = 'Y_CONCUR_EXPENSE_CS' ).
            lo_web_http_client = cl_web_http_client_manager=>create_by_http_destination( lo_http_destination ).
            DATA(lo_web_http_request) = lo_web_http_client->get_http_request( ).
            lo_web_http_request->set_header_fields(
                                 VALUE #(
                                            ( name = 'Accept' value = 'application/json' )
                                            ( name = 'Authorization' value = lv_auth )
                                        )
                                 ).
            lo_web_http_request->set_uri_path( i_uri_path = '/api/v3.0/expense/reports/' && lwa_yexp_get_e022-z_report_id ).
            lo_web_http_post_response = lo_web_http_client->execute( if_web_http_client=>get ).
            lv_response = lo_web_http_post_response->get_text( ).
            lv_response_code = lo_web_http_post_response->get_status( )-code.
          CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
        ENDTRY.

        IF lv_response_code <> 200.
          TRY.
              lv_log_uuid = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ).
            CATCH cx_uuid_error.
          ENDTRY.

          GET TIME STAMP FIELD lv_log_timestamp.
          ls_yexp_log_e022 = VALUE yexp_log_e022(
            log_uuid                   = lv_log_uuid
            log_created_on             = lv_log_timestamp
            log_comments               = 'Reports Fetching Failed. Received responce Code : ' && lv_response_code
            log_state                  = 'Failure'
            z_task_uuid                = lv_task_uuid
            z_report_uuid              = ''
            z_entry_uuid               = ''
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

        IF lv_response_code = 200.

          TYPES: BEGIN OF ts_report,
                   name               TYPE string,
                   total              TYPE string,
                   currencycode       TYPE string,
                   createdate         TYPE string,
                   submitdate         TYPE string,
                   ownerloginid       TYPE string,
                   ownername          TYPE string,
                   approvalstatusname TYPE string,
                   approvalstatuscode TYPE string,
                   lastmodifieddate   TYPE string,
                   totalclaimedamount TYPE string,
                   id                 TYPE string,
                 END OF ts_report.

          DATA:lwa_parse TYPE ts_report.

          xco_cp_json=>data->from_string( lv_response )->apply( VALUE #(
                        ( xco_cp_json=>transformation->boolean_to_abap_bool )
                      ) )->write_to( REF #( lwa_parse ) ).

          IF lwa_parse IS INITIAL.
            TRY.
                lv_log_uuid = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ).
              CATCH cx_uuid_error.
            ENDTRY.

            GET TIME STAMP FIELD lv_log_timestamp.
            ls_yexp_log_e022 = VALUE yexp_log_e022(
              log_uuid                   = lv_log_uuid
              log_created_on             = lv_log_timestamp
              log_comments               = 'JSON Parser Error / No Reports Found'
              log_state                  = 'Failure'
              z_task_uuid                = lv_task_uuid
              z_report_uuid              = ''
              z_entry_uuid               = ''
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

          IF lwa_parse IS NOT INITIAL.

            DATA(lv_duplicate) = abap_false.

            IF lwa_parse-id IS NOT INITIAL.
              SELECT * FROM yexp_report_e022 WHERE z_report_id = @lwa_parse-id INTO TABLE @DATA(lv_reports_db).
              IF lv_reports_db IS NOT INITIAL.
                lv_duplicate = abap_true.
              ENDIF.
              SELECT * FROM yexp_report_ed22 WHERE zreportid = @lwa_parse-id INTO TABLE @DATA(lv_reports_draft_db).
              IF lv_reports_draft_db IS NOT INITIAL.
                lv_duplicate = abap_true.
              ENDIF.
              SELECT * FROM zr_yexp_report_e022 WHERE zreportid = @lwa_parse-id INTO TABLE @DATA(lv_reports_cds).
              IF lv_reports_cds IS NOT INITIAL.
                lv_duplicate = abap_true.
              ENDIF.
            ENDIF.

            IF lv_duplicate = abap_false.

              DATA lv_created_on TYPE string.
              DATA lv_changed_on TYPE string.
              DATA lv_submitted_on TYPE string.

              lv_created_on = '00000000'.
              lv_changed_on = '00000000'.
              lv_submitted_on = '00000000'.

              IF lwa_parse-createdate IS NOT INITIAL.
                lv_created_on = lwa_parse-createdate.
                lv_created_on = lv_created_on+0(10).
                REPLACE ALL OCCURRENCES OF `-` IN lv_created_on WITH ``.
              ENDIF.

              IF lwa_parse-lastmodifieddate IS NOT INITIAL.
                lv_changed_on = lwa_parse-lastmodifieddate.
                lv_changed_on = lv_changed_on+0(10).
                REPLACE ALL OCCURRENCES OF `-` IN lv_changed_on WITH ``.
              ENDIF.

              IF lwa_parse-submitdate IS NOT INITIAL.
                lv_submitted_on = lwa_parse-submitdate.
                lv_submitted_on = lv_submitted_on+0(10).
                REPLACE ALL OCCURRENCES OF `-` IN lv_submitted_on WITH ``.
              ENDIF.

              DATA report_uuid TYPE zr_yexp_report_e022-zreportuuid.
              report_uuid = cl_system_uuid=>create_uuid_x16_static( ).

              "Report Amount Fix
              DATA lv_total_report_value TYPE string.
              DATA lv_claimed_report_value TYPE string.
              DATA lv_total_report_int TYPE decfloat34.
              DATA lv_claimed_report_int TYPE decfloat34.

              lv_total_report_value = '0'.
              lv_claimed_report_value = '0'.
              lv_total_report_int = '0'.
              lv_claimed_report_int = '0'.

              IF lwa_parse-total IS NOT INITIAL.
                lv_total_report_value = lwa_parse-total.
                REPLACE ALL OCCURRENCES OF ',' IN lv_total_report_value WITH '.'.
                lv_total_report_int = CONV decfloat34( lv_total_report_value ).
              ENDIF.

              IF lwa_parse-totalclaimedamount IS NOT INITIAL.
                lv_claimed_report_value = lwa_parse-totalclaimedamount.
                REPLACE ALL OCCURRENCES OF ',' IN lv_claimed_report_value WITH '.'.
                lv_claimed_report_int = CONV decfloat34( lv_claimed_report_value ).
              ENDIF.
              "Report Amount Fix

              DATA(ls_report) = VALUE yexp_report_e022(
                                    z_report_uuid             = report_uuid
                                    z_report_id               = lwa_parse-id
                                    z_task_uuid               = lv_task_uuid
                                    z_report_name             = lwa_parse-name
                                    z_report_createdon        = lv_created_on
                                    z_report_lastchangedon    = lv_changed_on
                                    z_report_submittedon      = lv_submitted_on
                                    z_owner_id                = lwa_parse-ownerloginid
                                    z_owner_name              = lwa_parse-ownername
                                    z_report_approvalcode     = lwa_parse-approvalstatuscode
                                    z_report_approvalname     = lwa_parse-approvalstatusname
                                    z_transaction_currency    = lwa_parse-currencycode
                                    z_total_amt               = lv_total_report_int
                                    z_total_claimed_amt       = lv_claimed_report_int
                                    z_report_status           = 'In Preparation'
                                                      ).
              INSERT yexp_report_e022 FROM @ls_report.
              IF sy-subrc = 0.
                COMMIT WORK.
              ELSE.
                TRY.
                    lv_log_uuid = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ).
                  CATCH cx_uuid_error.
                ENDTRY.

                GET TIME STAMP FIELD lv_log_timestamp.
                ls_yexp_log_e022 = VALUE yexp_log_e022(
                  log_uuid                   = lv_log_uuid
                  log_created_on             = lv_log_timestamp
                  log_comments               = 'Errored While Fetching Report Name : ' && lwa_parse-name && 'From Concur'
                  log_state                  = 'Failure'
                  z_task_uuid                = lv_task_uuid
                  z_report_uuid              = ''
                  z_entry_uuid               = ''
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

              CLEAR: ls_report.
              CLEAR: lo_http_destination,
              lo_web_http_client,
              lo_web_http_request,
              lo_web_http_post_response,
              lv_response,
              lv_response_code.
            ENDIF.



****************ENTRIES***************************
            DATA lv_report_id TYPE yexp_entry_e022-z_report_id.
            DATA lv_report_uuid TYPE yexp_entry_e022-z_report_uuid.
            lv_report_id = lwa_parse-id.
            lv_report_uuid = report_uuid.

            IF lv_report_id IS NOT INITIAL AND report_uuid IS INITIAL.
              SELECT z_report_uuid FROM yexp_report_e022 WHERE z_report_id = @lv_report_id INTO @lv_report_uuid.
              ENDSELECT.
            ENDIF.

            IF lv_report_id IS NOT INITIAL AND lv_report_uuid IS NOT INITIAL AND lv_auth IS NOT INITIAL.

              TRY.
                  lo_http_destination = cl_http_destination_provider=>create_by_comm_arrangement( comm_scenario = 'Y_CONCUR_EXPENSE_CS' ).
                  lo_web_http_client  = cl_web_http_client_manager=>create_by_http_destination( lo_http_destination ).
                  lo_web_http_request = lo_web_http_client->get_http_request( ).
                  lo_web_http_request->set_header_fields(
                                       VALUE #(
                                                  ( name = 'Accept' value = 'application/json' )
                                                  ( name = 'Authorization' value = lv_auth )
                                              )
                                       ).
                  lo_web_http_request->set_uri_path( i_uri_path = '/api/v3.0/expense/entries?limit=100&user=ALL&reportID=' && lv_report_id ).
                  lo_web_http_post_response = lo_web_http_client->execute( if_web_http_client=>get ).
                  lv_response = lo_web_http_post_response->get_text( ).
                  lv_response_code = lo_web_http_post_response->get_status( )-code.

                CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
              ENDTRY.

              IF lv_response_code <> 200.
                TRY.
                    lv_log_uuid = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ).
                  CATCH cx_uuid_error.
                ENDTRY.

                GET TIME STAMP FIELD lv_log_timestamp.
                ls_yexp_log_e022 = VALUE yexp_log_e022(
                  log_uuid                   = lv_log_uuid
                  log_created_on             = lv_log_timestamp
                  log_comments               = 'Expense Entries Fetching Failed. Received responce Code : ' && lv_response_code
                  log_state                  = 'Failure'
                  z_task_uuid                = ''
                  z_report_uuid              = lv_report_uuid
                  z_entry_uuid               = ''
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

              IF lv_response_code = 200.
                TYPES: BEGIN OF ts_entry,
                         id                      TYPE string,
                         description             TYPE string,
                         expensetypecode         TYPE string,
                         expensetypename         TYPE string,
                         spendcategorycode       TYPE string,
                         spendcategoryname       TYPE string,
                         transactiondate         TYPE string,
                         transactioncurrencycode TYPE string,
                         transactionamount       TYPE string,
                         approvedamount          TYPE string,
                         lastmodified            TYPE string,
                         vendordescription       TYPE string,
                       END OF ts_entry.

                TYPES: BEGIN OF ts_entrylist,
                         items TYPE STANDARD TABLE OF ts_entry WITH EMPTY KEY,
                       END OF ts_entrylist.

                DATA lwa_entrylist TYPE ts_entrylist.

                xco_cp_json=>data->from_string( lv_response )->apply( VALUE #(
                ( xco_cp_json=>transformation->boolean_to_abap_bool )
                 ) )->write_to( REF #( lwa_entrylist ) ).

                IF lwa_entrylist IS INITIAL.
                  TRY.
                      lv_log_uuid = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ).
                    CATCH cx_uuid_error.
                  ENDTRY.

                  GET TIME STAMP FIELD lv_log_timestamp.
                  ls_yexp_log_e022 = VALUE yexp_log_e022(
                    log_uuid                   = lv_log_uuid
                    log_created_on             = lv_log_timestamp
                    log_comments               = 'JSON Parser Error / No Records Found'
                    log_state                  = 'Failure'
                    z_task_uuid                = ''
                    z_report_uuid              = lv_report_uuid
                    z_entry_uuid               = ''
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

                IF lwa_entrylist IS NOT INITIAL.
                  IF lwa_entrylist-items IS NOT INITIAL.
                    LOOP AT lwa_entrylist-items INTO DATA(lwa_parse_entry).

                      IF lwa_parse_entry IS NOT INITIAL.

                        lv_duplicate = abap_false.
                        IF lwa_parse_entry-id IS NOT INITIAL.
                          SELECT * FROM yexp_entry_e022 WHERE z_entry_id = @lwa_parse_entry-id INTO TABLE @DATA(lt_entry_db).
                          IF lt_entry_db IS NOT INITIAL.
                            lv_duplicate = abap_true.
                          ENDIF.

                          SELECT * FROM yexp_entry_ed22 WHERE zentryid = @lwa_parse_entry-id INTO TABLE @DATA(lt_entry_draft_db).
                          IF lt_entry_draft_db IS NOT INITIAL.
                            lv_duplicate = abap_true.
                          ENDIF.
                        ENDIF.

                        IF lv_duplicate = abap_false.

                          GET TIME STAMP FIELD DATA(lv_timestamp).

                          DATA lv_transaction_date TYPE string.
                          DATA lv_lastmodified_date TYPE string.

                          lv_transaction_date  = '00000000'.
                          lv_lastmodified_date = '00000000'.

                          IF lwa_parse_entry-transactiondate IS NOT INITIAL.
                            lv_transaction_date = lwa_parse_entry-transactiondate.
                            lv_transaction_date = lv_transaction_date+0(10).
                            REPLACE ALL OCCURRENCES OF `-` IN lv_transaction_date WITH ``.
                          ENDIF.

                          IF lwa_parse_entry-lastmodified IS NOT INITIAL.
                            lv_lastmodified_date = lwa_parse_entry-lastmodified.
                            lv_lastmodified_date = lv_lastmodified_date+0(10).
                            REPLACE ALL OCCURRENCES OF `-` IN lv_lastmodified_date WITH ``.
                          ENDIF.

                          "Expense Amount Fix
                          DATA lv_total_exp_value TYPE string.
                          DATA lv_apprv_exp_value TYPE string.
                          DATA lv_total_exp_int TYPE decfloat34.
                          DATA lv_apprv_exp_int TYPE decfloat34.

                          lv_total_exp_value = '0'.
                          lv_apprv_exp_value = '0'.
                          lv_total_exp_int = '0'.
                          lv_apprv_exp_int = '0'.

                          IF lwa_parse_entry-transactionamount IS NOT INITIAL.
                            lv_total_exp_value = lwa_parse_entry-transactionamount.
                            REPLACE ALL OCCURRENCES OF ',' IN lv_total_exp_value WITH '.'.
                            lv_total_exp_int = CONV decfloat34( lv_total_exp_value ).
                          ENDIF.

                          IF lwa_parse_entry-approvedamount IS NOT INITIAL.
                            lv_apprv_exp_value = lwa_parse_entry-approvedamount.
                            REPLACE ALL OCCURRENCES OF ',' IN lv_apprv_exp_value WITH '.'.
                            lv_apprv_exp_int = CONV decfloat34( lv_apprv_exp_value ).
                          ENDIF.
                          "Expense Amount Fix

                          DATA(ls_yexp_entry_e022) = VALUE yexp_entry_e022(
                            z_entry_uuid               = cl_system_uuid=>create_uuid_x16_static( )
                            z_report_uuid              = lv_report_uuid
                            z_report_id                = lv_report_id
                            z_entry_id                 = lwa_parse_entry-id
                            z_entry_status             = 'In Preparation'
                            z_entry_description        = lwa_parse_entry-description
                            z_entry_typecode           = lwa_parse_entry-expensetypecode
                            z_entry_typename           = lwa_parse_entry-expensetypename
                            z_entry_spend_categorycode = lwa_parse_entry-spendcategorycode
                            z_entry_spend_categoryname = lwa_parse_entry-spendcategoryname
                            z_entry_transaction_date   = lv_transaction_date
                            z_entry_transaction_curr   = lwa_parse_entry-transactioncurrencycode
                            z_entry_transaction_amt    = lv_total_exp_int
                            z_entry_approved_amt       = lv_apprv_exp_int
                            z_entry_last_modified      = lv_lastmodified_date
                            z_entry_vendor_description = lwa_parse_entry-vendordescription
                            z_created_by               = sy-uname
                            z_created_at               = lv_timestamp
                            z_last_changed_by          = sy-uname
                            z_last_changed_at          = lv_timestamp
                            z_local_last_changed_at    = lv_timestamp
                          ).

                          INSERT yexp_entry_e022 FROM @ls_yexp_entry_e022.
                          IF sy-subrc = 0.
                            COMMIT WORK.
                          ENDIF.

                        ENDIF.

                      ENDIF.
                    ENDLOOP.
                  ENDIF.
                ENDIF.

              ENDIF.

            ENDIF.
****************ENTRIES***************************



            CLEAR: lo_http_destination,
            lo_web_http_client,
            lo_web_http_request,
            lo_web_http_post_response,
            lv_response,
            lv_response_code.
          ENDIF.
        ENDIF.
      ENDIF.
      CLEAR: lwa_parse.




****************BY REPORT DATE*************************

      IF lwa_yexp_get_e022-z_filter_by = 'Report Date'.

        DATA lv_uri_path TYPE string.
        lv_uri_path = '/api/v3.0/expense/reports?User=ALL&approvalStatusCode=A_ACCO&limit=100'.
        DATA(raw_from) = lwa_yexp_get_e022-z_filter_from.
        DATA(raw_to)   = lwa_yexp_get_e022-z_filter_to.
        DATA(converted_from) = raw_from+0(4) && '-' && raw_from+4(2) && '-' && raw_from+6(2).
        DATA(converted_to) = raw_to+0(4) && '-' && raw_to+4(2) && '-' && raw_to+6(2).
        DATA(lv_filter_to) = 'createDateBefore=' && converted_to && 'T11:59:00'.
        DATA(lv_filter_from) = 'createDateAfter=' && converted_from && 'T00:00:00'.
        lv_uri_path = lv_uri_path && '&' && lv_filter_from && '&' && lv_filter_to.

        TRY.
            lo_http_destination = cl_http_destination_provider=>create_by_comm_arrangement( comm_scenario = 'Y_CONCUR_EXPENSE_CS' ).
            lo_web_http_client = cl_web_http_client_manager=>create_by_http_destination( lo_http_destination ).
            lo_web_http_request = lo_web_http_client->get_http_request( ).
            lo_web_http_request->set_header_fields(
                                 VALUE #(
                                            ( name = 'Accept' value = 'application/json' )
                                            ( name = 'Authorization' value = lv_auth )
                                        )
                                 ).
            lo_web_http_request->set_uri_path( i_uri_path = lv_uri_path ).
            lo_web_http_post_response = lo_web_http_client->execute( if_web_http_client=>get ).
            lv_response = lo_web_http_post_response->get_text( ).
            lv_response_code = lo_web_http_post_response->get_status( )-code.
          CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
        ENDTRY.

        IF lv_response_code <> 200.
          TRY.
              lv_log_uuid = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ).
            CATCH cx_uuid_error.
          ENDTRY.

          GET TIME STAMP FIELD lv_log_timestamp.
          ls_yexp_log_e022 = VALUE yexp_log_e022(
            log_uuid                   = lv_log_uuid
            log_created_on             = lv_log_timestamp
            log_comments               = 'Reports Fetching Failed. Received responce Code : ' && lv_response_code
            log_state                  = 'Failure'
            z_task_uuid                = lv_task_uuid
            z_report_uuid              = ''
            z_entry_uuid               = ''
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

        IF lv_response_code = 200.

          TYPES: BEGIN OF ts_reportlist,
                   items TYPE STANDARD TABLE OF ts_report WITH EMPTY KEY,
                 END OF ts_reportlist.
          DATA lwa_reportlist TYPE ts_reportlist.

          xco_cp_json=>data->from_string( lv_response )->apply( VALUE #(
            ( xco_cp_json=>transformation->boolean_to_abap_bool )
          ) )->write_to( REF #( lwa_reportlist ) ).

          IF lwa_reportlist IS INITIAL.
            TRY.
                lv_log_uuid = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ).
              CATCH cx_uuid_error.
            ENDTRY.

            GET TIME STAMP FIELD lv_log_timestamp.
            ls_yexp_log_e022 = VALUE yexp_log_e022(
              log_uuid                   = lv_log_uuid
              log_created_on             = lv_log_timestamp
              log_comments               = 'JSON Parser Error / No Records Found'
              log_state                  = 'Failure'
              z_task_uuid                = lv_task_uuid
              z_report_uuid              = ''
              z_entry_uuid               = ''
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

          IF lwa_reportlist IS NOT INITIAL.
            IF lwa_reportlist-items IS NOT INITIAL.
              LOOP AT lwa_reportlist-items INTO lwa_parse.

                IF lwa_parse IS NOT INITIAL.

                  lv_duplicate = abap_false.

                  IF lwa_parse-id IS NOT INITIAL.
                    SELECT * FROM yexp_report_e022 WHERE z_report_id = @lwa_parse-id INTO TABLE @lv_reports_db.
                    IF lv_reports_db IS NOT INITIAL.
                      lv_duplicate = abap_true.
                    ENDIF.
                    SELECT * FROM yexp_report_ed22 WHERE zreportid = @lwa_parse-id INTO TABLE @lv_reports_draft_db.
                    IF lv_reports_draft_db IS NOT INITIAL.
                      lv_duplicate = abap_true.
                    ENDIF.
                    SELECT * FROM zr_yexp_report_e022 WHERE zreportid = @lwa_parse-id INTO TABLE @lv_reports_cds.
                    IF lv_reports_cds IS NOT INITIAL.
                      lv_duplicate = abap_true.
                    ENDIF.
                  ENDIF.

                  IF lv_duplicate = abap_false.

                    lv_created_on = '00000000'.
                    lv_changed_on = '00000000'.
                    lv_submitted_on = '00000000'.

                    IF lwa_parse-createdate IS NOT INITIAL.
                      lv_created_on = lwa_parse-createdate.
                      lv_created_on = lv_created_on+0(10).
                      REPLACE ALL OCCURRENCES OF `-` IN lv_created_on WITH ``.
                    ENDIF.

                    IF lwa_parse-lastmodifieddate IS NOT INITIAL.
                      lv_changed_on = lwa_parse-lastmodifieddate.
                      lv_changed_on = lv_changed_on+0(10).
                      REPLACE ALL OCCURRENCES OF `-` IN lv_changed_on WITH ``.
                    ENDIF.

                    IF lwa_parse-submitdate IS NOT INITIAL.
                      lv_submitted_on = lwa_parse-submitdate.
                      lv_submitted_on = lv_submitted_on+0(10).
                      REPLACE ALL OCCURRENCES OF `-` IN lv_submitted_on WITH ``.
                    ENDIF.

                    report_uuid = cl_system_uuid=>create_uuid_x16_static( ).

                    "Report Amount Fix
                    lv_total_report_value = '0'.
                    lv_claimed_report_value = '0'.
                    lv_total_report_int = '0'.
                    lv_claimed_report_int = '0'.

                    IF lwa_parse-total IS NOT INITIAL.
                      lv_total_report_value = lwa_parse-total.
                      REPLACE ALL OCCURRENCES OF ',' IN lv_total_report_value WITH '.'.
                      lv_total_report_int = CONV decfloat34( lv_total_report_value ).
                    ENDIF.

                    IF lwa_parse-totalclaimedamount IS NOT INITIAL.
                      lv_claimed_report_value = lwa_parse-totalclaimedamount.
                      REPLACE ALL OCCURRENCES OF ',' IN lv_claimed_report_value WITH '.'.
                      lv_claimed_report_int = CONV decfloat34( lv_claimed_report_value ).
                    ENDIF.
                    "Report Amount Fix

                    ls_report = VALUE yexp_report_e022(
                                          z_report_uuid             = report_uuid
                                          z_report_id               = lwa_parse-id
                                          z_task_uuid               = lv_task_uuid
                                          z_report_name             = lwa_parse-name
                                          z_report_createdon        = lv_created_on
                                          z_report_lastchangedon    = lv_changed_on
                                          z_report_submittedon      = lv_submitted_on
                                          z_owner_id                = lwa_parse-ownerloginid
                                          z_owner_name              = lwa_parse-ownername
                                          z_report_approvalcode     = lwa_parse-approvalstatuscode
                                          z_report_approvalname     = lwa_parse-approvalstatusname
                                          z_transaction_currency    = lwa_parse-currencycode
                                          z_total_amt               = lv_total_report_int
                                          z_total_claimed_amt       = lv_claimed_report_int
                                          z_report_status           = 'In Preparation'
                                                            ).
                    INSERT yexp_report_e022 FROM @ls_report.
                    IF sy-subrc = 0.
                      COMMIT WORK.
                    ELSE.
                      TRY.
                          lv_log_uuid = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ).
                        CATCH cx_uuid_error.
                      ENDTRY.

                      GET TIME STAMP FIELD lv_log_timestamp.
                      ls_yexp_log_e022 = VALUE yexp_log_e022(
                        log_uuid                   = lv_log_uuid
                        log_created_on             = lv_log_timestamp
                        log_comments               = 'Errored While Fetching Report Name : ' && lwa_parse-name && 'From Concur'
                        log_state                  = 'Failure'
                        z_task_uuid                = lv_task_uuid
                        z_report_uuid              = ''
                        z_entry_uuid               = ''
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
                    CLEAR: ls_report.

                  ENDIF.



****************ENTRIES***************************

                  lv_report_id = lwa_parse-id.
                  lv_report_uuid = report_uuid.

                  IF lv_report_id IS NOT INITIAL AND report_uuid IS INITIAL.
                    SELECT z_report_uuid FROM yexp_report_e022 WHERE z_report_id = @lv_report_id INTO @lv_report_uuid.
                    ENDSELECT.
                  ENDIF.

                  IF lv_report_id IS NOT INITIAL AND lv_report_uuid IS NOT INITIAL AND lv_auth IS NOT INITIAL.

                    TRY.
                        lo_http_destination = cl_http_destination_provider=>create_by_comm_arrangement( comm_scenario = 'Y_CONCUR_EXPENSE_CS' ).
                        lo_web_http_client  = cl_web_http_client_manager=>create_by_http_destination( lo_http_destination ).
                        lo_web_http_request = lo_web_http_client->get_http_request( ).
                        lo_web_http_request->set_header_fields(
                                             VALUE #(
                                                        ( name = 'Accept' value = 'application/json' )
                                                        ( name = 'Authorization' value = lv_auth )
                                                    )
                                             ).
                        lo_web_http_request->set_uri_path( i_uri_path = '/api/v3.0/expense/entries?limit=100&user=ALL&reportID=' && lv_report_id ).
                        lo_web_http_post_response = lo_web_http_client->execute( if_web_http_client=>get ).
                        lv_response = lo_web_http_post_response->get_text( ).
                        lv_response_code = lo_web_http_post_response->get_status( )-code.

                      CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
                    ENDTRY.

                    IF lv_response_code <> 200.
                      TRY.
                          lv_log_uuid = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ).
                        CATCH cx_uuid_error.
                      ENDTRY.

                      GET TIME STAMP FIELD lv_log_timestamp.
                      ls_yexp_log_e022 = VALUE yexp_log_e022(
                        log_uuid                   = lv_log_uuid
                        log_created_on             = lv_log_timestamp
                        log_comments               = 'Expense Entries Fetching Failed. Received responce Code : ' && lv_response_code
                        log_state                  = 'Failure'
                        z_task_uuid                = ''
                        z_report_uuid              = lv_report_uuid
                        z_entry_uuid               = ''
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

                    IF lv_response_code = 200.

                      xco_cp_json=>data->from_string( lv_response )->apply( VALUE #(
                      ( xco_cp_json=>transformation->boolean_to_abap_bool )
                       ) )->write_to( REF #( lwa_entrylist ) ).

                      IF lwa_entrylist IS INITIAL.
                        TRY.
                            lv_log_uuid = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ).
                          CATCH cx_uuid_error.
                        ENDTRY.

                        GET TIME STAMP FIELD lv_log_timestamp.
                        ls_yexp_log_e022 = VALUE yexp_log_e022(
                          log_uuid                   = lv_log_uuid
                          log_created_on             = lv_log_timestamp
                          log_comments               = 'JSON Parser Error / No Records Found'
                          log_state                  = 'Failure'
                          z_task_uuid                = ''
                          z_report_uuid              = lv_report_uuid
                          z_entry_uuid               = ''
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

                      IF lwa_entrylist IS NOT INITIAL.
                        IF lwa_entrylist-items IS NOT INITIAL.
                          LOOP AT lwa_entrylist-items INTO lwa_parse_entry.

                            IF lwa_parse_entry IS NOT INITIAL.

                              lv_duplicate = abap_false.
                              IF lwa_parse_entry-id IS NOT INITIAL.
                                SELECT * FROM yexp_entry_e022 WHERE z_entry_id = @lwa_parse_entry-id INTO TABLE @lt_entry_db.
                                IF lt_entry_db IS NOT INITIAL.
                                  lv_duplicate = abap_true.
                                ENDIF.

                                SELECT * FROM yexp_entry_ed22 WHERE zentryid = @lwa_parse_entry-id INTO TABLE @lt_entry_draft_db.
                                IF lt_entry_draft_db IS NOT INITIAL.
                                  lv_duplicate = abap_true.
                                ENDIF.
                              ENDIF.

                              IF lv_duplicate = abap_false.

                                GET TIME STAMP FIELD lv_timestamp.

                                lv_transaction_date  = '00000000'.
                                lv_lastmodified_date = '00000000'.

                                IF lwa_parse_entry-transactiondate IS NOT INITIAL.
                                  lv_transaction_date = lwa_parse_entry-transactiondate.
                                  lv_transaction_date = lv_transaction_date+0(10).
                                  REPLACE ALL OCCURRENCES OF `-` IN lv_transaction_date WITH ``.
                                ENDIF.

                                IF lwa_parse_entry-lastmodified IS NOT INITIAL.
                                  lv_lastmodified_date = lwa_parse_entry-lastmodified.
                                  lv_lastmodified_date = lv_lastmodified_date+0(10).
                                  REPLACE ALL OCCURRENCES OF `-` IN lv_lastmodified_date WITH ``.
                                ENDIF.

                                "Expense Amount Fix
                                lv_total_exp_value = '0'.
                                lv_apprv_exp_value = '0'.
                                lv_total_exp_int = '0'.
                                lv_apprv_exp_int = '0'.

                                IF lwa_parse_entry-transactionamount IS NOT INITIAL.
                                  lv_total_exp_value = lwa_parse_entry-transactionamount.
                                  REPLACE ALL OCCURRENCES OF ',' IN lv_total_exp_value WITH '.'.
                                  lv_total_exp_int = CONV decfloat34( lv_total_exp_value ).
                                ENDIF.

                                IF lwa_parse_entry-approvedamount IS NOT INITIAL.
                                  lv_apprv_exp_value = lwa_parse_entry-approvedamount.
                                  REPLACE ALL OCCURRENCES OF ',' IN lv_apprv_exp_value WITH '.'.
                                  lv_apprv_exp_int = CONV decfloat34( lv_apprv_exp_value ).
                                ENDIF.
                                "Expense Amount Fix

                                ls_yexp_entry_e022 = VALUE yexp_entry_e022(
                                  z_entry_uuid               = cl_system_uuid=>create_uuid_x16_static( )
                                  z_report_uuid              = lv_report_uuid
                                  z_report_id                = lv_report_id
                                  z_entry_id                 = lwa_parse_entry-id
                                  z_entry_status             = 'In Preparation'
                                  z_entry_description        = lwa_parse_entry-description
                                  z_entry_typecode           = lwa_parse_entry-expensetypecode
                                  z_entry_typename           = lwa_parse_entry-expensetypename
                                  z_entry_spend_categorycode = lwa_parse_entry-spendcategorycode
                                  z_entry_spend_categoryname = lwa_parse_entry-spendcategoryname
                                  z_entry_transaction_date   = lv_transaction_date
                                  z_entry_transaction_curr   = lwa_parse_entry-transactioncurrencycode
                                  z_entry_transaction_amt    = lv_total_exp_int
                                  z_entry_approved_amt       = lv_apprv_exp_int
                                  z_entry_last_modified      = lv_lastmodified_date
                                  z_entry_vendor_description = lwa_parse_entry-vendordescription
                                  z_created_by               = sy-uname
                                  z_created_at               = lv_timestamp
                                  z_last_changed_by          = sy-uname
                                  z_last_changed_at          = lv_timestamp
                                  z_local_last_changed_at    = lv_timestamp
                                ).

                                INSERT yexp_entry_e022 FROM @ls_yexp_entry_e022.
                                IF sy-subrc = 0.
                                  COMMIT WORK.
                                ENDIF.

                              ENDIF.

                            ENDIF.
                          ENDLOOP.
                        ENDIF.
                      ENDIF.

                    ENDIF.

                  ENDIF.
****************ENTRIES***************************




                ENDIF.
              ENDLOOP.
            ENDIF.
          ENDIF.

        ENDIF.

      ENDIF.
****************BY REPORT DATE*************************



    ENDIF.
****************Getting Reports end*********************




****************Store Response Start********************
    IF lv_task_uuid IS NOT INITIAL.
      UPDATE yexp_get_e022 SET z_task_process_step = '02' WHERE z_task_uuid = @lv_task_uuid. "02-Scheduled Reports Mass Data Run Finished
      IF sy-subrc = 0.
        COMMIT WORK.
      ENDIF.
    ENDIF.
****************Store Response End*********************




  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.
  ENDMETHOD.
ENDCLASS.
