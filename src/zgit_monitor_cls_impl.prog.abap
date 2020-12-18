*&---------------------------------------------------------------------*
*& 包含               ZGIT_ALV_CLS_IMPLEMENTATION
*&---------------------------------------------------------------------*
*----------------------------------------------------------------------*
*       CLASS gcl_data IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS gcl_data IMPLEMENTATION."数据处理类的实现

  METHOD main.
    author_check( ).
    get_data( ).
    deal_data( ).
  ENDMETHOD.
  METHOD author_check.


  ENDMETHOD.

  METHOD get_data.
    DATA:
      lt_monitor TYPE TABLE OF ztabap_rep_mon,
      ls_monitor TYPE ztabap_rep_mon.

    SELECT
      *
    FROM ztabap_rep_mon
    INTO TABLE lt_monitor
    WHERE repid IN s_repid
      AND zdate IN s_zdate.
    IF sy-subrc NE 0.
      RETURN.
    ENDIF.

    LOOP AT lt_monitor INTO ls_monitor GROUP BY ( repid = ls_monitor-repid )
                                        ASSIGNING FIELD-SYMBOL(<group>).

      gs_overview-repid = <group>-repid.
      LOOP AT GROUP <group> ASSIGNING FIELD-SYMBOL(<ls_group>).
        IF <ls_group>-end_time IS NOT INITIAL.
          gs_overview-avg_time = gs_overview-avg_time + calc_second( timestampl1 = <ls_group>-start_time
                                                                     timestampl2 = <ls_group>-end_time ).
        ENDIF.
        gs_overview-count = gs_overview-count + 1.

        MOVE-CORRESPONDING <ls_group> TO gs_detail.
        IF gs_detail-end_time > gs_detail-start_time.
          gs_detail-proc_time = calc_second( timestampl1 = ls_monitor-start_time
                                             timestampl2 = ls_monitor-end_time ).
        ENDIF.
        IF gs_detail-end_time IS INITIAL.
          gs_detail-color = 'C601'.
        ENDIF.
        APPEND gs_detail TO gt_detail.
        CLEAR gs_detail.

      ENDLOOP.

      IF gs_overview-real_count <> 0.
        gs_overview-avg_time = gs_overview-avg_time / gs_overview-real_count.
      ENDIF.
      APPEND gs_overview TO gt_overview.
      CLEAR gs_overview.
      CLEAR ls_monitor.
    ENDLOOP.

    FREE lt_monitor.

    IF gt_overview IS NOT INITIAL.

      DATA:BEGIN OF ls_trdirt,
             name TYPE trdirt-name,
             text TYPE trdirt-text,
           END OF ls_trdirt,
           lt_trdirt LIKE TABLE OF ls_trdirt.

      SELECT
        name
        text
        FROM trdirt INTO TABLE lt_trdirt
        FOR ALL ENTRIES IN gt_overview
        WHERE name = gt_overview-repid
          AND sprsl = sy-langu.
      SORT lt_trdirt BY name.

      LOOP AT gt_overview INTO gs_overview.
        READ TABLE lt_trdirt INTO ls_trdirt WITH KEY name = gs_overview-repid.
        IF sy-subrc = 0.
          gs_overview-repti = ls_trdirt-text.
        ENDIF.
        CLEAR ls_trdirt.
        MODIFY gt_overview FROM gs_overview.
        CLEAR gs_overview.
      ENDLOOP.

    ENDIF.

  ENDMETHOD.

  METHOD deal_data.


  ENDMETHOD.

  METHOD calc_second.

    DATA: l_d1 TYPE d,
          l_t1 TYPE t,
          l_s1 TYPE p DECIMALS 6,
          l_d2 TYPE d,
          l_t2 TYPE t,
          l_s2 TYPE p DECIMALS 6.

    CONVERT TIME STAMP timestampl1 TIME ZONE sy-zonlo INTO DATE l_d1 TIME l_t1.
    l_s1 = frac( timestampl1 ).
    CONVERT TIME STAMP timestampl2 TIME ZONE sy-zonlo INTO DATE l_d2 TIME l_t2.
    l_s2 = frac( timestampl2 ).
    seconds = ( l_d2 - l_d1 ) * 86400 + l_t2 - l_t1 + l_s2 - l_s1.

  ENDMETHOD.

