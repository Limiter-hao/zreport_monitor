***********************************************************************
* Title           : 报表监控
* Application     : GIT
* Subject         : 监控
* Ref no:         :
* Author          : 19100641
* Req Date        : 20200817
***********************************************************************
*          　　设计主要逻辑与原理说明                                 *
***********************************************************************
***********************************************************************
REPORT zgit_monitor .

TABLES:sscrfields.
*-------------alv的相关定义---------------------------------------
"alv类定义
DATA gcl_alv1 TYPE REF TO cl_gui_alv_grid.
DATA gcl_alv2 TYPE REF TO cl_gui_alv_grid.
"容器定义
DATA gcl_split_container TYPE REF TO cl_gui_splitter_container.
"类型定义
TYPES:
  BEGIN OF typ_overview,
    repid      TYPE repid,
    repti      TYPE repti,
    count      TYPE i,
    real_count TYPE i,
    avg_time   TYPE timestampl,
  END OF typ_overview,

  BEGIN OF typ_detail.
    INCLUDE TYPE ztabap_rep_mon.
  TYPES:
    proc_time TYPE timestampl,
    color     TYPE c LENGTH 4,  "颜色
    sel       TYPE c, "选择标
  END OF typ_detail,

  BEGIN OF typ_para_alv.
    INCLUDE TYPE rsparams.
  TYPES:
    text TYPE string,
  END OF typ_para_alv,
  typt_para_alv TYPE TABLE OF typ_para_alv.
*---------------全局ALV内表定义-------------------------------
DATA:
  gt_detail   TYPE TABLE OF typ_detail,
  gs_detail   TYPE typ_detail,
  gt_overview TYPE TABLE OF typ_overview,
  gs_overview TYPE typ_overview.

*--------------全局变量定义---------------------------------
DATA ok_code TYPE sy-ucomm. "ok_code
DATA gv_ttext TYPE tstct-ttext. "title文本
DATA gv_mode TYPE char2. "屏幕分割标识
DATA gv_tree TYPE c. "是否启用alv_tree

*--------------选择屏幕---------------------------------
SELECTION-SCREEN:BEGIN OF BLOCK b1 WITH FRAME TITLE txt1.
SELECT-OPTIONS:
s_repid FOR sy-repid MEMORY ID rid,
s_zdate FOR gs_detail-zdate.
SELECTION-SCREEN:END OF BLOCK b1.

"Defin class 大部分通用类
INCLUDE zgit_monitor_cls_define.
"Alv_gird与Gcl_event_receiver的类以及其他类的实现
INCLUDE zgit_monitor_cls_impl.
"标准Status
INCLUDE zgit_monitor_module.

INITIALIZATION.  "IniTiaLiZaTion

  "设置标题为tcode标题
  SELECT SINGLE ttext FROM tstct INTO @gv_ttext
    WHERE tcode = @sy-tcode.
  SET TITLEBAR 'TITLE' WITH gv_ttext.
  "设置两个选择屏幕按钮
  sscrfields-functxt_02 = VALUE smp_dyntxt( icon_id = icon_view_switch icon_text = ''  ).

AT SELECTION-SCREEN OUTPUT.  "Pbo


AT SELECTION-SCREEN.  "Pai

START-OF-SELECTION.  "Start

  gv_mode = 21 .
  "取数
  DATA(lcl_data) = NEW gcl_data( ).
  lcl_data->main( ).

END-OF-SELECTION.    "End
  FREE lcl_data.
  CALL SCREEN 100.
