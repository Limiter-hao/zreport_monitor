class ZCL_ALV_MODE definition
  public
  final
  create public .

public section.

  interfaces ZIF_ALV_MODE
      data values DYNNR = '0100' .

  aliases CON
    for ZIF_ALV_MODE~CON .
  aliases DYNNR
    for ZIF_ALV_MODE~DYNNR .
  aliases MODE
    for ZIF_ALV_MODE~MODE .
  aliases NUMBER
    for ZIF_ALV_MODE~NUMBER .
  aliases REPID
    for ZIF_ALV_MODE~REPID .
  aliases TREE
    for ZIF_ALV_MODE~TREE .
  aliases T_MODE
    for ZIF_ALV_MODE~T_MODE .
  aliases ZIFLOG
    for ZIF_ALV_MODE~ZIFLOG .

  data HORIZONTAL type ABAP_BOOL .

  methods CONSTRUCTOR
    importing
      value(IV_REPID) type REPID optional .
protected section.
private section.
ENDCLASS.



CLASS ZCL_ALV_MODE IMPLEMENTATION.


  METHOD constructor.

    repid = iv_repid.

  ENDMETHOD.
ENDCLASS.
