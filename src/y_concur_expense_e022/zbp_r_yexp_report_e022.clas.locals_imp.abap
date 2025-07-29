CLASS lhc_zr_yexp_report_e022 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR zr_yexp_report_e022 RESULT result.

ENDCLASS.

CLASS lhc_zr_yexp_report_e022 IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

ENDCLASS.
