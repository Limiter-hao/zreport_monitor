class ZCL_EVENT_RECEIVER definition
  public
  create public .

public section.

  interfaces ZIF_MSG .

  data GCL_ALV_GRID type ref to CL_GUI_ALV_GRID .
  data OBJID type CHAR10 .
  data REPID type REPID .

  methods CONSTRUCTOR
    importing
      value(I_OBJID) type CHAR10 optional
      value(I_REPID) type REPID optional .
  methods HANDLE_TOOLBAR
    for event TOOLBAR of CL_GUI_ALV_GRID
    importing
      !E_OBJECT .
  methods HANDLE_USER_COMMAND
    for event USER_COMMAND of CL_GUI_ALV_GRID
    importing
      !E_UCOMM .
  methods MENU_BUTTON
    for event MENU_BUTTON of CL_GUI_ALV_GRID
    importing
      !E_OBJECT
      !E_UCOMM .
  methods HANDLE_DOUBLE_CLICK
    for event DOUBLE_CLICK of CL_GUI_ALV_GRID
    importing
      !E_ROW
      !E_COLUMN
      !ES_ROW_NO .
  methods HANDLE_DATA_CHANGED
    for event DATA_CHANGED of CL_GUI_ALV_GRID
    importing
      !ER_DATA_CHANGED .
  methods DATA_CHANGED_FINISHED
    for event DATA_CHANGED_FINISHED of CL_GUI_ALV_GRID
    importing
      !E_MODIFIED
      !ET_GOOD_CELLS .
  methods ON_F4
    for event ONF4 of CL_GUI_ALV_GRID
    importing
      !E_FIELDNAME
      !E_FIELDVALUE
      !ES_ROW_NO
      !ER_EVENT_DATA
      !ET_BAD_CELLS
      !E_DISPLAY .
  methods ON_F1
    for event ONF1 of CL_GUI_ALV_GRID
    importing
      !E_FIELDNAME
      !ES_ROW_NO
      !ER_EVENT_DATA .
  methods HANDLE_HOTSPOT_CLICK
    for event HOTSPOT_CLICK of CL_GUI_ALV_GRID
    importing
      !E_ROW_ID
      !E_COLUMN_ID
      !ES_ROW_NO .
protected section.

  methods CHECK_DATA
    importing
      !PS_MAT type LVC_S_MODI
      !PR_DATA_CHANGED type ref to CL_ALV_CHANGED_DATA_PROTOCOL .
  methods DEFAULT_TOOBAR
    importing
      !E_OBJECT type ref to CL_ALV_EVENT_TOOLBAR_SET
      !CMODE type ref to ZCL_ALV_MODE .
  methods DEFAULT_USER_COMMAND
    importing
      !CMODE type ref to ZCL_ALV_MODE
      !E_UCOMM type SY-UCOMM .
  methods GET_ROW_DATA
    importing
      !CMODE type ref to ZCL_ALV_MODE
      !ES_ROW_NO type LVC_S_ROID
    returning
      value(SDATA) type ref to DATA .
  methods DEFAULT_HOTSPOT_CLICK
    importing
      !SDATA type ref to DATA
      !E_COLUMN_ID type LVC_S_COL
      !ZIFLOG type ZE_GIT_IFLOG optional .
  methods REFRESH
    importing
      !ALV_GRID type ref to CL_GUI_ALV_GRID .
private section.

  data ERROR_IN_DATA type CHAR1 .
ENDCLASS.



CLASS ZCL_EVENT_RECEIVER IMPLEMENTATION.


  METHOD check_data.

*    read table gt_head  into gs_head index ps_mat-row_id.
*
*    DATA ls_head LIKE gs_head.
*
*    FIELD-SYMBOLS <fs> TYPE any.
*
*    ASSIGN COMPONENT  ps_mat-fieldname OF STRUCTURE ls_head TO <fs>.
*
*    CALL METHOD pr_data_changed->get_cell_value
*      EXPORTING
*        i_row_id    = ps_mat-row_id
*        i_fieldname = ps_mat-fieldname
*      IMPORTING
*        e_value     = <fs>.
*
*    DATA lv_error TYPE c.
*
*    CASE ps_mat-fieldname.
*
*      WHEN 'ZHSL'.
*
*
*        IF <fs> > gs_head-labst.
*
*          lv_error = 'X'.
*          RAISE EVENT zif_msg~display_msg EXPORTING iv_type = 'W' iv_msg = '转换数量不允许大于库存数量'.
*        ELSE.
*
*        ENDIF.
*
*    ENDCASE.
*
*    IF lv_error = 'X'.
*
*      CALL METHOD pr_data_changed->modify_cell
*        EXPORTING
*          i_row_id    = ps_mat-row_id
*          i_fieldname = ps_mat-fieldname
*          i_value     = <fs>.
*
*    ELSE.
*
*      MODIFY gt_head FROM gs_head INDEX ps_mat-row_id.
*
*    ENDIF.
*
*    CLEAR gs_head.
  ENDMETHOD.


  METHOD constructor.

    objid = i_objid.
    repid = i_repid.

  ENDMETHOD.


  method DATA_CHANGED_FINISHED.
  endmethod.


  METHOD default_hotspot_click.

    ASSIGN sdata->* TO FIELD-SYMBOL(<fs_data>).

    CASE e_column_id-fieldname.

        "点击状态栏按钮，弹出消息框,调用了标准slgd的
      WHEN 'ICON'.

        IF ziflog = abap_true.
          ASSIGN COMPONENT 'BALOGNR' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<balognr>).

          IF sy-subrc = 0.

            CHECK <balognr> IS NOT INITIAL.
            "这里使用了zcl_logger_factory 来创建log,没有的话可以不用
