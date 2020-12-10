class ZCL_ALV_DISPLAY definition
  public
  create public .

public section.

  interfaces ZIF_MSG .
  interfaces ZIF_ALV_MODE .

  aliases CON
    for ZIF_ALV_MODE~CON .
  aliases GV_DYNNR
    for ZIF_ALV_MODE~DYNNR .
  aliases GV_MODE
    for ZIF_ALV_MODE~MODE .
  aliases GV_REPID
    for ZIF_ALV_MODE~REPID .
  aliases GV_TREE
    for ZIF_ALV_MODE~TREE .

  data OBJID type CHAR10 .

  methods CONSTRUCTOR
    importing
      !CMODE type ref to ZCL_ALV_MODE .
  methods ALV_GRID
    changing
      !CMODE type ref to ZCL_ALV_MODE .
  methods GET_LAYOUT
    returning
      value(LAYOUT) type LVC_S_LAYO .
  methods GET_FIELDCAT
    returning
      value(FCAT) type LVC_T_FCAT .
  methods ALV_OUT
    importing
      !CONTAINER type ref to CL_GUI_CONTAINER
      !IV_HANDLE type SLIS_HANDL
    changing
      !DATA type TABLE
      !EVF_CLS type ref to ZCL_EVENT_RECEIVER optional
      !ALV_GRID type ref to CL_GUI_ALV_GRID .
  methods SET_SPLIT
    exporting
      !HORIZONTAL type C
    changing
      !RS_CON type ZSGIT_CONTAINER
    returning
      value(ALV_NUMBER) type I .
  methods REFRESH
    importing
      !ALV_GRID type ref to CL_GUI_ALV_GRID .
protected section.
private section.
ENDCLASS.



CLASS ZCL_ALV_DISPLAY IMPLEMENTATION.


  METHOD alv_grid.

    "将容器与屏幕做关联
    IF cmode->con-container IS NOT BOUND.
      cmode->number = set_split( IMPORTING horizontal = cmode->horizontal
                                 CHANGING rs_con = cmode->con ).
    ENDIF.
*------------------循环构造alv--------------------------------------------
    DATA lv_handle TYPE slis_handl.
    DO cmode->number TIMES.
      "alv 标识
      lv_handle = sy-index.
      CONDENSE lv_handle NO-GAPS.
      "构造alv
      me->objid = lv_handle.
      IF cmode->horizontal = abap_true."横向多个alv
        DATA(lcl_split) = cmode->con-split_container->get_container( row = 1  column = sy-index ).
      ELSE.
        lcl_split = cmode->con-split_container->get_container( row = sy-index  column = 1 ).
      ENDIF.
      "动态化alv类
      IF cmode->number > 1.
        DATA(lv_class) = 'GCL_ALV' && sy-index.
        DATA(lv_tbnam) = 'GT_DATA' && sy-index.
      ELSE.
        lv_class = 'GCL_ALV'.
        lv_tbnam = 'GT_DATA'.
      ENDIF.
      "动态化内表
      "先从配置表中判断是否有特殊对应的内表
      READ TABLE cmode->t_mode INTO DATA(ls_mode) WITH KEY handle = lv_handle.
      IF sy-subrc = 0.
        lv_tbnam = ls_mode-tabnam.
      ENDIF.
      CLEAR ls_mode.

      CONCATENATE '(' cmode->repid ')' lv_tbnam INTO lv_tbnam.
      CONCATENATE '(' cmode->repid ')' lv_class INTO lv_class.
      ASSIGN (lv_tbnam) TO FIELD-SYMBOL(<ft_data>).
      ASSIGN (lv_class) TO FIELD-SYMBOL(<fcl_alv>).
      CLEAR:lv_tbnam,lv_class.

      DATA(lcl_event) = NEW zcl_event_receiver(  ).
      "实例化事件处理类
      me->alv_out( EXPORTING container = lcl_split
                             iv_handle = lv_handle
                   CHANGING  alv_grid = <fcl_alv>
                             evf_cls = lcl_event
                             data = <ft_data> ).
    ENDDO.

  ENDMETHOD.


  METHOD alv_out.

    DATA:lt_fcat    TYPE lvc_t_fcat,
         ls_layout  TYPE lvc_s_layo,
         ls_variant TYPE disvariant.

    IF   alv_grid IS NOT BOUND.

      alv_grid = NEW #( i_parent = container ).
      lt_fcat   = get_fieldcat( ).
      ls_layout = get_layout( ).

      ls_variant-report = gv_repid.
      ls_variant-handle = iv_handle.

      CALL METHOD alv_grid->set_table_for_first_display
        EXPORTING
          is_layout       = ls_layout
          i_save          = 'A'
          is_variant      = ls_variant
        CHANGING
          it_outtab       = data
          it_fieldcatalog = lt_fcat.

      IF evf_cls IS BOUND.
        evf_cls->gcl_alv_grid = alv_grid.

        "数据修改中事件
        SET HANDLER evf_cls->handle_data_changed       FOR alv_grid.
        "数据修改后事件
        SET HANDLER evf_cls->data_changed_finished FOR alv_grid.
        "光标移动事件
        CALL METHOD alv_grid->register_edit_event
          EXPORTING
            i_event_id = cl_gui_alv_grid=>mc_evt_modified.
        "回车事件
        CALL METHOD alv_grid->register_edit_event
          EXPORTING
            i_event_id = cl_gui_alv_grid=>mc_evt_enter.
        SET HANDLER evf_cls->handle_user_command FOR alv_grid."用户命令
        SET HANDLER evf_cls->handle_toolbar      FOR alv_grid."状态栏
        SET HANDLER evf_cls->menu_button         FOR alv_grid."状态栏下拉
        CALL METHOD alv_grid->set_toolbar_interactive."激活状态栏
        SET HANDLER evf_cls->handle_hotspot_click FOR alv_grid."热点事件
        SET HANDLER evf_cls->handle_double_click  FOR alv_grid."双击

      ENDIF.

    ELSE.
      refresh( alv_grid ).
    ENDIF.

  ENDMETHOD.


  METHOD constructor.

    gv_mode = cmode->mode.
    gv_repid = cmode->repid.
    gv_tree  = cmode->tree.
    gv_dynnr = cmode->dynnr.

  ENDMETHOD.


  method GET_FIELDCAT.
  endmethod.


  METHOD get_layout.

    layout-zebra = 'X'."隔行换色
    layout-cwidth_opt = abap_true.     "优化列宽设置
