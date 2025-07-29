CLASS lhc_zr_yconfig_e022 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR zr_yconfig_e022
        RESULT result,
      getaccesstoken FOR MODIFY
        IMPORTING keys FOR ACTION zr_yconfig_e022~getaccesstoken.
ENDCLASS.

CLASS lhc_zr_yconfig_e022 IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD getaccesstoken.

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

    READ ENTITIES OF zr_yconfig_e022 IN LOCAL MODE
    ENTITY zr_yconfig_e022
    ALL FIELDS WITH
    CORRESPONDING #( keys )
    RESULT DATA(lt_zr_yconfig_e022).

    IF lt_zr_yconfig_e022 IS NOT INITIAL.
      LOOP AT lt_zr_yconfig_e022 INTO DATA(lwa_zr_yconfig_e022).
        IF lwa_zr_yconfig_e022-zuuid IS NOT INITIAL.
          lv_uuid = lwa_zr_yconfig_e022-zuuid.
          EXIT.
        ENDIF.
      ENDLOOP.
    ENDIF.

    IF lt_zr_yconfig_e022 IS NOT INITIAL.
      LOOP AT lt_zr_yconfig_e022 INTO lwa_zr_yconfig_e022.
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
      ENDLOOP.
    ENDIF.

    IF lv_refresh_token IS NOT INITIAL AND
       lv_access_token IS NOT INITIAL.

      IF lv_uuid IS NOT INITIAL.
        MODIFY ENTITIES OF zr_yconfig_e022
            ENTITY zr_yconfig_e022
                UPDATE
                    SET FIELDS WITH VALUE
                    #(
                        (
                            zuuid = lv_uuid
                            zrefreshtoken = lv_refresh_token
                            zstatuscode = lv_response_code
                        )
                     )
                 FAILED DATA(failed_info)
                 REPORTED DATA(reported_info).

          APPEND VALUE #( zuuid = lv_uuid
          %msg = new_message_with_text(
                      severity = if_abap_behv_message=>severity-success
                      text = 'Access Token Generation Succeed.' )
         ) TO reported-zr_yconfig_e022.

      ENDIF.
    ELSE.
      MODIFY ENTITIES OF zr_yconfig_e022
          ENTITY zr_yconfig_e022
              UPDATE
                  SET FIELDS WITH VALUE
                  #(
                      (
                          zuuid = lv_uuid
                          zstatuscode = lv_response_code
                      )
                   )
               FAILED failed_info
               REPORTED reported_info.

          APPEND VALUE #( zuuid = lv_uuid
          %msg = new_message_with_text(
                      severity = if_abap_behv_message=>severity-information
                      text = 'Access Token Generation Failed.' )
         ) TO reported-zr_yconfig_e022.

    ENDIF.

  ENDMETHOD.

ENDCLASS.