ENDCLASS.
*----------------------------------------------------------------------*
*       CLASS LCL_EVENT_RECEIVER IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS gcl_event_receiver IMPLEMENTATION.

  METHOD constructor.
    objid = i_objid.
  ENDMETHOD.
  "ALV内表展示处单击事件捕捉，需要设置热点对单击列字段
  METHOD handle_hotspot_click.

    READ TABLE gt_overview ASSIGNING FIELD-SYMBOL(<fs_data>) INDEX es_row_no-row_id.
    "-> 在此位置添加单击事件，可参照父类代码
    ASSIGN COMPONENT 'REPID' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_repid>).
    CASE e_column_id-fieldname.
      WHEN 'COUNT'.
        IF sy-subrc = 0.
          DATA lt_filter TYPE lvc_t_filt.
          lt_filter = VALUE #( ( fieldname = 'REPID' sign = 'I' option = 'EQ'  low = <fs_repid> ) ).
          gcl_alv2->set_filter_criteria( lt_filter ).
          alv_action=>refresh(  gcl_alv2 ).
        ENDIF.
        "点击的时候，将右面的屏幕显示出来
        IF gv_mode = '12'.
          gcl_split_container->set_column_width( EXPORTING id = 1 width = 600 ).
        ELSE.
          gcl_split_container->set_row_height( EXPORTING id = 1 height = 30 ).
        ENDIF.
      WHEN 'REPID'.
        CALL FUNCTION 'RS_TOOL_ACCESS' ##fm_subrc_ok
          EXPORTING
            operation           = 'SHOW'
            object_name         = <fs_repid>
            object_type         = 'PROG'
          EXCEPTIONS
            not_executed        = 1
            invalid_object_type = 2
            OTHERS              = 3.

    ENDCASE.

  ENDMETHOD.

  METHOD handle_toolbar.
    "标准按钮功能
    me->default_toobar( e_object = e_object ).

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
    CASE objid.
      WHEN '1'.

      WHEN '2'.
        mar_toolbar:
            'DELETE'    '' '删除日志' icon_delete.
        "增加menu
        MOVE 'SEL_TAB' TO ls_toolbar-function.
        MOVE icon_selection TO ls_toolbar-icon.
        MOVE 2 TO ls_toolbar-butn_type.
        MOVE '选择条件' TO ls_toolbar-quickinfo.
        MOVE ' ' TO ls_toolbar-disabled.
        APPEND ls_toolbar TO e_object->mt_toolbar.
        CLEAR ls_toolbar.

        MOVE 'EXECUTE' TO ls_toolbar-function.
        MOVE  icon_execute_object TO ls_toolbar-icon.
        MOVE 2 TO ls_toolbar-butn_type.
        MOVE '执行' TO ls_toolbar-quickinfo.
        MOVE ' ' TO ls_toolbar-disabled.
        APPEND ls_toolbar TO e_object->mt_toolbar.
        CLEAR ls_toolbar.

    ENDCASE.

  ENDMETHOD.                    "HANDLE_TOOLBAR
  METHOD menu_button.
    CASE e_ucomm.
      WHEN 'SEL_TAB'.

        e_object->add_function( fcode = 'SEL_TAB'
                                text  = '选择条件' ).
        e_object->add_function( fcode = 'MASK'
                                text  = '选择条件（外码）' ).
      WHEN 'EXECUTE'.

        e_object->add_function( fcode = 'EXECUTE'
                                text  = '执行' ).
        e_object->add_function( fcode = 'DEBUG'
                                text  = '调试执行' ).
    ENDCASE.
  ENDMETHOD.
