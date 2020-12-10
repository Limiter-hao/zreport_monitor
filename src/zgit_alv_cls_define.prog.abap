*&---------------------------------------------------------------------*
*& 包含               ZGIT_ALV_CLS_DEFINE
*&---------------------------------------------------------------------*
*----------------------------------------------------------------------*
*       CLASS gCL_EVENT_RECEIVER DEFINITION
*----------------------------------------------------------------------*
*       alv常用事件的类定义，继承父类zcl_event_receiver
*----------------------------------------------------------------------*
CLASS gcl_event_receiver DEFINITION INHERITING FROM zcl_event_receiver FINAL.

  PUBLIC SECTION.
    METHODS:
      "状态栏增加图标
      handle_toolbar REDEFINITION,
      "点击按钮后
      handle_user_command REDEFINITION,
      "双击
      handle_double_click  REDEFINITION,
      "数据更改
*      handle_data_changed REDEFINITION,
      "数据更改后
      data_changed_finished REDEFINITION,
      "F4 事件
      on_f4 REDEFINITION,
      "单击热键
      handle_hotspot_click REDEFINITION,
      "menu事件
      menu_button REDEFINITION.

  PROTECTED SECTION.
    METHODS:
      check_data REDEFINITION.

ENDCLASS.
*----------------------------------------------------------------------*
*       CLASS gcl_alv DEFINITION
*----------------------------------------------------------------------*
*       alv展示类
*----------------------------------------------------------------------*
CLASS gcl_alv_display DEFINITION INHERITING FROM zcl_alv_display FINAL.

  PUBLIC SECTION.

    METHODS:
*      get_layout REDEFINITION,
      get_fieldcat REDEFINITION,
      alv_grid  REDEFINITION.
*      alv_out REDEFINITION.

ENDCLASS.
*----------------------------------------------------------------------*
*       CLASS gcl_data DEFINITION
*----------------------------------------------------------------------*
*       alv数据处理类
*----------------------------------------------------------------------*
CLASS gcl_data DEFINITION INHERITING FROM zcl_alv_data FINAL.
  PUBLIC  SECTION.
    METHODS:
      author_check REDEFINITION ,"权限检查
      get_data REDEFINITION ,"取数
      deal_data REDEFINITION."数据处理

ENDCLASS.
