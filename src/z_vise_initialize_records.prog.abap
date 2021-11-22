*&---------------------------------------------------------------------*
*& Report  Z_VISE_INITIALIZE_RECORDS
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  z_vise_initialize_records.

PARAMETERS prog TYPE syrepid.

DELETE FROM zvise_records WHERE mainprogram = prog AND uname = sy-uname.
WRITE: 'sy-subrc', sy-subrc.