* 响应用户命令
  METHOD handle_user_command.

    "标准按钮处理
    me->default_user_command( e_ucomm = e_ucomm ).

    "->在此位置添加按钮事件，可参照父类代码
    DATA lv_error TYPE abap_bool.
    CLEAR lv_error.
    CASE e_ucomm.
      WHEN 'DELETE'.
        lv_error = get_rows( EXPORTING alv_grid =  gcl_alv1
                             CHANGING it_data =  gt_detail ).

        CHECK lv_error NE abap_true.

        DATA: ls_mon TYPE ztabap_rep_mon,
              lt_mon LIKE TABLE OF ls_mon.

        LOOP AT gt_detail INTO gs_detail WHERE sel = abap_true.
          MOVE-CORRESPONDING gs_detail TO ls_mon.
          APPEND ls_mon TO lt_mon.
          CLEAR ls_mon.
        ENDLOOP.

        DELETE ztabap_rep_mon FROM TABLE lt_mon.
        IF sy-subrc = 0.
          COMMIT WORK.
          MESSAGE '删除成功' TYPE 'I' DISPLAY LIKE 'S'.
        ELSE.
          ROLLBACK WORK.
          MESSAGE '删除失败' TYPE 'I' DISPLAY LIKE 'E'.
        ENDIF.
        "重新走取数逻辑
        NEW gcl_data( )->main( ).

      WHEN 'SEL_TAB' OR 'MASK' OR 'EXECUTE' OR 'DEBUG'.
        "获取选中行
        lv_error = get_rows( EXPORTING  alv_grid =  gcl_alv2
                             CHANGING   it_data =  gt_detail ).
        CHECK lv_error NE abap_true.
        "获取改行的程序名
        READ TABLE gt_detail INTO gs_detail WITH KEY sel = abap_true.

        ASSIGN COMPONENT 'REPID' OF STRUCTURE gs_detail TO FIELD-SYMBOL(<fs_repid>).
        DATA lt_sel_table TYPE TABLE OF rsparams.
        ASSIGN COMPONENT 'SELECTION_TABLE' OF STRUCTURE gs_detail
                                           TO FIELD-SYMBOL(<selection_table>).
        IF sy-subrc = 0.
          "将json转换为内表
          /ui2/cl_json=>deserialize( EXPORTING json = <selection_table> CHANGING data = lt_sel_table ).
        ENDIF.

        CASE e_ucomm.
          WHEN 'SEL_TAB' OR 'MASK'.

            DATA:lt_alv TYPE typt_para_alv,
                 ls_alv TYPE typ_para_alv.
            CLEAR:ls_alv,lt_alv.
            FIELD-SYMBOLS <fs_alv> TYPE typ_para_alv.

            MOVE-CORRESPONDING lt_sel_table TO lt_alv.
            FREE lt_sel_table.
            "读取选择文本
            DATA lt_texttab TYPE TABLE OF textpool.
            READ TEXTPOOL <fs_repid> LANGUAGE sy-langu INTO lt_texttab.
            "填充到alv内表
            LOOP AT lt_alv ASSIGNING <fs_alv>.
              READ TABLE lt_texttab INTO DATA(ls_texttab) WITH KEY key = <fs_alv>-selname.
              IF sy-subrc = 0.
                <fs_alv>-text = ls_texttab-entry.
              ENDIF.
              CLEAR ls_texttab.
            ENDLOOP.

            CALL FUNCTION 'RS_TEXTPOOL_READ'
              EXPORTING
                objectname           = <fs_repid>