*            DATA(log) = zcl_logger_factory=>create_log( object = repid
*                                                        subobject = 'BAPI').
*
*            log->single_search( object = repid
*            subobject = 'BAPI'
*            lognumber = <balognr>
*            ).

          ENDIF.
        ELSE.
          ASSIGN COMPONENT 'BAPIRETTAB' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<ft_bapirettab>).

          IF sy-subrc = 0.

            DATA(falv) = zcl_falv=>create( EXPORTING i_popup = abap_true CHANGING ct_table = <ft_bapirettab> ).
            falv->layout->set_cwidth_opt( abap_true )->set_no_toolbar( abap_true ).
            falv->display( ).

          ENDIF.
        ENDIF.

    ENDCASE.

  ENDMETHOD.


  METHOD default_toobar.

    DELETE e_object->mt_toolbar WHERE quickinfo = '插入行'.
    DELETE e_object->mt_toolbar WHERE quickinfo = '删除行'.
    DELETE e_object->mt_toolbar WHERE quickinfo = '剪切'.
    DELETE e_object->mt_toolbar WHERE quickinfo = '复制文本'.
    DELETE e_object->mt_toolbar WHERE quickinfo = '插入总览'.
    DELETE e_object->mt_toolbar WHERE quickinfo = '附加行'.
    DELETE e_object->mt_toolbar WHERE quickinfo = '复制行'.
    DELETE e_object->mt_toolbar WHERE quickinfo = '视图'.
    DELETE e_object->mt_toolbar WHERE quickinfo = '显示图形'.
    DELETE e_object->mt_toolbar WHERE quickinfo = '撤销'.
    DELETE e_object->mt_toolbar WHERE quickinfo = '明细'.
    DELETE e_object->mt_toolbar WHERE quickinfo = '打印'.
    DELETE e_object->mt_toolbar WHERE quickinfo = '最终用户文档'.

    DATA:ls_toolbar TYPE stb_button.

    DEFINE mar_toolbar.
      ls_toolbar-function   = &1.
      ls_toolbar-text       = &2.
      ls_toolbar-quickinfo  = &3.
      ls_toolbar-icon       = &4.
      APPEND ls_toolbar TO e_object->mt_toolbar .
      CLEAR ls_toolbar.
    END-OF-DEFINITION.

    CASE objid.
      WHEN '1'.
        "HGY 20200520 增加按钮的折叠
        IF cmode->mode NE '11'.
          mar_toolbar 'EXPAND' '' '展开' icon_expand.
          mar_toolbar 'COLLPASE'  '' '折叠' icon_collapse.
        ENDIF.
        IF cmode->tree = abap_true.
          mar_toolbar 'TREE' '' '层次结构展示' icon_tree.
        ENDIF.

      WHEN OTHERS.
    ENDCASE.

  ENDMETHOD.


  METHOD default_user_command.

    CASE e_ucomm.
      WHEN 'EXPAND'.
        IF cmode->horizontal = abap_true.
          cmode->con-split_container->set_column_width( EXPORTING id = 1 width = 600 ).
        ELSE.
          cmode->con-split_container->set_row_height( EXPORTING id = 1 height = 30 ).
        ENDIF.
      WHEN 'COLLPASE'.
        IF cmode->horizontal = abap_true.
          cmode->con-split_container->set_column_width( EXPORTING id = 1 width = 2050 ).
        ELSE.
          cmode->con-split_container->set_row_height( EXPORTING id = 1 height = 100 ).
        ENDIF.
      WHEN 'TREE'.
        cmode->con-tree_container->set_column_width( EXPORTING id = 1 width = 15 ).
    ENDCASE.

  ENDMETHOD.


  METHOD GET_ROW_DATA.

    FIELD-SYMBOLS <ft_data> TYPE  table.

    DATA lv_tabnam TYPE tabnam.

    "动态内表
    READ TABLE cmode->t_mode INTO DATA(ls_mode) WITH KEY handle = objid.
    IF sy-subrc = 0.
      lv_tabnam = ls_mode-tabnam.
    ELSE.
      lv_tabnam = 'GT_DATA' && objid.
    ENDIF.

    "获取当前程序的内表
    CONCATENATE '(' repid ')' lv_tabnam INTO lv_tabnam.
    ASSIGN (lv_tabnam) TO <ft_data>.
    sdata = REF #( <ft_data>[ es_row_no-row_id ] OPTIONAL ).

  ENDMETHOD.


  METHOD handle_data_changed.

    DATA: ls_good TYPE lvc_s_modi.

    error_in_data = space.

    LOOP AT er_data_changed->mt_mod_cells INTO ls_good.

      CALL METHOD check_data
        EXPORTING
          ps_mat          = ls_good
          pr_data_changed = er_data_changed.

    ENDLOOP.

    refresh( gcl_alv_grid ).
    IF error_in_data EQ 'X'.
      CALL METHOD er_data_changed->display_protocol.
    ENDIF.

  ENDMETHOD.


  METHOD handle_double_click.

