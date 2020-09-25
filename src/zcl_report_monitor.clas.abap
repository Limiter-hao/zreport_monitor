class ZCL_REPORT_MONITOR definition
  public
  final
  create public .

public section.

  data REPID type REPID .
  data GS_MONITOR type ZTABAP_REP_MON .
  data DISABLED type ABAP_BOOL .

  methods START
    importing
      !DEBUG type ABAP_BOOL optional .
  methods CONSTRUCTOR
    importing
      value(I_REPID) type REPID .
  methods END .
protected section.
private section.
ENDCLASS.



CLASS ZCL_REPORT_MONITOR IMPLEMENTATION.


  METHOD constructor.
    "将传入的程序名传递到属性中
    repid = i_repid.
    "判断日志功能是否在配置表中关闭
    SELECT SINGLE zif_monitor FROM zrepmor_config INTO disabled
      WHERE repid = repid.

  ENDMETHOD.


  METHOD end.
    IF disabled = abap_true.
      RETURN.
    ENDIF.
    GET TIME STAMP FIELD gs_monitor-end_time.
    UPDATE ztabap_rep_mon
    SET end_time = gs_monitor-end_time
    WHERE relid = 'MO'
    AND repid = repid
    AND starttime = gs_monitor-starttime.

    IF sy-subrc = 0.
      COMMIT WORK.
    ELSE.
      ROLLBACK WORK.
    ENDIF.

  ENDMETHOD.


  METHOD start.

    IF debug = abap_true.
      BREAK-POINT AT NEXT APPLICATION STATEMENT.
    ELSE.

      IF disabled = abap_true.
        RETURN.
      ENDIF.

      DATA: lt_sel_table TYPE TABLE OF rsparams.
      DATA: lv_id            TYPE c LENGTH 62,
            lv_computer_name TYPE string.

      CALL FUNCTION 'RS_REFRESH_FROM_SELECTOPTIONS'
        EXPORTING
          curr_report     = repid
        TABLES
          selection_table = lt_sel_table.

      GET  TIME STAMP FIELD gs_monitor-start_time.
      gs_monitor-relid = 'MO'.
      gs_monitor-repid = repid.
      gs_monitor-starttime = gs_monitor-start_time.
      gs_monitor-srtf2 = 0.
      gs_monitor-zusr = sy-uname.
      IF sy-batch = ''.
        CALL METHOD cl_gui_frontend_services=>get_computer_name
          CHANGING
            computer_name = lv_computer_name.
        cl_gui_cfw=>flush( ).
        gs_monitor-computer_name = lv_computer_name.
        gs_monitor-ip_address = cl_gui_frontend_services=>get_ip_address( ).
      ELSE.
        gs_monitor-computer_name = '[后台JOB]'.
      ENDIF.
      gs_monitor-tcode = sy-tcode.
      gs_monitor-zdate = sy-datum.
      gs_monitor-ztime = sy-uzeit.
      INSERT ztabap_rep_mon FROM gs_monitor.
      "利用datebase存储选择条件，RELID 作为存储id srtf2 作为最大行号，在ztabap_rep_mon 中已定义
      CONCATENATE repid gs_monitor-starttime INTO lv_id RESPECTING BLANKS.
      EXPORT sel_table = lt_sel_table TO DATABASE ztabap_rep_mon(mo) FROM gs_monitor ID lv_id.
      IF sy-subrc = 0.
        COMMIT WORK.
      ELSE.
        ROLLBACK WORK.
      ENDIF.
    ENDIF.

  ENDMETHOD.
ENDCLASS.