*               ACTION               = 'EDIT'
*               AUTHORITY_CHECK      = ' '
                language             = sy-langu
              TABLES
                tpool                = lt_texttab
              EXCEPTIONS
                object_not_found     = 1
                permission_failure   = 2
                invalid_program_type = 3
                error_occured        = 4
                action_cancelled     = 5
                OTHERS               = 6.
            IF sy-subrc <> 0.

            ENDIF.


            IF  e_ucomm = 'MASK'.  "转码
              PERFORM (space) IN PROGRAM (<fs_repid>) IF FOUND.
              LOOP AT lt_alv ASSIGNING <fs_alv>.
                CONCATENATE '(' <fs_repid> ')' <fs_alv>-selname INTO DATA(lv_fieldname).
                IF <fs_alv>-kind = 'S'.
                  CONCATENATE lv_fieldname '-LOW' INTO lv_fieldname.
                ENDIF.
                ASSIGN (lv_fieldname) TO FIELD-SYMBOL(<fs_field>).
                CHECK sy-subrc = 0.
                DESCRIBE FIELD <fs_field> EDIT MASK DATA(lv_mask).
                CHECK lv_mask IS NOT INITIAL.
                IF <fs_alv>-low IS NOT INITIAL.
                  WRITE <fs_alv>-low TO <fs_alv>-low USING EDIT MASK lv_mask.
                ENDIF.
                IF <fs_alv>-high IS NOT INITIAL.
                  WRITE <fs_alv>-high TO <fs_alv>-high USING EDIT MASK lv_mask.
                ENDIF.
              ENDLOOP.
            ENDIF.

            "调用alv
            DATA(falv) = zcl_falv=>create( EXPORTING i_popup = abap_true
                                           CHANGING ct_table = lt_alv ).
            falv->column( 'SELNAME')->set_coltext( '字段名' ).
            falv->column( 'TEXT'   )->set_coltext( '字段描述' ).
            falv->column( 'KIND'   )->set_coltext( 'P:单值/S:多值' ).
            falv->column( 'SIGN'   )->set_coltext( 'I:包含/E:不包含' ).
            falv->column( 'OPTION' )->set_coltext( 'EQ/BT/CP' ).
            falv->column( 'LOW'    )->set_coltext( 'LOW' ).
            falv->column( 'HIGH'   )->set_coltext( 'HIGH' ).

            falv->layout->set_cwidth_opt( abap_true )->set_no_toolbar( abap_true ).
            falv->display( ).

          WHEN 'EXECUTE'.
            SUBMIT (<fs_repid>) WITH SELECTION-TABLE lt_sel_table
                                VIA SELECTION-SCREEN AND RETURN.
          WHEN 'DEBUG'.
            SUBMIT (<fs_repid>) WITH SELECTION-TABLE lt_sel_table
                                VIA SELECTION-SCREEN WITH p_debug = abap_true
                                AND RETURN.
        ENDCASE.
    ENDCASE.
  ENDMETHOD.                    "HANDLE_USER_COMMAND

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
        mar_toolbar 'EXPAND' '' '展开' icon_expand.
        mar_toolbar 'COLLPASE'  '' '折叠' icon_collapse.
      WHEN OTHERS.
    ENDCASE.
  ENDMETHOD.
  METHOD default_user_command.
    CASE e_ucomm.
      WHEN 'EXPAND'.
        IF gv_mode = '12'.
          gcl_split_container->set_column_width( EXPORTING id = 1 width = 600 ).
        ELSE.
          gcl_split_container->set_row_height( EXPORTING id = 1 height = 30 ).
        ENDIF.
      WHEN 'COLLPASE'.
        IF gv_mode = '12'.
          gcl_split_container->set_column_width( EXPORTING id = 1 width = 2050 ).
        ELSE.
          gcl_split_container->set_row_height( EXPORTING id = 1 height = 100 ).
        ENDIF.
    ENDCASE.
  ENDMETHOD.
  METHOD get_rows.

    LOOP AT  it_data ASSIGNING FIELD-SYMBOL(<ls_data>).
      ASSIGN COMPONENT 'SEL' OF STRUCTURE <ls_data> TO FIELD-SYMBOL(<fs>).
      IF sy-subrc = 0.
        CLEAR <fs>.
      ENDIF.
    ENDLOOP.
    DATA lt_row TYPE lvc_t_row.
    alv_grid->get_selected_rows( IMPORTING et_index_rows = lt_row ).

    IF lt_row IS INITIAL.
      MESSAGE '请至少选中一行数据进行操作' TYPE 'S' DISPLAY LIKE 'W' .
      error = abap_true.
      RETURN.
    ENDIF.

    IF only_check = abap_true AND lines( lt_row ) > 1.
      MESSAGE '只允许选中一行数据进行操作' TYPE 'S' DISPLAY LIKE 'W' .
      error = abap_true.
      RETURN.
    ENDIF.

    LOOP AT lt_row INTO DATA(ls_row).
      READ TABLE it_data ASSIGNING <ls_data> INDEX ls_row-index.
      IF sy-subrc = 0.
        ASSIGN COMPONENT 'SEL' OF STRUCTURE <ls_data> TO <fs>.
        IF sy-subrc = 0.
          <fs> = abap_true.
        ENDIF.
      ENDIF.
      CLEAR ls_row.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS. "LCL_EVENT_RECEIVER IMPLEMENTATION

