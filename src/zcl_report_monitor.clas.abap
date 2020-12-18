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


  METHOD CONSTRUCTOR.
    "将传入的程序名传递到属性中
    repid = i_repid.
    "判断日志功能是否在配置表中关闭
    SELECT SINGLE zif_monitor FROM zrepmor_config INTO disabled
      WHERE repid = repid.

  ENDMETHOD.


  METHOD END.
    IF disabled = abap_true.
      RETURN.
    ENDIF.
    GET TIME STAMP FIELD gs_monitor-end_time.
    UPDATE ztabap_rep_mon
    SET end_time = gs_monitor-end_time
    WHERE guid = gs_monitor-guid.
    IF sy-subrc = 0.
      COMMIT WORK.
    ELSE.
      ROLLBACK WORK.
    ENDIF.

  ENDMETHOD.


  METHOD START.

    IF debug = abap_true.
      BREAK-POINT AT NEXT APPLICATION STATEMENT.
    ELSE.

      IF disabled = abap_true.
        RETURN.
      ENDIF.

      DATA: lt_sel_table TYPE TABLE OF rsparams.
      DATA: lv_id            TYPE c LENGTH 62,
            lv_computer_name TYPE string.

      TRY.
          gs_monitor-guid = cl_system_uuid=>create_uuid_x16_static( ).
        CATCH cx_uuid_error INTO DATA(/afl/oref).
      ENDTRY.

      CALL FUNCTION 'RS_REFRESH_FROM_SELECTOPTIONS'
        EXPORTING
          curr_report     = repid
        TABLES
          selection_table = lt_sel_table.
      gs_monitor-selection_table = /ui2/cl_json=>serialize( data = lt_sel_table ).
      FREE lt_sel_table.

      GET  TIME STAMP FIELD gs_monitor-start_time.
      gs_monitor-repid = repid.
      gs_monitor-starttime = gs_monitor-start_time.
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

      IF sy-subrc = 0.
        COMMIT WORK.
      ELSE.
        ROLLBACK WORK.
      ENDIF.
    ENDIF.

  ENDMETHOD.
ENDCLASS.
