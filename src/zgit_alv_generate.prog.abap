*&---------------------------------------------------------------------*
*& Report ZGIT_ALV_generate
*&---------------------------------------------------------------------*
*& ALV 生成器 author:Limiter
*&---------------------------------------------------------------------*
REPORT zgit_alv_generate.

DATA:     g_tc1_lines  LIKE sy-loopc.
DATA:BEGIN OF gs_config.

    INCLUDE TYPE zsgit_config.
DATA:  END OF gs_config.

DATA ok_code TYPE sy-ucomm.

DATA: gs_source TYPE string.
DATA: gt_source LIKE STANDARD TABLE OF gs_source.

gs_config-status = abap_true.
gs_config-zif_monitor = abap_true.

DATA:BEGIN OF gs_mode,

       sel    TYPE c,
       handle TYPE slis_handl, "alv处理标识
       tabnam TYPE tabnam, "alv 对应的内表名

     END OF gs_mode,
     gt_mode LIKE TABLE OF gs_mode.
CLEAR:gs_mode,gt_mode.

START-OF-SELECTION.

  CALL SCREEN 100.

CLASS se38 DEFINITION ."创建程序类

  PUBLIC SECTION.

    METHODS set_main.
    METHODS copy_program.
    METHODS copy_status.
    METHODS copy_screen.
    METHODS trans IMPORTING progname TYPE progname.
    METHODS set_title IMPORTING progname TYPE progname
                                title    TYPE ze_git_title
                                title_e  TYPE ze_git_title_e OPTIONAL.

  PRIVATE SECTION.

    METHODS
      set_source IMPORTING source TYPE string.
    METHODS
      space.


ENDCLASS.

