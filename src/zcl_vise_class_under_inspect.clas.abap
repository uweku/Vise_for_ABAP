class ZCL_VISE_CLASS_UNDER_INSPECT definition
  public
  create public .

public section.

  methods SELECT_SFLIGHT
    importing
      !IV_CARRID type S_CARR_ID
      !IV_CONNID type S_CONN_ID
      !IV_DATE type S_DATE optional
    returning
      value(RT_SFLIGHT) type FLIGHTTAB .
  methods CONSTRUCTOR
    importing
      !IV_CHANGES_BEHAVIOR type ABAP_BOOL .
  methods TEST_TRANSACTIONAL_INTEGRITY
    returning
      value(RS_NOT_COMMITED_SFLIGHT) type SFLIGHT .
protected section.

  data MV_CHANGES_BEHAVIOR type ABAP_BOOL .
private section.
ENDCLASS.



CLASS ZCL_VISE_CLASS_UNDER_INSPECT IMPLEMENTATION.


METHOD constructor.
  mv_changes_behavior = iv_changes_behavior.
ENDMETHOD.


METHOD select_sflight.
  FIELD-SYMBOLS <ls_sflight> TYPE sflight.
  IF iv_carrid IS NOT INITIAL AND iv_connid IS NOT INITIAL AND iv_date IS NOT INITIAL.
    SELECT * FROM sflight INTO TABLE rt_sflight WHERE carrid = iv_carrid AND connid = iv_connid AND fldate = iv_date.
  ELSEIF iv_carrid IS NOT INITIAL AND iv_connid IS NOT INITIAL.
    SELECT * FROM sflight INTO TABLE rt_sflight WHERE carrid = iv_carrid AND connid = iv_connid.
  ENDIF.
  IF mv_changes_behavior = abap_true."change some values
    LOOP AT rt_sflight ASSIGNING <ls_sflight>.
      <ls_sflight>-price = <ls_sflight>-price + 1.
    ENDLOOP.
  ENDIF.
ENDMETHOD.


METHOD test_transactional_integrity.

  rs_not_commited_sflight-carrid = 'UK'.
  rs_not_commited_sflight-connid = '1985'.
  rs_not_commited_sflight-fldate = '20100520'.

  DELETE sflight FROM rs_not_commited_sflight.
  COMMIT WORK.

  MODIFY sflight FROM rs_not_commited_sflight.
  TRY.
      zcl_vise=>grip( rs_not_commited_sflight ).
    CATCH cx_root.
      "we aren't really interested in what vise says..
      "rather if the following ROLLBACK will rollback the currently inserted entry or not
  ENDTRY.
  ROLLBACK WORK.
ENDMETHOD.
ENDCLASS.
