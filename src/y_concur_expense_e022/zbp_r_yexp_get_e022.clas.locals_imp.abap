CLASS lsc_zr_yexp_get_e022 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_zr_yexp_get_e022 IMPLEMENTATION.

  METHOD save_modified.

    DATA lt_zr_yexp_get_e022 TYPE STANDARD TABLE OF zr_yexp_get_e022.

    IF update-zr_yexp_get_e022 IS NOT INITIAL.

      lt_zr_yexp_get_e022 = CORRESPONDING #( update-zr_yexp_get_e022 ).

      LOOP AT lt_zr_yexp_get_e022 INTO DATA(lwa_zr_yexp_get_e022).

        IF lwa_zr_yexp_get_e022-ztaskuuid IS NOT INITIAL AND lwa_zr_yexp_get_e022-ztaskprocessstep = '01'. "01-Schedule reports Mass Data Run

          TRY.

              DATA job_start_info TYPE cl_apj_rt_api=>ty_start_info.
              DATA job_parameter TYPE cl_apj_rt_api=>ty_job_parameter_value.
              DATA range_value TYPE cl_apj_rt_api=>ty_value_range.
              DATA job_template_name TYPE cl_apj_rt_api=>ty_template_name.
              DATA job_parameters TYPE cl_apj_rt_api=>tt_job_parameter_value.
              DATA job_name TYPE cl_apj_rt_api=>ty_jobname.
              DATA job_count TYPE cl_apj_rt_api=>ty_jobcount.

              job_template_name = 'Y_CONCUR_REPORTS_TEMPLATE'.

              job_start_info-start_immediately = abap_true.

              job_parameter-name = 'UUID'.
              range_value-sign = 'I'.
              range_value-option = 'EQ'.
              range_value-low = lwa_zr_yexp_get_e022-ztaskuuid.
              APPEND range_value TO job_parameter-t_value.
              APPEND job_parameter TO job_parameters.

              cl_apj_rt_api=>schedule_job(
                  EXPORTING
                  iv_job_template_name = job_template_name
                  iv_job_text = 'Retrieve Reports From Concur'
                  is_start_info = job_start_info
                  it_job_parameter_value = job_parameters
                  IMPORTING
                  ev_jobname  = job_name
                  ev_jobcount = job_count
                  ).

            CATCH cx_apj_rt INTO DATA(job_scheduling_error).

          ENDTRY.
        ENDIF.

        IF lwa_zr_yexp_get_e022-ztaskuuid IS NOT INITIAL AND lwa_zr_yexp_get_e022-ztaskprocessstep = '03'. "03-Schedule Post Invoice Mass Data Run

          TRY.

              job_template_name = 'Y_CONCUR_SINV_TEMPLATE'.

              job_start_info-start_immediately = abap_true.

              job_parameter-name = 'UUID'.
              range_value-sign = 'I'.
              range_value-option = 'EQ'.
              range_value-low = lwa_zr_yexp_get_e022-ztaskuuid.
              APPEND range_value TO job_parameter-t_value.
              APPEND job_parameter TO job_parameters.

              cl_apj_rt_api=>schedule_job(
                  EXPORTING
                  iv_job_template_name = job_template_name
                  iv_job_text = 'Concur Integration - Post Supplier Invoices'
                  is_start_info = job_start_info
                  it_job_parameter_value = job_parameters
                  IMPORTING
                  ev_jobname  = job_name
                  ev_jobcount = job_count
                  ).

            CATCH cx_apj_rt INTO job_scheduling_error.

          ENDTRY.
        ENDIF.

      ENDLOOP.
    ENDIF.

  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_zr_yexp_get_e022 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR zr_yexp_get_e022 RESULT result.

    METHODS retrieve_report FOR MODIFY
      IMPORTING keys FOR ACTION zr_yexp_get_e022~retrieve_report.

    METHODS generate_taskid FOR DETERMINE ON SAVE
      IMPORTING keys FOR zr_yexp_get_e022~generate_taskid.
    METHODS refresh FOR MODIFY
      IMPORTING keys FOR ACTION zr_yexp_get_e022~refresh.
    METHODS post_invoice FOR MODIFY
      IMPORTING keys FOR ACTION zr_yexp_get_e022~post_invoice.

ENDCLASS.

