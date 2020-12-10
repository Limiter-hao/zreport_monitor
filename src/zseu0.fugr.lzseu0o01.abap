***INCLUDE LSEU0O01 .
MODULE INIT_SCREEN OUTPUT.
  IF SY-DYNNR = '0120'.     SET PF-STATUS 'CUA_POPF'.
  ELSEIF SY-DYNNR = '0191'. SET PF-STATUS 'PRINT'.
  ELSE.                     SET PF-STATUS 'CUA_POP'.
  ENDIF.
  CASE SY-DYNNR.
    WHEN 100. SET TITLEBAR 'ADD'.              " Status hinzufügen
    WHEN 120. SET TITLEBAR 'DEL'.
    WHEN 111. SET TITLEBAR 'COA'.              " Oberfläce kopieren
    WHEN 113. SET TITLEBAR 'COA'.              " Oberfläce umbenennen
    WHEN 112. SET TITLEBAR 'ROA'.              " Oberfläce umbenennen
    WHEN 191. SET TITLEBAR 'PRI' WITH RSMPE-PROGRAM RSMPE-STATUS.
    WHEN 210. SET TITLEBAR 'SEA'.              " Titel hinzufügen
  ENDCASE.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  INIT_SCREEN_TIT  OUTPUT
*&---------------------------------------------------------------------*
MODULE INIT_SCREEN_TIT OUTPUT.
  CASE CUA_ACTIVE.
    WHEN 'C'. SET PF-STATUS 'COPY_TIT'.       " Titel kopieren
              SET TITLEBAR 'TTC'.
    WHEN 'R'. SET PF-STATUS 'RNAM_TIT'.       " Titel umbenennen
              SET TITLEBAR 'TTR'.
  ENDCASE.
ENDMODULE.
