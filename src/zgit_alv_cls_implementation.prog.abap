*&---------------------------------------------------------------------*
*& 包含               ZGIT_ALV_CLS_IMPLEMENTATION
*&---------------------------------------------------------------------*
*----------------------------------------------------------------------*
*       CLASS gcl_data IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS gcl_data IMPLEMENTATION."数据处理类的实现

  METHOD author_check.


  ENDMETHOD.

  METHOD get_data.

*    SELECT
*      vbeln
*      FROM vbak INTO CORRESPONDING FIELDS OF TABLE gt_data.
*    IF sy-subrc NE 0.
*      RAISE EVENT display_msg EXPORTING type = 'W' msg = '未查询到数据'.
*      CHECK gcl_msg->handle_msg NE abap_true.
*    ENDIF.

  ENDMETHOD.

  METHOD deal_data.


  ENDMETHOD.

ENDCLASS.
*----------------------------------------------------------------------*
*       CLASS LCL_EVENT_RECEIVER IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS gcl_event_receiver IMPLEMENTATION.

  "ALV内表展示处单击事件捕捉，需要设置热点对单击列字段
  METHOD handle_hotspot_click.

    "获取单击的行内容
    DATA(lcl_data) = get_row_data( cmode = gcl_alv_mode  es_row_no = es_row_no ).
    ASSIGN lcl_data->* TO FIELD-SYMBOL(<fs_data>).

    "调用默认单击功能
    me->default_hotspot_click( sdata = lcl_data
                               e_column_id = e_column_id
                               ziflog = gcl_alv_mode->ziflog ).

    "-> 在此位置添加单击事件，可参照父类代码

  ENDMETHOD.

  METHOD handle_toolbar.

    "标准按钮功能
    me->default_toobar( e_object = e_object cmode = gcl_alv_mode ).

    DATA:ls_toolbar TYPE stb_button.

    "添加按钮的宏定义
    DEFINE mar_toolbar.
      ls_toolbar-function   = &1.
      ls_toolbar-text       = &2.
      ls_toolbar-quickinfo  = &3.
      ls_toolbar-icon       = &4.
      APPEND ls_toolbar TO e_object->mt_toolbar .
      CLEAR ls_toolbar.
    END-OF-DEFINITION.

    "-> 在此位置添加状态栏按钮，可参照父类代码

  ENDMETHOD.                    "HANDLE_TOOLBAR
  METHOD menu_button.

    "->在此位置添加menu_button的实现方法

  ENDMETHOD."mebu_button
  "双击
  METHOD handle_double_click.

    "获取双击的行内容
    DATA(lcl_data) = get_row_data( cmode = gcl_alv_mode  es_row_no = es_row_no ).
    ASSIGN lcl_data->* TO FIELD-SYMBOL(<fs_data>).

    "-> 在此位置添加双击事件，可参照父类代码

  ENDMETHOD. "HANDLE_DOUBLE_CLICK

* 响应用户命令
  METHOD handle_user_command.

    "标准按钮处理
    me->default_user_command( e_ucomm = e_ucomm
                              cmode = gcl_alv_mode ).

    "->在此位置添加按钮事件，可参照父类代码

  ENDMETHOD.                    "HANDLE_USER_COMMAND
  "f4搜索帮助
  METHOD on_f4.

    "->在此位置添加F4 事件

  ENDMETHOD."on_f4

  METHOD data_changed_finished.

    "->在此位置添加修改事件后

  ENDMETHOD."data_changed_finished.


  METHOD check_data.

    "->参照父类代码check_data 的使用

  ENDMETHOD.                    "CHECK_DATA
ENDCLASS. "LCL_EVENT_RECEIVER IMPLEMENTATION

CLASS gcl_alv_display IMPLEMENTATION."alv展示类

  METHOD get_fieldcat.

    DATA ls_fcat TYPE lvc_s_fcat.
    CLEAR ls_fcat.

    DEFINE mar_field.

      ls_fcat-fieldname  = &1.           "字段名
      ls_fcat-coltext    = &2.           "字段描述文本

      CASE &1.

        WHEN 'ICON'.
          ls_fcat-icon = abap_true.
          ls_fcat-hotspot = abap_true.

      ENDCASE.

      APPEND ls_fcat TO fcat.
      CLEAR ls_fcat.
    END-OF-DEFINITION.

    CASE objid.

      WHEN '1'.

        mar_field 'VBELN' '销售订单号'.
        mar_field 'VKORG' '销售组织'.
        mar_field 'ERDAT' '创建日期'.
        mar_field 'ERNAM' '创建人'.
        mar_field 'ICON'  '状态'.
        mar_field 'MSG'   '错误消息'.

      WHEN '2'.

        mar_field 'VBELN' '销售订单号'.
        mar_field 'POSNR' '销售订单行项目号'.
        mar_field 'MATNR' '物料号'.
        mar_field 'KWMENG' '订单数量'.

    ENDCASE.


  ENDMETHOD.

  METHOD alv_grid.

    "将容器与屏幕做关联
    IF gcl_alv_mode->con-container IS NOT BOUND.
      gcl_alv_mode->number = set_split( IMPORTING horizontal = gcl_alv_mode->horizontal
                                CHANGING rs_con = gcl_alv_mode->con ).
    ENDIF.
*------------------循环构造alv--------------------------------------------
    DATA lv_handle TYPE slis_handl.
    DO gcl_alv_mode->number TIMES.
      "alv 标识
      lv_handle = sy-index.
      CONDENSE lv_handle NO-GAPS.
      "构造alv
      me->objid = lv_handle.
      IF gcl_alv_mode->horizontal = abap_true."横向多个alv
        DATA(lcl_split) = gcl_alv_mode->con-split_container->get_container( row = 1  column = sy-index ).
      ELSE.
        lcl_split = gcl_alv_mode->con-split_container->get_container( row = sy-index  column = 1 ).
      ENDIF.
      "动态化alv类
      IF gcl_alv_mode->number > 1.
        DATA(lv_class) = 'GCL_ALV' && sy-index.
        DATA(lv_tbnam) = 'GT_DATA' && sy-index.
      ELSE.
        lv_class = 'GCL_ALV'.
        lv_tbnam = 'GT_DATA'.
      ENDIF.
      "动态化内表
      "先从配置表中判断是否有特殊对应的内表
      READ TABLE gcl_alv_mode->t_mode INTO DATA(ls_mode) WITH KEY handle = lv_handle.
      IF sy-subrc = 0.
        lv_tbnam = ls_mode-tabnam.
      ENDIF.
      CLEAR ls_mode.

      ASSIGN (lv_tbnam) TO FIELD-SYMBOL(<ft_data>).
      ASSIGN (lv_class) TO FIELD-SYMBOL(<fcl_alv>).
      CLEAR:lv_tbnam,lv_class.
      "实例化事件处理类
      DATA lcl_event TYPE REF TO zcl_event_receiver.
      lcl_event ?= NEW gcl_event_receiver( i_objid = objid
                                           i_repid = sy-repid ).

      me->alv_out( EXPORTING container = lcl_split
                             iv_handle = lv_handle
                   CHANGING  alv_grid = <fcl_alv>
                             evf_cls = lcl_event
                             data = <ft_data> ).
    ENDDO.

   "如果tree标记打X 的话，启用tree功能
*   IF gv_tree = abap_true.
*     NEW tree( )->construct( ).
*   ENDIF.

  ENDMETHOD.

ENDCLASS.