CLASS lhc_zr_yexp_get_e022 IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD retrieve_report.

    DATA lv_task_uuid TYPE zr_yexp_get_e022-ztaskuuid.
    DATA lv_filter_by TYPE string.
    DATA lv_report_id TYPE string.
    DATA lv_filter_from TYPE string.
    DATA lv_filter_to TYPE string.
    DATA lv_process_step TYPE string.

    READ ENTITIES OF zr_yexp_get_e022 IN LOCAL MODE
      ENTITY zr_yexp_get_e022
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_zr_yexp_get_e022).

    IF lt_zr_yexp_get_e022 IS NOT INITIAL.
      LOOP AT lt_zr_yexp_get_e022 INTO DATA(lwa_zr_yexp_get_e022).
        lv_task_uuid = lwa_zr_yexp_get_e022-ztaskuuid.
        lv_filter_by = lwa_zr_yexp_get_e022-zfilterby.
        lv_report_id = lwa_zr_yexp_get_e022-zreportid.
        lv_filter_from = lwa_zr_yexp_get_e022-zfilterfrom.
        lv_filter_to = lwa_zr_yexp_get_e022-zfilterto.
        lv_process_step = lwa_zr_yexp_get_e022-ztaskprocessstep.
        EXIT.
      ENDLOOP.
    ENDIF.

    IF lv_task_uuid IS NOT INITIAL AND lv_process_step = '00'.
      IF lv_filter_by IS NOT INITIAL.
        IF lv_filter_by = 'Report ID'.
          IF lv_report_id IS NOT INITIAL.
            MODIFY ENTITIES OF zr_yexp_get_e022
                ENTITY zr_yexp_get_e022
                    UPDATE
                        SET FIELDS WITH VALUE
                        #(
                            (
                                ztaskuuid = lv_task_uuid
                                ztaskprocessstep = '01' "01-Schedule reports Mass Data Run
                                ztaskstatus = 'Reports Retrieving, Click Refresh For Current Status'
                            )
                         )
                     FAILED DATA(failed_info)
                     REPORTED DATA(reported_info).
          ELSE.
            APPEND VALUE #( ztaskuuid = lv_task_uuid
                 %msg = new_message_with_text(
                             severity = if_abap_behv_message=>severity-information
                             text = 'Report ID is Missing...' )
                ) TO reported-zr_yexp_get_e022.
          ENDIF.
        ENDIF.
        IF lv_filter_by = 'Report Date'.
          IF lv_filter_from NE '00000000' AND lv_filter_to NE '00000000'.
            MODIFY ENTITIES OF zr_yexp_get_e022
                ENTITY zr_yexp_get_e022
                    UPDATE
                        SET FIELDS WITH VALUE
                        #(
                            (
                                ztaskuuid = lv_task_uuid
                                ztaskprocessstep = '01' "01-Schedule reports Mass Data Run
                                ztaskstatus = 'Reports Retrieving, Click Refresh For Current Status'
                            )
                         )
                     FAILED failed_info
                     REPORTED reported_info.
          ELSE.
            APPEND VALUE #( ztaskuuid = lv_task_uuid
                 %msg = new_message_with_text(
                             severity = if_abap_behv_message=>severity-information
                             text = 'Start Date Or End Date Missing...' )
                ) TO reported-zr_yexp_get_e022.
          ENDIF.
        ENDIF.
      ELSE.
        APPEND VALUE #( ztaskuuid = lv_task_uuid
                         %msg = new_message_with_text(
                                     severity = if_abap_behv_message=>severity-information
                                     text = 'Please Ensure Filter By Field to continue...' )
                        ) TO reported-zr_yexp_get_e022.
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD generate_taskid.

    LOOP AT keys INTO DATA(ls_key).
      SELECT FROM zr_yexp_get_e022 FIELDS COUNT( ztaskid ) INTO @DATA(lv_last_id).
      lv_last_id = lv_last_id + 1.
      MODIFY ENTITIES OF zr_yexp_get_e022 IN LOCAL MODE
          ENTITY zr_yexp_get_e022
          UPDATE SET FIELDS WITH VALUE #(
                  (
                      ztaskuuid = ls_key-ztaskuuid
                      ztaskid   = 'Task-' && lv_last_id
                      ztaskstatus = 'In Preparation'
                      ztaskprocessstep = '00' "00-Open Status
                  ) )
          REPORTED DATA(update_reported).
      reported = CORRESPONDING #( DEEP update_reported ).
    ENDLOOP.

  ENDMETHOD.

  METHOD refresh.

    DATA lv_task_uuid TYPE zr_yexp_get_e022-ztaskuuid.
    DATA lv_task_process_step TYPE zr_yexp_get_e022-ztaskprocessstep.

    READ ENTITIES OF zr_yexp_get_e022 IN LOCAL MODE
      ENTITY zr_yexp_get_e022
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_zr_yexp_get_e022).

    IF lt_zr_yexp_get_e022 IS NOT INITIAL.
      LOOP AT lt_zr_yexp_get_e022 INTO DATA(lwa_zr_yexp_get_e022).
        lv_task_uuid = lwa_zr_yexp_get_e022-ztaskuuid.
        lv_task_process_step = lwa_zr_yexp_get_e022-ztaskprocessstep.
        EXIT.
      ENDLOOP.
    ENDIF.

    IF lv_task_uuid IS NOT INITIAL AND lv_task_process_step EQ '02'. "02-Scheduled Reports Mass Data Run Finished

      SELECT * FROM yexp_report_e022 WHERE z_task_uuid = @lv_task_uuid INTO TABLE @DATA(lt_yexp_report_e022).

      IF lt_yexp_report_e022 IS NOT INITIAL.
        MODIFY ENTITIES OF zr_yexp_get_e022
           ENTITY zr_yexp_get_e022
               UPDATE
                   SET FIELDS WITH VALUE
                   #(
                       (
                           ztaskuuid = lv_task_uuid
                           ztaskprocessstep = '00' "00-Open Status
                           ztaskstatus = 'Reports Retrieved From Concur'
                       )
                    )
                FAILED DATA(failed_info)
                REPORTED DATA(reported_info).
      ELSE.
        MODIFY ENTITIES OF zr_yexp_get_e022
          ENTITY zr_yexp_get_e022
              UPDATE
                  SET FIELDS WITH VALUE
                  #(
                      (
                          ztaskuuid = lv_task_uuid
                          ztaskprocessstep = '00' "00-Open Status
                          ztaskstatus = 'Reports Not Found'
                      )
                   )
               FAILED failed_info
               REPORTED reported_info.
      ENDIF.
    ENDIF.

    IF lv_task_uuid IS NOT INITIAL AND lv_task_process_step EQ '04'. "04-Scheduled Post Invoice Mass Data Run Finished
      MODIFY ENTITIES OF zr_yexp_get_e022
        ENTITY zr_yexp_get_e022
            UPDATE
                SET FIELDS WITH VALUE
                #(
                    (
                        ztaskuuid = lv_task_uuid
                        ztaskprocessstep = '00' "00-Open Status
                        ztaskstatus = 'Supplier Invoices Posted'
                    )
                 )
             FAILED failed_info
             REPORTED reported_info.
    ENDIF.

    IF lv_task_uuid IS NOT INITIAL.
      APPEND VALUE #( ztaskuuid = lwa_zr_yexp_get_e022-ztaskuuid
   %msg = new_message_with_text(
               severity = if_abap_behv_message=>severity-success
               text = 'Screen Refreshed' )
  ) TO reported-zr_yexp_get_e022.
    ENDIF.

  ENDMETHOD.

  METHOD post_invoice.

    DATA lv_task_uuid TYPE zr_yexp_get_e022-ztaskuuid.
    DATA lv_process_step TYPE string.

    READ ENTITIES OF zr_yexp_get_e022 IN LOCAL MODE
      ENTITY zr_yexp_get_e022
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_zr_yexp_get_e022).

    IF lt_zr_yexp_get_e022 IS NOT INITIAL.
      LOOP AT lt_zr_yexp_get_e022 INTO DATA(lwa_zr_yexp_get_e022).
        lv_task_uuid = lwa_zr_yexp_get_e022-ztaskuuid.
        lv_process_step = lwa_zr_yexp_get_e022-ztaskprocessstep.
        EXIT.
      ENDLOOP.
    ENDIF.

    IF lv_task_uuid IS NOT INITIAL AND lv_process_step = '00'.

      DATA(lv_reports_check) = abap_false.

      SELECT * FROM yexp_report_e022 WHERE z_task_uuid = @lv_task_uuid AND z_report_status = 'In Preparation' INTO TABLE @DATA(lt_yexp_report_e022).
      IF lt_yexp_report_e022 IS NOT INITIAL.
        lv_reports_check = abap_true.
      ENDIF.

      IF lv_reports_check = abap_true.
        MODIFY ENTITIES OF zr_yexp_get_e022
          ENTITY zr_yexp_get_e022
              UPDATE
                  SET FIELDS WITH VALUE
                  #(
                      (
                          ztaskuuid = lv_task_uuid
                          ztaskprocessstep = '03' "03-Schedule Post Invoice Mass Data Run
                          ztaskstatus = 'Invoice Posting, Click Refresh For Current Status'
                      )
                   )
               FAILED DATA(failed_info)
               REPORTED DATA(reported_info).
      ELSE.
        APPEND VALUE #( ztaskuuid = lwa_zr_yexp_get_e022-ztaskuuid
         %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-success
                     text = 'No Reports Found, Post Invoice Not Possible.' )
        ) TO reported-zr_yexp_get_e022.
      ENDIF.

    ENDIF.

  ENDMETHOD.

ENDCLASS.
