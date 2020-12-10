*&---------------------------------------------------------------------*
*& 包含               ZGIT_MODULE
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS_0100'.
  SET TITLEBAR 'TITLE' WITH gv_ttext.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  CASE ok_code.
    WHEN '&F03' OR '&F12'.
      FREE gcl_alv_mode.
      LEAVE TO SCREEN 0.
    WHEN '&F15'.
      LEAVE TO SCREEN 0.
    WHEN 'CLAYOUT'.
      CALL FUNCTION 'STRING_REVERSE'
        EXPORTING
          string    = gcl_alv_mode->mode
          lang      = '1'
        IMPORTING
          rstring   = gcl_alv_mode->mode
        EXCEPTIONS
          too_small = 1
          OTHERS    = 2.
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module INIT_ALV OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE init_alv OUTPUT.

  NEW gcl_alv_display( gcl_alv_mode )->alv_grid( CHANGING cmode = gcl_alv_mode ).

ENDMODULE.
