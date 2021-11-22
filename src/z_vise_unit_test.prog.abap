*&---------------------------------------------------------------------*
*& Report  Z_VISE_UNIT_TEST
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  z_vise_unit_test.

*----------------------------------------------------------------------*
*       CLASS lcl_cl_ DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_cl_vise DEFINITION FOR TESTING. "#AU Risk_Level Harmless
  "#AU Duration Short
  PRIVATE SECTION.
    DATA ms_sflight TYPE sflight.
    DATA ms_sflight2 TYPE sflight.
    METHODS setup.
    METHODS teardown.
    METHODS no_changing_behavior FOR TESTING.
    METHODS changing_behavior FOR TESTING.
    METHODS changing_behavior_but_no_exc FOR TESTING.
    METHODS test_luw FOR TESTING.
    METHODS test_sorted_table FOR TESTING.
ENDCLASS.                    "lcl_cl_vise DEFINITION
*----------------------------------------------------------------------*
*       CLASS lcl_cl_vise IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_cl_vise IMPLEMENTATION.
  METHOD setup.
    DATA lt_sflight TYPE flighttab.
    SELECT * FROM sflight INTO TABLE lt_sflight WHERE carrid = 'LH' AND connid = '400' AND fldate = '20100520'.
    IF sy-subrc NE 0.
      ms_sflight-carrid = 'LH'.
      ms_sflight-connid = '400'.
      ms_sflight-fldate = '20100520'.
      MODIFY sflight FROM ms_sflight.
    ENDIF.

    SELECT * FROM sflight INTO TABLE lt_sflight WHERE carrid = 'LH' AND connid = '400' AND fldate = '20100912'.
    IF sy-subrc NE 0.
      ms_sflight2-carrid = 'LH'.
      ms_sflight2-connid = '400'.
      ms_sflight2-fldate = '20100912'.
      MODIFY sflight FROM ms_sflight2.
    ENDIF.
  ENDMETHOD.                    "setup

  METHOD teardown.
    IF ms_sflight IS NOT INITIAL.
      DELETE sflight FROM ms_sflight.
    ENDIF.
    IF ms_sflight2 IS NOT INITIAL.
      DELETE sflight FROM ms_sflight2.
    ENDIF.
  ENDMETHOD.                    "teardown

  METHOD no_changing_behavior.
    DATA lo_backend TYPE REF TO zcl_vise_class_under_inspect.
    DATA lt_sflight TYPE flighttab.

    zcl_vise=>release( 'Z_VISE_UNIT_TEST' ).
    CREATE OBJECT lo_backend
      EXPORTING
        iv_changes_behavior = abap_false.
    lt_sflight = lo_backend->select_sflight( iv_carrid = 'LH' iv_connid = '400' iv_date = '20100710' ).

    zcl_vise=>grip( i_data = lt_sflight ).

    CREATE OBJECT lo_backend
      EXPORTING
        iv_changes_behavior = abap_false.
    lt_sflight = lo_backend->select_sflight( iv_carrid = 'LH' iv_connid = '400' iv_date = '20100710' ).
    zcl_vise=>grip( i_data = lt_sflight ).
  ENDMETHOD.                    "no_changing_behavior

  METHOD changing_behavior.
    DATA lo_cx_vise TYPE REF TO zcx_vise.
    DATA lo_backend TYPE REF TO zcl_vise_class_under_inspect.
    DATA lt_sflight TYPE flighttab.
    zcl_vise=>release( 'Z_VISE_UNIT_TEST' ).
    CREATE OBJECT lo_backend
      EXPORTING
        iv_changes_behavior = abap_false.
    lt_sflight = lo_backend->select_sflight( iv_carrid = 'LH' iv_connid = '400' iv_date = '20100710' ).
    zcl_vise=>grip( i_data = lt_sflight ).

    TRY.
        CREATE OBJECT lo_backend
          EXPORTING
            iv_changes_behavior = abap_true.
        lt_sflight = lo_backend->select_sflight( iv_carrid = 'LH' iv_connid = '400' iv_date = '20100710' ).
        zcl_vise=>grip( i_data = lt_sflight )."is expected to raise an exception
      CATCH zcx_vise INTO lo_cx_vise.
    ENDTRY.
    cl_aunit_assert=>assert_not_initial( lo_cx_vise ).
  ENDMETHOD.                    "changing_behavior

  METHOD changing_behavior_but_no_exc.
    DATA lt_sflight TYPE flighttab.
    DATA lo_cx_vise TYPE REF TO zcx_vise.
    DATA lo_backend TYPE REF TO zcl_vise_class_under_inspect.
    DATA lt_ignore TYPE string_table.
    APPEND 'PRICE' TO lt_ignore.

    zcl_vise=>release( 'Z_VISE_UNIT_TEST' ).
    CREATE OBJECT lo_backend
      EXPORTING
        iv_changes_behavior = abap_false.
    lt_sflight = lo_backend->select_sflight( iv_carrid = 'LH' iv_connid = '400' iv_date = '20100710' ).
    zcl_vise=>grip( i_data = lt_sflight it_ignore_components = lt_ignore ).

    TRY.
        CREATE OBJECT lo_backend
          EXPORTING
            iv_changes_behavior = abap_true.
        lt_sflight = lo_backend->select_sflight( iv_carrid = 'LH' iv_connid = '400' iv_date = '20100710' ).
        zcl_vise=>grip( i_data = lt_sflight it_ignore_components = lt_ignore ).
      CATCH zcx_vise INTO lo_cx_vise.
    ENDTRY.
    cl_aunit_assert=>assert_initial( lo_cx_vise ).
  ENDMETHOD.                    "changing_behavior_but_no_exc

  METHOD test_luw.
