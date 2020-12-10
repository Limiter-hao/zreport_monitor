class ZCL_ALV_REFRESH definition
  public
  final
  create public .

public section.

  class-methods DO
    importing
      value(I_GRID) type ref to CL_GUI_ALV_GRID .
protected section.
private section.
ENDCLASS.



CLASS ZCL_ALV_REFRESH IMPLEMENTATION.


  METHOD do.

    "获取当前alv的layout
    DATA ls_layout TYPE lvc_s_layo.
    i_grid->get_frontend_layout(  IMPORTING es_layout = ls_layout ).

    "SAPBUG,获取到的layout的CWIDTH_OPT 参数，赋值X，但是获取到的是1
    ls_layout-cwidth_opt = abap_true.

    "给alv类重置layout
    i_grid->set_frontend_layout( ls_layout ).

    "刷新
    i_grid->refresh_table_display(
                      is_stable = VALUE #( row = abap_true col = abap_true )  ).

  ENDMETHOD.
ENDCLASS.
