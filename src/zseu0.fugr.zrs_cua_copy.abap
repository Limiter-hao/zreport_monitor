FUNCTION zrs_cua_copy.
*"--------------------------------------------------------------------
*"*"局部接口：
*"  IMPORTING
*"     VALUE(COBJECTNAME) LIKE  TRDIR-NAME DEFAULT SPACE
*"     VALUE(EXIT_FUNCTION) LIKE  TFDIR-FUNCNAME DEFAULT SPACE
*"     VALUE(OBJECTNAME) LIKE  TRDIR-NAME DEFAULT SPACE
*"     VALUE(SUPPRESS_CHECKS) DEFAULT SPACE
*"  EXPORTING
*"     VALUE(COBJECTNAME) LIKE  TRDIR-NAME
*"     VALUE(OBJECTNAME) LIKE  TRDIR-NAME
*"  EXCEPTIONS
*"      ALREADY_EXISTS
*"      NOT_EXCECUTED
*"      OBJECT_NOT_FOUND
*"      OBJECT_NOT_SPECIFIED
*"      PERMISSION_FAILURE
*"      UNKNOWN_VERSION
*"--------------------------------------------------------------------
  DATA: s_trkey LIKE trkey,
        t_trkey LIKE trkey,
        s_langu LIKE sy-langu,
        t_langu LIKE sy-langu,
        tr_corr LIKE e071-trkorr,
        rcode   TYPE rcode.
  exit_func_name = exit_function.
  IF suppress_checks  = space.
    "Limiter   23.10.2019 14:53:04修改此处{
    rsmpe-program    = cobjectname.
    "}
    rsmpe-cp_program = objectname.
    CLEAR scr_return.
    CALL SCREEN 111 STARTING AT 10 5.
    IF scr_return = con_cancel.
      MESSAGE e237 RAISING not_excecuted.
    ENDIF.
    objectname  = rsmpe-program.
    cobjectname = rsmpe-cp_program.
  ELSE.
*    Quelle
    CALL FUNCTION 'RS_CORR_CHECK'
      EXPORTING
        object              = objectname
        object_class        = con_class_program
        suppress_dialog     = con_true
      IMPORTING
        transport_key       = s_trkey
      EXCEPTIONS
        unknown_objectclass = 0.
    PERFORM get_master_language_trkey USING s_trkey s_langu.
*    Ziel
    CALL FUNCTION 'RS_CORR_INSERT'
      EXPORTING
        object              = cobjectname
        object_class        = con_class_program
        mode                = 'MODIFY'
        extend              = con_true
      IMPORTING
        transport_key       = t_trkey
        ordernum            = tr_corr
      EXCEPTIONS
        cancelled           = 1
        permission_failure  = 2
        unknown_objectclass = 3
        OTHERS              = 4.
    IF sy-subrc NE 0.
      MESSAGE ID     sy-msgid
              TYPE   'E'
              NUMBER sy-msgno
              WITH   sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING permission_failure.
    ENDIF.
    PERFORM copy_frame USING objectname cobjectname
                             s_langu t_langu t_trkey
                             con_true con_false
                             tr_corr
                       CHANGING rcode.
    IF rcode = con_rc_message.
      MESSAGE ID     sy-msgid
              TYPE   'E'
              NUMBER sy-msgno
              WITH   sy-msgv1 sy-msgv2
                     sy-msgv3 sy-msgv2
              RAISING unknown_version.
    ENDIF.
  ENDIF.

ENDFUNCTION.