CLASS gcl_alv_display IMPLEMENTATION."alv展示类

  METHOD get_fieldcat.

    DATA ls_fcat TYPE lvc_s_fcat.
    CLEAR ls_fcat.

    DEFINE mar_field.
      ls_fcat-fieldname  = &1.
      ls_fcat-ref_table  = &2.
      ls_fcat-ref_field  = &3.
      ls_fcat-hotspot    = &4.
      ls_fcat-just       = &5.
      ls_fcat-outputlen  = &6.
      ls_fcat-scrtext_l  = &7.
      ls_fcat-colddictxt = 'L'.
       APPEND ls_fcat TO fcat.
       CLEAR ls_fcat.
    END-OF-DEFINITION.

    CASE handle.
      WHEN '1'.
        mar_field 'REPID'      'SYST'       'REPID'       'X' 'L' 20  '程序名称'.
        mar_field 'REPTI'      'TRDIRT'     'REPTI'       ' ' 'L' 40  '程序描述'.
        mar_field 'COUNT'      'SAPWLTCOD1' 'SWLDIASTEP'  'X' 'C' 7   '执行次数'.
        mar_field 'REAL_COUNT' 'SAPWLTCOD1' 'SWLDIASTEP'  ' ' 'C' 7   '有效次数'.
        ls_fcat-decimals_o = 3.
        mar_field 'AVG_TIME'   ''           ''            ' ' 'R' 13  '平均执行时间(s)'.
      WHEN '2'.
        mar_field:
       'REPID'          'SYST'  'REPID'  ' ' 'L' 20  '程序名称',
       'ZDATE'          'SYST'  'DATUM'  ' ' 'L' 10  '日期',
       'ZTIME'          'SYST'  'UZEIT'  ' ' 'L' 8   '时间',
       'ZUSR'           'SYST'  'UNAME'  ' ' 'L' 12  '用户',
       'COMPUTER_NAME'  '    '  '     '  ' ' 'C' 20  '计算机名',
       'IP_ADDRESS'     '    '  '     '  ' ' 'L' 13  'IP地址',
       'TCODE'          'SYST'  'TCODE'  ' ' 'L' 15  '事务代码'.
        ls_fcat-decimals_o = 3.
        mar_field:
        'PROC_TIME'      ''      ''       ' ' 'R' 14  '执行时间(s)'.

    ENDCASE.


  ENDMETHOD.

  METHOD get_layout.

    layout-zebra = 'X'."隔行换色
    layout-cwidth_opt = abap_true.     "优化列宽设置
    layout-sel_mode       = 'D'. "alv选择模式
    layout-info_fname = 'COLOR'.
  ENDMETHOD.
  METHOD alv_grid.

    split_container( ).
    "第一个alv
    DATA(lcl_event1) = NEW gcl_event_receiver( i_objid = '1' ).
    alv_out( EXPORTING container =  gcl_split_container->get_container( row = 1  column = 1 )
                       iv_handle = '1'
                       evf_cls = lcl_event1
             CHANGING  data = gt_overview
                       alv_grid = gcl_alv1 ).

    "第二个alv
    IF gv_mode = '12'.
      DATA(lcl_split) = gcl_split_container->get_container( row = 1  column = 2 ).
    ELSE.
      lcl_split = gcl_split_container->get_container( row = 2  column = 1 ).
    ENDIF.

    DATA(lcl_event2) = NEW gcl_event_receiver( i_objid = '2' ).
    alv_out( EXPORTING container =  lcl_split
                       iv_handle = '2'
                       evf_cls = lcl_event2
             CHANGING  data = gt_detail
                       alv_grid = gcl_alv2 ).

  ENDMETHOD.

  METHOD split_container.

    DATA: lv_rows    TYPE i,
          lv_columns TYPE i.
    lv_rows = gv_mode(1).
    lv_columns = gv_mode+1(1).

    IF gcl_split_container IS NOT BOUND.
      gcl_split_container =
      NEW cl_gui_splitter_container(
                                    parent  = NEW cl_gui_docking_container( repid = sy-repid
                                                                            dynnr = sy-dynnr
                                                                            extension = 2050 )
                                    rows    = lv_rows
                                    columns = lv_columns ).
    ENDIF.

    "增加布局转换的逻辑，上下屏改为左右屏
    "增加布局转换的逻辑，上下屏改为左右屏
    CASE ok_code.
      WHEN 'CLAYOUT'.
        FREE gcl_alv1.
        FREE gcl_alv2.
        gcl_split_container->set_grid( rows = CONV #( gv_mode(1) )
                                       columns = CONV #( gv_mode+1(1) ) ).
    ENDCASE.
    "设置边框
    gcl_split_container->set_border( cl_gui_cfw=>true ).
    "设置为相对模式
    gcl_split_container->set_column_mode( gcl_split_container->mode_absolute ).
    "默认隐藏下面或者右面的alv
    IF gv_mode = '12'.
      gcl_split_container->set_column_width( EXPORTING id = 1 width = 2050 ).
    ELSE.
      gcl_split_container->set_row_height( EXPORTING id = 1 height = 100 ).
    ENDIF.

  ENDMETHOD.
  METHOD alv_out.

    DATA:lt_fcat    TYPE lvc_t_fcat,
         ls_layout  TYPE lvc_s_layo,
         ls_variant TYPE disvariant.

    IF  alv_grid IS NOT BOUND.

      alv_grid = NEW #( i_parent = container ).
      lt_fcat   = get_fieldcat( iv_handle ).
      ls_layout = get_layout( ).

      ls_variant-report = sy-repid.
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

        SET HANDLER evf_cls->handle_user_command FOR alv_grid."用户命令
        SET HANDLER evf_cls->handle_toolbar      FOR alv_grid."状态栏
        SET HANDLER evf_cls->menu_button         FOR alv_grid."状态栏下拉
        CALL METHOD alv_grid->set_toolbar_interactive."激活状态栏
        SET HANDLER evf_cls->handle_hotspot_click FOR alv_grid."热点事件

      ENDIF.

    ELSE.
      alv_action=>refresh( alv_grid ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
CLASS alv_action IMPLEMENTATION.
  METHOD refresh.
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