*   LAYOUT-INFO_FNAME = 'CLR'."行项目颜色
*   layout-stylefname = 'STYLE'.
    layout-sel_mode       = 'D'.

  ENDMETHOD.


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


  METHOD set_split.

    "将容器与屏幕做关联

    IF rs_con-container IS NOT BOUND.

      rs_con-container = NEW cl_gui_docking_container( repid = gv_repid
                                                       dynnr = gv_dynnr
                                                       extension = 2050 ).

    ENDIF.

    IF gv_tree = 'X'."先将容器划分为左右两个

      IF rs_con-tree_container IS NOT BOUND.
        rs_con-tree_container = NEW cl_gui_splitter_container(
                                                        parent  = rs_con-container
                                                        rows    = 1
                                                        columns = 2 ).

        "设置边框
        rs_con-tree_container->set_border( cl_gui_cfw=>false ).
        "设置为相对模式
        rs_con-tree_container->set_column_mode( rs_con-tree_container->mode_relative ).
        "将分割的左面屏幕进行隐藏
        rs_con-tree_container->set_column_width( EXPORTING id = 1 width = 0 ).

      ENDIF.

    ENDIF.

*----------------------将容器进行分割----------------------------------
    DATA: lv_rows    TYPE i,
          lv_columns TYPE i.

    lv_rows = gv_mode(1).
    lv_columns = gv_mode+1(1).

    IF rs_con-split_container IS NOT BOUND.

      "如果要显示tree,在那么alv在tree的右面容器再进行分割处理

      IF gv_tree = 'X'.

        rs_con-split_container = NEW cl_gui_splitter_container(
                                                        parent  = rs_con-tree_container->get_container( row = 1 column = 2 )
                                                         rows    = lv_rows
                                                         columns = lv_columns ).

      ELSE.

        rs_con-split_container = NEW cl_gui_splitter_container( parent  = rs_con-container
                                                         rows    = lv_rows
                                                         columns = lv_columns ).

      ENDIF.

      "设置边框
      rs_con-split_container->set_border( cl_gui_cfw=>true ).
      "设置为相对模式
      rs_con-split_container->set_column_mode( rs_con-split_container->mode_absolute ).

    ENDIF.

    " 控制横屏跟竖屏的时候，上面跟左面的alv占满全屏,并输出分割的数量

    IF lv_rows > 1."纵向多个alv

      rs_con-split_container->set_row_height( EXPORTING id = 1 height = 100 ).
      alv_number = lv_rows.

    ELSEIF lv_columns > 1."横向多个alv

      rs_con-split_container->set_column_width( EXPORTING id = 1 width = 2050 ).
      alv_number = lv_columns.
      horizontal = abap_true.

    ELSE."一个alv

      rs_con-split_container->set_row_height( EXPORTING id = 1 height = 100 ).
      alv_number = lv_rows.

    ENDIF.
  ENDMETHOD.
ENDCLASS.