CLASS se38 IMPLEMENTATION.

  METHOD set_main.

    DATA lv_source TYPE string.

    me->set_source( '***********************************************************************' ).
    me->set_source( '* Title           :' && gs_config-title ).
    me->set_source( '* Application     : MM' ).
    me->set_source( '* Subject         : &&' ).
    me->set_source( '* Requested by    : &&' ).
    me->set_source( '* Execution       : Online when required' ).
    me->set_source( '* Ref no:         : JJY-FS-DS-032' ).
    me->set_source( '* Author          :' && sy-uname ).
    me->set_source( '* Req Date        :' && sy-datum ).
    me->set_source( '***********************************************************************' ).
    me->set_source( '*          　　设计主要逻辑与原理说明                                 *' ).
    me->set_source( '***********************************************************************' ).
    me->set_source( '***********************************************************************' ).

    TRANSLATE gs_config-name TO LOWER CASE.
    CONCATENATE 'REPORT' gs_config-name '.' INTO lv_source SEPARATED BY space.
    TRANSLATE gs_config-name TO UPPER CASE.
    me->set_source( lv_source  ).
    me->space( ).
    me->set_source( 'TABLES:sscrfields.' ).

    me->set_source( '*-------------程序相关类声明---------------------------------------' ).
    me->set_source( '"alv类定义' ).

    "循环alv进行赋值

    DATA lv_alv_name TYPE string.
    CLEAR lv_alv_name.

    IF gs_config-nm = 1.

      lv_alv_name = 'DATA gcl_alv TYPE REF TO cl_gui_alv_grid.'.
      me->set_source( CONV #( lv_alv_name ) ).

    ELSE.

      DO gs_config-nm TIMES.
        lv_alv_name = 'DATA gcl_alv' && sy-index .
        CONCATENATE lv_alv_name 'TYPE REF TO cl_gui_alv_grid.'
        INTO lv_alv_name SEPARATED BY space.
        me->set_source( CONV #( lv_alv_name ) ).
        CLEAR lv_alv_name.
      ENDDO.

    ENDIF.
    CLEAR lv_alv_name.

    IF gs_config-tree = 'X'.
      me->set_source( '"alv_tree 定义' ).
      me->set_source( 'DATA gcl_tree TYPE REF TO cl_gui_alv_tree.' ).
    ENDIF.
    me->set_source( '"事件处理类定义' ).
    me->set_source( 'DATA(gcl_msg) = NEW zcl_msg( ).' ).

    me->set_source( '"alv模式' ).
    me->set_source( 'DATA(gcl_alv_mode) = NEW zcl_alv_mode( sy-repid ).' ).

    me->set_source( '"监控类' ).
    me->set_source( 'DATA(gcl_monitor) = NEW zcl_report_monitor( sy-repid ).' ).
    me->set_source( 'PARAMETERS p_debug TYPE abap_bool NO-DISPLAY. "调式标记，请勿删除').
    me->space( ).

    me->set_source( '*---------------全局ALV内表定义------------------------------------' ).

    DATA: lv_tabnam TYPE tabnam,
          lv_strnam TYPE tabnam.

    DATA lv_handle TYPE slis_handl.
    CLEAR lv_handle.

    IF gs_config-nm = 1.
      me->set_source( '"内表1').
      me->set_source( 'DATA:BEGIN OF gs_data.' ).
      me->space( ).
      me->set_source( '       INCLUDE TYPE zsgit_alv.' ).
      me->space( ).
      me->set_source( '     DATA: END OF gs_data,').
      me->set_source( '     gt_data LIKE TABLE OF gs_data.').
    ELSE.
      DO gs_config-nm TIMES.

        lv_handle = sy-index.
        CONDENSE lv_handle NO-GAPS.

        READ TABLE gt_mode INTO gs_mode WITH KEY handle = lv_handle.
        IF sy-subrc = 0.

          lv_tabnam = gs_mode-tabnam.
          lv_strnam = lv_tabnam.
          lv_strnam+1(1) = 'S'.

        ELSE.

          lv_strnam = 'gs_data' && sy-index.
          lv_tabnam = 'gt_data' && sy-index.

        ENDIF.
        me->set_source( '"内表' && sy-index ).
        CONCATENATE 'DATA:BEGIN OF' lv_strnam '.' INTO lv_source SEPARATED BY space.
        me->set_source( lv_source ).
        me->set_source( '"在此添加内表字段' ).
        me->set_source( '       INCLUDE TYPE zsgit_alv.' ).
        CONCATENATE '     DATA: END OF ' lv_strnam ',' INTO lv_source SEPARATED BY space.
        me->set_source( lv_source ).

        CONCATENATE '     ' lv_tabnam   'LIKE TABLE OF' lv_strnam '.' INTO lv_source SEPARATED BY space.
        me->set_source( lv_source ).
        CLEAR lv_source.
        lv_source = 'CLEAR:' && lv_strnam && ',' && lv_tabnam && '.'.
        me->set_source( lv_source ).

      ENDDO.
    ENDIF.

    IF gs_config-tree = 'X'.

      me->set_source( '"alv tree 的内表，切必须为空' ).
      me->set_source('DATA gt_tree LIKE gt_data1.').
      me->set_source( 'CLEAR gt_tree.').
      me->space( ).
    ENDIF.

    me->set_source( '"alv跟内表对应关系配置表' ).
    me->set_source('DATA gt_mode TYPE ztgit_alv_mode.').
    me->set_source('CLEAR gt_mode.').
    me->set_source('*---------------全局变量定义---------------------------------------').
    me->set_source('DATA ok_code TYPE sy-ucomm. "ok_code').
    me->set_source('DATA gv_ttext TYPE tstct-ttext. "title文本').
    me->set_source('DATA gv_mode TYPE char2. "屏幕分割标识').
    me->set_source('DATA gv_tree TYPE c. "是否启用alv_tree').
    me->space( ).
    me->set_source('*---------------选择屏幕-------------------------------------------').
    me->set_source('SELECTION-SCREEN:BEGIN OF BLOCK b1 WITH FRAME TITLE txt1.').
    me->space( ).

    me->set_source('SELECT-OPTIONS s_ucomm FOR SSCRFIELDS-ucomm.').
    me->space( ).
    me->set_source('SELECTION-SCREEN:END OF BLOCK b1.').
    me->space( ).

    me->set_source('"Defin class 大部分通用类').

    lv_source = gs_config-name && '_cls_define.'.
    CONCATENATE 'INCLUDE' lv_source INTO lv_source SEPARATED BY space.
    me->set_source( lv_source ).
    IF gs_config-tree = 'X'.
      me->set_source('"Alv_Tree 的类实现与定义').
      me->set_source('INCLUDE zdemo_hgy_alv4_tree.').
    ENDIF.
    me->set_source('"Alv_gird与Gcl_event_receiver的类以及其他类的实现').
    lv_source = gs_config-name && '_cls_impl.'.
    CONCATENATE 'INCLUDE' lv_source INTO lv_source SEPARATED BY space.
    me->set_source( lv_source ).

    IF gs_config-status = 'X'.
      me->set_source('"标准Status').
      me->set_source('INCLUDE zgit_module.').
    ELSE.

      lv_source = gs_config-name && 'module.'.
      CONCATENATE 'INCLUDE' lv_source INTO lv_source SEPARATED BY space.
      me->set_source( lv_source ).

    ENDIF.
    me->space( ).

    me->set_source( 'INITIALIZATION.  "IniTiaLiZaTion' ).
    me->space( ).

    me->set_source( '  "设置标题为tcode标题' ).
    me->set_source( '  SELECT SINGLE ttext FROM tstct INTO @gv_ttext' ).
    me->set_source( '    WHERE tcode = @sy-tcode.' ).

    CONCATENATE '''' 'TITLE' '''' INTO lv_source .
    CONCATENATE '  SET TITLEBAR' lv_source 'WITH gv_ttext.' INTO lv_source SEPARATED BY space.

    me->set_source( lv_source ).
    me->set_source( 'AT SELECTION-SCREEN OUTPUT.  "Pbo' ).
    me->space( ).

    me->set_source( 'AT SELECTION-SCREEN.  "Pai' ).
    me->space( ).

    me->set_source( 'START-OF-SELECTION.  "Start' ).
    me->space( ).
    me->set_source( 'gcl_monitor->start( p_debug ).' ).

    CONCATENATE 'gcl_alv_mode->mode =' gs_config-mode '.' INTO lv_source SEPARATED BY space.
    me->set_source( lv_source ).
    me->space( ).

    IF gs_config-tree = 'X'.
      CONCATENATE 'gcl_alv_mode->tree = abap_true' '  .' INTO lv_source SEPARATED BY space.
      me->set_source( lv_source ).
    ENDIF.

    me->set_source( '"标准日志启用，对程序的影响是在点击状态按钮的时候，启用了，会调用标准日志弹窗' ).
    me->set_source( '"不启用，调用falv，将bapirettab的数据展示出来' ).
    IF gs_config-ziflog = 'X'.
      CONCATENATE 'gcl_alv_mode->ziflog = abap_true' '  .' INTO lv_source SEPARATED BY space.
    ELSE.
      CONCATENATE 'gcl_alv_mode->ziflog = abap_false' '  .' INTO lv_source SEPARATED BY space.
    ENDIF.

    me->set_source( lv_source ).
    CLEAR lv_source.
    me->set_source( '  "默认alv1 对应内表gt_data1  alv2对应内表gt_data2' ).

    "判断 gt_mode 是否为空
    CLEAR lv_source.
    IF gt_mode IS NOT INITIAL.
      me->set_source( '  "如需指定alv对应特殊名的内表，' ).
      me->set_source( '  gcl_alv_mode->t_mode = VALUE #( ' ).
      LOOP AT gt_mode INTO gs_mode.

        CONCATENATE '''' gs_mode-handle '''' INTO gs_mode-handle.
        CONCATENATE '''' gs_mode-tabnam '''' INTO gs_mode-tabnam.
        CONCATENATE '( handle = '  gs_mode-handle  'tabnam = '  gs_mode-tabnam ')' INTO lv_source SEPARATED BY space.
        AT LAST.
          CONCATENATE lv_source ').' INTO lv_source SEPARATED BY space.
        ENDAT.
        me->set_source( lv_source ).

      ENDLOOP.
    ENDIF.

    me->set_source( '  SET HANDLER gcl_msg->display_msg FOR ALL INSTANCES.' ).
    me->set_source( '  "取数' ).
    me->set_source( '  DATA(lcl_data) = NEW gcl_data( ).' ).
    me->set_source( '  lcl_data->main( ).' ).

    me->set_source( 'END-OF-SELECTION.    "End' ).
    me->space( ).
    me->set_source( 'gcl_monitor->end( ).' ).
    me->set_source( 'FREE gcl_monitor.' ).
    me->set_source( '  CHECK gcl_msg->zif_msg~handle_msg NE abap_true.' ).
    me->set_source( '  FREE lcl_data.' ).
    me->set_source( '  CALL SCREEN 100.' ).

    DATA(lv_name) = gs_config-name.

    INSERT REPORT lv_name FROM gt_source PROGRAM TYPE '1'   FIXED-POINT ARITHMETIC 'X'.
    COMMIT WORK AND WAIT.
    GENERATE SUBROUTINE POOL gt_source NAME lv_name.

    "增加程序的中英文名称

    me->set_title( EXPORTING  progname = gs_config-name
                                title    = gs_config-title
                                title_e  = gs_config-title_e ).


  ENDMETHOD.

  METHOD set_source.

    gs_source = source.
    APPEND gs_source TO gt_source.
    CLEAR gs_source.

  ENDMETHOD.

  METHOD space.

    CLEAR gs_source.
    APPEND gs_source TO gt_source.
    CLEAR gs_source.

  ENDMETHOD.

  METHOD copy_program.

*    DATA(lt_source) =  NEW zcl_program( )->decode_program( 'ZGIT_ALV' ).
*    REPLACE 'ZGIT_ALV' IN TABLE lt_source WITH gs_config-name.

    DATA: ls_save TYPE trdirt,
          lt_save LIKE TABLE OF ls_save.
    CLEAR:ls_save,lt_save.

    DATA lt_source TYPE soli_tab.
    CLEAR lt_source.
    DATA lv_target TYPE progname.
    CLEAR lv_target.

    DATA lv_name TYPE progname.
    DATA lv_title TYPE ze_git_title.

    lv_target = gs_config-name && '_CLS_DEFINE'.
    lv_name = lv_target.
    READ REPORT 'ZGIT_ALV_CLS_DEFINE'  INTO lt_source.
    INSERT REPORT lv_target  FROM lt_source PROGRAM TYPE 'I'  FIXED-POINT ARITHMETIC 'X'.
    COMMIT WORK AND WAIT.
    GENERATE SUBROUTINE POOL lt_source NAME lv_target.

    lv_title = lv_name.
    me->set_title( EXPORTING    progname = lv_name
                                title    = lv_title
                                title_e  = lv_title ).

    lv_target = gs_config-name && '_CLS_IMPL'.
    lv_name = lv_target.
    READ REPORT 'ZGIT_ALV_CLS_IMPLEMENTATION'  INTO lt_source.
    INSERT REPORT lv_target  FROM lt_source PROGRAM TYPE 'I'  FIXED-POINT ARITHMETIC 'X'.
    COMMIT WORK AND WAIT.
    GENERATE SUBROUTINE POOL lt_source NAME lv_target.

    lv_title = lv_name.
    me->set_title( EXPORTING    progname = lv_name
                                title    = lv_title
                                title_e  = lv_title ).

    IF gs_config-status NE 'X'.

      lv_target = gs_config-name && '_MODULE'.
      lv_name = lv_target.
      READ REPORT 'ZGIT_ALV_MODULE'  INTO lt_source.
      INSERT REPORT lv_target  FROM lt_source PROGRAM TYPE 'I'  FIXED-POINT ARITHMETIC 'X'.
      COMMIT WORK AND WAIT.
      GENERATE SUBROUTINE POOL lt_source NAME lv_target.

      lv_title = lv_name.
      me->set_title( EXPORTING    progname = lv_name
                                  title    = lv_title
                                  title_e  = lv_title ).

    ENDIF.

  ENDMETHOD.

  METHOD copy_status.

    DATA :lv_cobjname TYPE trdir-name,
          lv_objname  TYPE trdir-name.

    CALL FUNCTION 'ZRS_CUA_COPY'
      EXPORTING
        cobjectname          = 'ZGIT_ALV'
        exit_function        = ' '
        objectname           = gs_config-name
        suppress_checks      = ' '
      IMPORTING
        cobjectname          = lv_cobjname
        objectname           = lv_objname
      EXCEPTIONS
        already_exists       = 1
        not_excecuted        = 2
        object_not_found     = 3
        object_not_specified = 4
        permission_failure   = 5
        unknown_version      = 6
        OTHERS               = 7.
    IF sy-subrc <> 0.

    ENDIF.

  ENDMETHOD.

  METHOD copy_screen.

    DATA ls_rs37a TYPE rs37a.

*ls_rs37a-

    ls_rs37a-qnumb = '0100'.
    ls_rs37a-qprog = 'ZGIT_ALV'.
    ls_rs37a-znumb = '0100'.
    ls_rs37a-zprog = gs_config-name.


    CALL FUNCTION 'RS_SCRP_COPY'
      EXPORTING
        source_dynnr         = ls_rs37a-qnumb
        source_progname      = ls_rs37a-qprog
        target_dynnr         = ls_rs37a-znumb
        target_progname      = ls_rs37a-zprog
      EXCEPTIONS
        illegal_value        = 1
        not_executed         = 2
        no_modify_permission = 3
        source_not_exists    = 4
        target_exists        = 5
        OTHERS               = 6.
    IF sy-subrc <> 0.

    ENDIF.

  ENDMETHOD.
  METHOD trans.
    "调用标准函数，将程序插入请求
    CALL FUNCTION 'RS_CORR_INSERT'
      EXPORTING
        object                   = progname
        object_class             = 'ABAP'
        mode                     = 'I'
        extend                   = ''
        object_class_supports_ma = abap_true
        korrnum                  = ''
      EXCEPTIONS
        cancelled                = 01
        permission_failure       = 02
        unknown_objectclass      = 03.

  ENDMETHOD.
  METHOD set_title.

    DATA: ls_save TYPE trdirt.
    CLEAR:ls_save.

    DATA lt_save TYPE TABLE OF trdirt.

    IF gs_config-title IS NOT INITIAL.
      ls_save-name  = progname.
      ls_save-sprsl = '1'.
      ls_save-text  = title.
      APPEND ls_save TO lt_save.
      CLEAR ls_save.
    ENDIF.

    IF gs_config-title_e IS NOT INITIAL.
      ls_save-name  = progname.
      ls_save-sprsl = 'E'.
      ls_save-text  = title_e.
      APPEND ls_save TO lt_save.
      CLEAR ls_save.
    ENDIF.

    IF lt_save IS NOT INITIAL.

      MODIFY trdirt FROM TABLE lt_save.
      IF sy-subrc = 0.
        COMMIT WORK.
      ELSE.
        ROLLBACK WORK.
      ENDIF.

    ENDIF.

  ENDMETHOD.

ENDCLASS.
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS_0100'.
  LOOP AT SCREEN .
    CASE screen-name.
      WHEN 'GS_CONFIG-TREE'.
        IF gs_config-nm = '1'.
          screen-input = '0'.
        ELSE.

          screen-input = '1'.
        ENDIF.
        MODIFY SCREEN.
    ENDCASE.
  ENDLOOP.

  "将txt编辑器跟文本做挂钩

  DATA lt_soli TYPE soli_tab.

  lt_soli = VALUE #(
( line = |背景：支持单个alv 多个alv 横向 纵向显示| )
( line = |目前只做了左右分屏跟上下分屏，可分为N个，| )
( line = |左边多个屏幕,右面多个这种使用概率不大，暂未考虑在内，有时间再做考虑| )
( line = |一、n 1 代表 上下屏显示N个alv| )
( line = |    1 N 代表左右屏显示N个ALV| )
( line = |    1 1 不分屏| )
( line = |二、多个alv，alv的类是已1，2，3依次类推:| )
( line = |    例如 gcl_alv1,gcl_alv2,且默认是gcl_alv1对应内表gt_data1,| )
( line = |三、如有不同的内表对应，请在左面内表填入例如:| )
( line = |    1  gt_data, 2 gt_item| )
( line = |    程序会自动识别| )
( line = |四、单个ALV不允许开启tree模式，也没有必要开启| )
( line = |五、是否启用SLG标准日志功能，启用的话，默认的状态图标点击会调用标准日志功能| )
( line = |六、程序监控功能,启用的话，会调用类zcl_report_monitor来记录程序| )
).

  DATA(lcl_edit) = NEW cl_gui_textedit(
        parent                     = NEW cl_gui_custom_container( container_name = 'CON1' )
        wordwrap_mode              = cl_gui_textedit=>wordwrap_at_windowborder
        wordwrap_position          = 256
        wordwrap_to_linebreak_mode = cl_gui_textedit=>true ).

  lcl_edit->set_text_as_r3table( EXPORTING table = lt_soli ).
  lcl_edit->protect_selection( protect_mode = 1  enable_editing_protected_text = 1 ).

  lcl_edit->protect_lines( from_line = '1'
  to_line = '200'
  protect_mode = 1
  enable_editing_protected_text = 1 ).
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  CASE ok_code.

    WHEN '&F03' OR '&F12' OR '&F15'.

      LEAVE TO SCREEN 0.

  ENDCASE.

  CLEAR ok_code.
  CLEAR sy-ucomm.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  GET_NM  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_nm INPUT.

  "根据mode判断一下alv的个数

  DATA(lv_rows) = gs_config-mode(1).
  DATA(lv_columns) = gs_config-mode+1(1).

  IF lv_rows > lv_columns.

    gs_config-nm = lv_rows.

  ELSEIF lv_rows < lv_columns.

    gs_config-nm = lv_columns.

  ELSE.

    gs_config-nm = '1'.

  ENDIF.

  IF gs_config-nm = '1'.
    "单个alv，默认是使用gt_data 作为内表
    gs_mode-handle = '1'.
    gs_mode-tabnam = 'GT_DATA'.
    APPEND gs_mode TO gt_mode.
    CLEAR gs_mode.
  ENDIF.

ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100_1  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100_1 INPUT.

  CASE ok_code.

    WHEN 'INS'.

      "获取alv个数，获取alv行数

      DATA(line) = lines( gt_mode ) + 1.

      IF line > gs_config-nm.

        MESSAGE '已超出Alv数量' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.

      ENDIF.

      APPEND gs_mode TO gt_mode.
      CLEAR gs_mode.

    WHEN 'DEL'.

      "获取选中的行

      DATA lv_line TYPE i.
      GET CURSOR LINE lv_line.

      DELETE gt_mode INDEX lv_line.

    WHEN 'EXEC'.

      IF gs_config-nm = '1' AND gs_config-tree = 'X'.

        MESSAGE '单一ALV不允许开启tree接口' TYPE 'I' DISPLAY LIKE 'E'.
        RETURN.

      ENDIF.

      "检查程序是否已经存在

      CHECK gs_config-name(1) <> '='.
      SELECT COUNT(*) FROM progdir WHERE name = gs_config-name
                                     AND state = 'I'.
      IF sy-subrc NE 0.
        SELECT COUNT(*) FROM progdir WHERE name = gs_config-name
                                       AND state = 'A'.
        IF sy-subrc = 0.

        ENDIF.

      ENDIF.

      IF sy-subrc <> 0.


      ELSE.

        MESSAGE '程序已存在，不允许再次生成' TYPE 'I' DISPLAY LIKE 'E'.
        RETURN.

      ENDIF.

      DATA(se38) = NEW se38( ).

      se38->set_main( ).

      se38->copy_program( ).
*      PERFORM show_own_orders.
      se38->trans( gs_config-name ).
      se38->trans( gs_config-name && '_CLS_IMPLEMENTATION').
      se38->trans( gs_config-name && '_CLS_DEFINE' ).

      IF gs_config-status NE 'X'.
        se38->trans( gs_config-name && '_Module' ).
      ENDIF.

      se38->copy_status( ).
      se38->copy_screen( ).
    WHEN 'SUBMIT'.

      CALL FUNCTION 'RS_TOOL_ACCESS' ##fm_subrc_ok
        EXPORTING
          operation           = 'SHOW'
          object_name         = gs_config-name
          object_type         = 'PROG'
        EXCEPTIONS
          not_executed        = 1
          invalid_object_type = 2
          OTHERS              = 3.

  ENDCASE.

  CLEAR ok_code.
  CLEAR sy-ucomm.

ENDMODULE.

*&SPWIZARD: DECLARATION OF TABLECONTROL 'TC1' ITSELF
CONTROLS: tc1 TYPE TABLEVIEW USING SCREEN 0100.

*&SPWIZARD: OUTPUT MODULE FOR TC 'TC1'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: UPDATE LINES FOR EQUIVALENT SCROLLBAR
MODULE tc1_change_tc_attr OUTPUT.
  DESCRIBE TABLE gt_mode LINES tc1-lines.
ENDMODULE.

*&SPWIZARD: INPUT MODULE FOR TC 'TC1'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: MODIFY TABLE
MODULE tc1_modify INPUT.
  MODIFY gt_mode
    FROM gs_mode
    INDEX tc1-current_line.
ENDMODULE.

*&SPWIZARD: INPUT MODUL FOR TC 'TC1'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: MARK TABLE
MODULE tc1_mark INPUT.
  DATA: g_tc1_wa2 LIKE LINE OF gt_mode.
  IF tc1-line_sel_mode = 1
  AND gs_mode-sel = 'X'.
    LOOP AT gt_mode INTO g_tc1_wa2
      WHERE sel = 'X'.
      g_tc1_wa2-sel = ''.
      MODIFY gt_mode
        FROM g_tc1_wa2
        TRANSPORTING sel.
    ENDLOOP.
  ENDIF.
  MODIFY gt_mode
    FROM gs_mode
    INDEX tc1-current_line
    TRANSPORTING sel.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  GET_ZIFLOG  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_ziflog INPUT.

  IF gs_config-ziflog IS NOT INITIAL.
    MESSAGE '请不要忘记到tcod:SLG0中创建日志对象' TYPE 'I' DISPLAY LIKE 'E'.
  ENDIF.

ENDMODULE.
