class ZCL_VISE definition
  public
  final
  create public .

public section.
  type-pools ABAP .

  class-methods CLASS_CONSTRUCTOR .
  class-methods GRIP
    importing
      !I_DATA type DATA
      !IV_NAME type ZNAME_OF_VALUE optional
      !IT_IGNORE_COMPONENTS type STRING_TABLE optional
      !IV_SORT_FIELD01 type NAME_FELD optional
      !IV_SORT_FIELD02 type NAME_FELD optional
      !IV_SORT_FIELD03 type NAME_FELD optional .
  class-methods RELEASE
    importing
      !IV_REPID type SYREPID
      !IV_UNAME type UBNAME default SY-UNAME .
protected section.

  class-data:
    mt_vise_records TYPE TABLE OF zvise_records .

  class-methods FLUSH_AFTER_ROLLBACK
    for event TRANSACTION_FINISHED of CL_SYSTEM_TRANSACTION_STATE
    importing
      !KIND .
  class-methods REGISTER_DB_OP_AFTER_ROLLBACK
    importing
      !IS_RECORD type ZVISE_RECORDS .
  class-methods RAISE_ROLLBACK .
private section.
ENDCLASS.



CLASS ZCL_VISE IMPLEMENTATION.


METHOD class_constructor.
  SET HANDLER flush_after_rollback.
ENDMETHOD.


METHOD flush_after_rollback.
  DATA ls_record TYPE zvise_records.
  DATA lv_task TYPE string.
  IF kind NE cl_system_transaction_state=>rollback_work.
    RETURN.
  ENDIF.
  LOOP AT mt_vise_records INTO ls_record.
    lv_task = sy-tabix.
    IF ls_record-blocktype IS NOT INITIAL.
      MODIFY zvise_records FROM ls_record.
    ELSE.
      DELETE FROM zvise_records WHERE mainprogram = ls_record-mainprogram AND uname = ls_record-uname.
    ENDIF.
  ENDLOOP.
  FREE: mt_vise_records.
ENDMETHOD.


METHOD grip.
  DATA: lt_abap_callstack TYPE abap_callstack.
  DATA: ls_abap_callstack TYPE abap_callstack_line.
  DATA ls_record TYPE zvise_records.
  FIELD-SYMBOLS <lv_data> TYPE any.
  FIELD-SYMBOLS <ls_data> TYPE any.
  DATA lv_component TYPE string.

  DATA lv_previous_content TYPE string.
  DATA lo_elem_descr TYPE REF TO cl_abap_elemdescr.
  DATA lo_struct_descr TYPE REF TO cl_abap_structdescr.

  FIELD-SYMBOLS <l_any> TYPE ANY TABLE.
  FIELD-SYMBOLS <ls_any> TYPE any.
  DATA lr_data TYPE REF TO data.
  DATA lv_type_kind TYPE abap_typekind.

  CALL FUNCTION 'SYSTEM_CALLSTACK'
    IMPORTING
      callstack = lt_abap_callstack.

  READ TABLE lt_abap_callstack INTO ls_abap_callstack INDEX 2.
  CHECK sy-subrc = 0.

  MOVE-CORRESPONDING ls_abap_callstack TO ls_record.
  ls_record-value_name = iv_name.
  ls_record-uname = sy-uname.

  IF it_ignore_components IS NOT INITIAL OR iv_sort_field01 IS NOT INITIAL OR iv_sort_field02 IS NOT INITIAL OR iv_sort_field03 IS NOT INITIAL.
    TRY.
        lo_elem_descr ?= cl_abap_typedescr=>describe_by_data( i_data ).
      CATCH cx_sy_move_cast_error.
    ENDTRY.

    TRY.
        lo_struct_descr ?= cl_abap_typedescr=>describe_by_data( i_data ).
        CREATE DATA lr_data LIKE i_data.
        ASSIGN lr_data->* TO <ls_any>.

        ASSIGN COMPONENT lv_component OF STRUCTURE <ls_any> TO <lv_data>.
        IF sy-subrc = 0.
          CLEAR: <lv_data>.
        ENDIF.
        CALL TRANSFORMATION id SOURCE value = <ls_any> RESULT XML ls_record-content.

      CATCH cx_sy_move_cast_error.
    ENDTRY.

    TRY.
        CREATE DATA lr_data LIKE i_data.
        ASSIGN lr_data->* TO <l_any>.
        <l_any> = i_data.

        lv_type_kind = cl_abap_datadescr=>get_data_type_kind( p_data = <l_any> ).

        CASE lv_type_kind.
          WHEN cl_abap_datadescr=>typekind_struct1 OR cl_abap_datadescr=>typekind_struct2.
            "currently not supported
          WHEN cl_abap_datadescr=>typekind_table.
            LOOP AT it_ignore_components INTO lv_component.
              LOOP AT <l_any> ASSIGNING <ls_data>.
                ASSIGN COMPONENT lv_component OF STRUCTURE <ls_data> TO <lv_data>.
                IF sy-subrc = 0.
                  CLEAR: <lv_data>.
                ENDIF.
              ENDLOOP.
            ENDLOOP.
        ENDCASE.

        IF iv_sort_field01 IS NOT INITIAL AND iv_sort_field02 IS INITIAL AND iv_sort_field03 IS INITIAL.
          SORT <l_any> BY (iv_sort_field01).
        ENDIF.
        IF iv_sort_field01 IS NOT INITIAL AND iv_sort_field02 IS NOT INITIAL AND iv_sort_field03 IS INITIAL.
          SORT <l_any> BY (iv_sort_field01) (iv_sort_field02).
        ENDIF.
        IF iv_sort_field01 IS NOT INITIAL AND iv_sort_field02 IS NOT INITIAL AND iv_sort_field03 IS NOT INITIAL.
          SORT <l_any> BY (iv_sort_field01) (iv_sort_field02) (iv_sort_field03).
        ENDIF.
        CALL TRANSFORMATION id SOURCE value = <l_any> RESULT XML ls_record-content.
      CATCH cx_sy_move_cast_error.
    ENDTRY.
  ENDIF.

  IF ls_record-content IS INITIAL.
    CALL TRANSFORMATION id SOURCE value = i_data RESULT XML ls_record-content.
  ENDIF.

  SELECT SINGLE content FROM zvise_records INTO lv_previous_content
    WHERE mainprogram = ls_record-mainprogram
    AND include     = ls_record-include
    AND blocktype   = ls_record-blocktype
    AND blockname   = ls_record-blockname
    AND value_name  = ls_record-value_name
    AND uname = ls_record-uname
    AND is_error_record = abap_false.
  IF sy-subrc = 0.
    IF lv_previous_content NE ls_record-content.
      RAISE EXCEPTION TYPE zcx_vise.
    ENDIF.
  ENDIF.

  CHECK ls_record IS NOT INITIAL.
  MODIFY zvise_records FROM ls_record.

  register_db_op_after_rollback( ls_record ).
ENDMETHOD.                    "grip


METHOD raise_rollback.
  ROLLBACK WORK.
  RAISE EXCEPTION TYPE zcx_vise_forced_rollback.
ENDMETHOD.


METHOD register_db_op_after_rollback.
    APPEND is_record TO mt_vise_records.
  ENDMETHOD.                    "register_db_op_after_rollback


METHOD release.
  DATA ls_record TYPE zvise_records.
  ls_record-mainprogram = iv_repid.
  ls_record-uname = iv_uname.

  DELETE FROM zvise_records WHERE mainprogram = iv_repid AND uname = iv_uname.
  register_db_op_after_rollback( ls_record ).
ENDMETHOD.                    "release
ENDCLASS.