*   the SELECT in ZVISE_RECORD is expected to be successfull if ZCL_VISE=>FLUSH_AFTER_ROLLBACK has been called after ROLLBACK WORK
    DATA lo_backend TYPE REF TO zcl_vise_class_under_inspect.
    DATA lv_count TYPE i.
    DATA ls_sflight TYPE sflight.
    zcl_vise=>release( 'Z_VISE_UNIT_TEST' ).

    CREATE OBJECT lo_backend
      EXPORTING
        iv_changes_behavior = abap_false.
    ls_sflight = lo_backend->test_transactional_integrity( ).

    SELECT COUNT( * ) INTO lv_count FROM zvise_records WHERE mainprogram = 'ZCL_VISE_CLASS_UNDER_INSPECT==CP' AND uname = sy-uname.
    cl_aunit_assert=>assert_not_initial( lv_count ).
  ENDMETHOD.                    "test_luw
  METHOD test_sorted_table.
    DATA lo_backend TYPE REF TO zcl_vise_class_under_inspect.
    DATA lt_sflight TYPE flighttab.
    DATA lt_sflight2 TYPE flighttab.
    FIELD-SYMBOLS <ls_sflight> TYPE sflight.

    zcl_vise=>release( 'Z_VISE_UNIT_TEST' ).
    CREATE OBJECT lo_backend
      EXPORTING
        iv_changes_behavior = abap_false.

    lt_sflight = lo_backend->select_sflight( iv_carrid = 'LH' iv_connid = '400' ).
    LOOP AT lt_sflight ASSIGNING <ls_sflight>.
      <ls_sflight>-price = sy-tabix.
    ENDLOOP.
    lt_sflight2 = lt_sflight.

    SORT lt_sflight BY price ASCENDING."make it hard for vise to compare identical, but differently sorted tables
    SORT lt_sflight2 BY price DESCENDING.

    zcl_vise=>grip( i_data = lt_sflight iv_sort_field01 = 'CARRID' iv_sort_field02 = 'CONNID' iv_sort_field03 = 'FLDATE' ).
    zcl_vise=>grip( i_data = lt_sflight2 iv_sort_field01 = 'CARRID' iv_sort_field02 = 'CONNID' iv_sort_field03 = 'FLDATE' )."should not raise any exception
  ENDMETHOD.                    "test_sorted_table
ENDCLASS.                    "lcl_cl_vise IMPLEMENTATION
