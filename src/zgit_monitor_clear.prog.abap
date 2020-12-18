*&---------------------------------------------------------------------*
*& Report ZGIT_MONITOR_CLEAR
*&---------------------------------------------------------------------*
*& 采用定时JOB的方式，按照一定的期间频率来清理日志表，防止数据量过多
*& author :Limiter
*&---------------------------------------------------------------------*
REPORT zgit_monitor_clear.

DATA ls_mon TYPE ztabap_rep_mon.

SELECT-OPTIONS:s_repid FOR ls_mon-repid NO INTERVALS,
               s_zdate FOR ls_mon-zdate.

PARAMETERS p_day TYPE i OBLIGATORY DEFAULT 30. "默认只留30天的日志

START-OF-SELECTION.

  DATA lr_zdate TYPE RANGE OF ztabap_rep_mon-zdate.

  IF s_zdate[] IS NOT INITIAL.
    lr_zdate = s_zdate[].
  ELSE.
    "计算当前日期往前推30天的日期
    lr_zdate = VALUE #( ( sign = 'I' option = 'EQ' low = '00000000' high = sy-datum - 30 ) ).
  ENDIF.

  "进行删除
  DELETE FROM ztabap_rep_mon WHERE repid IN s_repid
                               AND zdate IN lr_zdate.
  IF sy-subrc = 0.
    COMMIT WORK.
  ELSE.
    ROLLBACK WORK.
  ENDIF.
