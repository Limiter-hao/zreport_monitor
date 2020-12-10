***********************************************************************
* Title           : 多屏幕alv展示
* Application     : GIT
* Subject         :
* Requested by    :
* Execution       :
* Ref no:         : Fs number
* Author          : Limiter
* Req Date        : 20191021
***********************************************************************
*          　　设计主要逻辑与原理说明                                 *
***********************************************************************
REPORT zgit_alv.

TABLES:vbak.
*-------------alv的相关定义---------------------------------------
"alv类定义
DATA gcl_alv1 TYPE REF TO cl_gui_alv_grid.
DATA gcl_alv2 TYPE REF TO cl_gui_alv_grid.
"alv_tree 定义
DATA gcl_tree TYPE REF TO cl_gui_alv_tree.
"事件处理类定义
DATA(gcl_msg) = NEW zcl_msg( ).
"alv模式
DATA(gcl_alv_mode) = NEW zcl_alv_mode( sy-repid ).
"监控类
DATA(gcl_monitor) = NEW zcl_report_monitor( sy-repid ).
PARAMETERS p_debug TYPE abap_bool NO-DISPLAY. "调式标记，请勿删除
*---------------全局ALV内表定义-------------------------------

DATA:BEGIN OF gs_data.
"在此添加自定义字段
    INCLUDE TYPE zsgit_alv.
DATA: END OF gs_data,
gt_data LIKE TABLE OF gs_data.

CLEAR:gs_data,gt_data.

"如需多个alv展示，定义内表为gt_data加数字
DATA:BEGIN OF gs_data1,
       "在此添加自定义字段
       vbeln LIKE vbap-vbeln,
       posnr LIKE vbap-posnr,
       matnr LIKE vbap-matnr,

     END OF gs_data1.
CLEAR:gs_data1.

DATA:gt_data1 LIKE TABLE OF gs_data1,
     gt_data2 LIKE gt_data.

CLEAR:gt_data1,gt_data2.

"alv tree 的内表，切必须为空
DATA gt_tree LIKE gt_data1.
CLEAR gt_tree.

*--------------全局变量定义---------------------------------
DATA ok_code TYPE sy-ucomm. "ok_code
DATA gv_ttext TYPE tstct-ttext. "title文本

*--------------选择屏幕---------------------------------------------
SELECTION-SCREEN:BEGIN OF BLOCK b1 WITH FRAME TITLE txt1.

SELECT-OPTIONS s_vkorg FOR vbak-vkorg.

SELECTION-SCREEN:END OF BLOCK b1.

"Defin class 大部分通用类
INCLUDE zgit_alv_cls_define.
"Alv_gird与Gcl_event_receiver的类以及其他类的实现
INCLUDE zgit_alv_cls_implementation.
"标准module
INCLUDE zgit_module.
"初始化

INITIALIZATION.

  "设置标题为tcode标题
  SELECT SINGLE ttext FROM tstct INTO @gv_ttext
    WHERE tcode = @sy-tcode.
  SET TITLEBAR 'TITLE' WITH gv_ttext.

  "屏幕输出前

AT SELECTION-SCREEN OUTPUT.

  "屏幕输出后

AT SELECTION-SCREEN.

  "开始

START-OF-SELECTION.

  "目前只做了这俩，如果是多屏幕的再次模板基础上进行更改
  "n 1 代表 上下屏显示N个alv
  "1 N 代表左右屏显示N个ALV
  "1 1 不分屏
  gcl_alv_mode->mode = '12'.

  "默认alv1 对应内表gt_data1  alv2对应内表gt_data2
  "如需指定alv对应特殊名的内表，
  gcl_alv_mode->t_mode = VALUE #(
  ( handle = '1' tabnam = 'GT_DATA' )
  ( handle = '2' tabnam = 'GT_DATA1' )
  ).

  gcl_alv_mode->tree = abap_true."启用tree功能
  gcl_alv_mode->ziflog = abap_false."启用标准日志功能


  SET HANDLER gcl_msg->display_msg FOR ALL INSTANCES.
  "取数
  gcl_monitor->start( p_debug ).
  DATA(lcl_data) = NEW gcl_data( ).

  lcl_data->main( ).

END-OF-SELECTION.
  gcl_monitor->end( ).
  FREE gcl_monitor.
  CHECK gcl_msg->handle_msg NE abap_true.
  FREE lcl_data.
  CALL SCREEN 100.
