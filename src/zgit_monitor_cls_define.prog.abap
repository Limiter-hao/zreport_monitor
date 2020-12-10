*&---------------------------------------------------------------------*
*& 包含               ZGIT_ALV_CLS_DEFINE
*&---------------------------------------------------------------------*
*----------------------------------------------------------------------*
*       CLASS gCL_EVENT_RECEIVER DEFINITION
*----------------------------------------------------------------------*
*       alv常用事件的类定义，继承父类zcl_event_receiver
*----------------------------------------------------------------------*
CLASS gcl_event_receiver DEFINITION.

  PUBLIC SECTION.

    DATA:
          objid    TYPE char10."ALV识别
    METHODS:
      constructor
        IMPORTING
          i_objid TYPE char10 OPTIONAL,
      handle_toolbar FOR EVENT toolbar OF cl_gui_alv_grid "状态栏
        IMPORTING
          e_object ,
      handle_user_command FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING
          e_ucomm ,
      handle_hotspot_click
                  FOR EVENT hotspot_click OF cl_gui_alv_grid    "屏幕中的单击事件，可以具体到某行某列，需要设置热点
        IMPORTING e_row_id e_column_id es_row_no,
      menu_button FOR EVENT menu_button OF cl_gui_alv_grid
        IMPORTING e_object e_ucomm  .

  PRIVATE SECTION.
    METHODS:
      default_toobar IMPORTING
                       e_object TYPE REF TO	cl_alv_event_toolbar_set,
      default_user_command IMPORTING e_ucomm TYPE sy-ucomm,
      get_rows IMPORTING alv_grid     TYPE REF TO cl_gui_alv_grid
                         only_check   TYPE abap_bool OPTIONAL
               CHANGING  it_data      TYPE table
               RETURNING VALUE(error) TYPE abap_bool.

ENDCLASS. "LCL_EVENT_RECEIVER DEFINITION
*----------------------------------------------------------------------*
*       CLASS gcl_alv DEFINITION
*----------------------------------------------------------------------*
*       alv展示类
*----------------------------------------------------------------------*
CLASS gcl_alv_display DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS:
      get_layout
        RETURNING VALUE(layout) TYPE lvc_s_layo,
      get_fieldcat
        IMPORTING handle      TYPE slis_handl
        RETURNING VALUE(fcat) TYPE lvc_t_fcat,
      alv_grid,
      alv_out IMPORTING container TYPE REF TO cl_gui_container
                        iv_handle TYPE  slis_handl
                        evf_cls   TYPE REF TO gcl_event_receiver
              CHANGING  alv_grid  TYPE REF TO cl_gui_alv_grid
                        data      TYPE  table.

  PRIVATE SECTION.
    METHODS
      split_container.

ENDCLASS.
*----------------------------------------------------------------------*
*       CLASS gcl_data DEFINITION
*----------------------------------------------------------------------*
*       alv数据处理类
*----------------------------------------------------------------------*
CLASS gcl_data DEFINITION FINAL.
  PUBLIC  SECTION.
    METHODS:
      main,
      author_check  ,"权限检查
      get_data  ,"取数
      deal_data ."数据处理
  PRIVATE SECTION.
    METHODS:
      calc_second  IMPORTING timestampl1    TYPE timestampl
                             timestampl2    TYPE timestampl
                   RETURNING VALUE(seconds) TYPE timestampl.

ENDCLASS.
CLASS alv_action DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS:
      refresh IMPORTING i_grid TYPE REF TO cl_gui_alv_grid.

ENDCLASS.