*    CASE objid.
*      WHEN '1'."双击

*        gcl_alv_mode->con-split_container->set_row_height( EXPORTING id = 1 height = 30 ).
*        ASSIGN COMPONENT 'VBELN' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_vbeln>).
*        DATA lt_filter TYPE lvc_t_filt.
*        lt_filter = VALUE #( ( fieldname = 'VBELN' sign = 'I' option = 'EQ'  low = <fs_vbeln> ) ).
*        gcl_alv2->set_filter_criteria( lt_filter ).
*        zcl_alv_refresh=>do(  gcl_alv2 ).

*      WHEN '2'.
*
*    ENDCASE.

  ENDMETHOD.


  METHOD handle_hotspot_click.

*    CASE e_column_id-fieldname.
*
*      WHEN 'BELNR_F'.
*
*        ASSIGN  COMPONENT 'BELNR_F' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_belnr>).
*        IF sy-subrc = 0.
*
*          SET PARAMETER ID 'BLN' FIELD <fs_belnr>.
*
*        ENDIF.
*        ASSIGN  COMPONENT 'BUKRS_S' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_bukrs>).
*        IF sy-subrc = 0.
*
*          SET PARAMETER ID 'BUK' FIELD <fs_bukrs>.
*
*        ENDIF.
*        ASSIGN  COMPONENT 'GJAHR_F' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_gjahr>).
*        IF sy-subrc = 0.
*
*          SET PARAMETER ID 'GJR' FIELD <fs_gjahr>.
*
*        ENDIF.
*
*        CALL TRANSACTION 'FB03' AND SKIP FIRST SCREEN.
*
*    ENDCASE.
*

  ENDMETHOD.


  METHOD handle_toolbar.

    " menu_button 的例子
*    MOVE 'POST' TO ls_toolbar-function.
*    MOVE icon_workflow_process TO ls_toolbar-icon.
*    MOVE 1 TO ls_toolbar-butn_type.

*    0    button(normal)
*    1    menu and default button
*    2    menu
*    3    分割符
*    4    radio button
*    5    Checkbox
*    6    menu entry

*    MOVE '过账' TO ls_toolbar-quickinfo.
*    MOVE '过账' TO ls_toolbar-text.
*    MOVE ' ' TO ls_toolbar-disabled.
*    APPEND ls_toolbar TO e_object->mt_toolbar.
*    CLEAR ls_toolbar.

  ENDMETHOD.


  method HANDLE_USER_COMMAND.
  endmethod.


  method MENU_BUTTON.
  endmethod.


  method ON_F1.
  endmethod.


  method ON_F4.
  endmethod.


  method REFRESH.

   "获取当前alv的layout
    DATA ls_layout TYPE lvc_s_layo.
    alv_grid->get_frontend_layout(  IMPORTING es_layout = ls_layout ).
    "SAPBUG,获取到的layout的CWIDTH_OPT 参数，赋值X，但是获取到的是1
    ls_layout-cwidth_opt = abap_true.
    "给alv类重置layout
    alv_grid->set_frontend_layout( ls_layout ).
    "刷新
    alv_grid->refresh_table_display(
                      is_stable = VALUE #( row = abap_true col = abap_true )  ).

  endmethod.
ENDCLASS.
