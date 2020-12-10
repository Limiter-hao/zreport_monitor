class ZCL_MSG definition
  public
  final
  create public .

public section.

  interfaces ZIF_MSG .

  aliases HANDLE_MSG
    for ZIF_MSG~HANDLE_MSG .

  methods DISPLAY_MSG
    for event DISPLAY_MSG of ZIF_MSG
    importing
      !TYPE
      !MSG .
protected section.
private section.
ENDCLASS.



CLASS ZCL_MSG IMPLEMENTATION.


  METHOD display_msg.

    zif_msg~handle_msg = 'X'.
    IF sy-batch = abap_false."控制下后台模式的话不弹消息
      MESSAGE msg TYPE 'I' DISPLAY LIKE  type.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
