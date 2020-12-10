class ZCL_ALV_DATA definition
  public
  create public .

public section.

  interfaces ZIF_MSG .

  aliases HANDLE_MSG
    for ZIF_MSG~HANDLE_MSG .
  aliases DISPLAY_MSG
    for ZIF_MSG~DISPLAY_MSG .

  methods MAIN .
  methods AUTHOR_CHECK .
  methods GET_DATA .
  methods DEAL_DATA .
protected section.
private section.
ENDCLASS.



CLASS ZCL_ALV_DATA IMPLEMENTATION.


  method AUTHOR_CHECK.
  endmethod.


  method DEAL_DATA.
  endmethod.


  METHOD GET_DATA.

*    RAISE EVENT display_msg EXPORTING type = 'W' msg = '未查询到数据'.

  ENDMETHOD.


  METHOD MAIN.

    get_data( )."取数
    deal_data( )."数据处理

  ENDMETHOD.
ENDCLASS.
