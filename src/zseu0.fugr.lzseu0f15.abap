***INCLUDE LSEU0F15 .
FORM CALL_PRINT_PROGRAM USING PROGRAM     LIKE TRDIR-NAME
                                  SELECTIONS  LIKE RSMPE_PRNT
                                  PARAMETERS  LIKE PRI_PARAMS.
  MKR_MP_SOURCE_TABLES P_.
  DATA: MLANGU LIKE SY-LANGU,
        AUTHOR LIKE EUDB-AUTOR,
        DATE   LIKE EUDB-DATUM,
        TIME   LIKE EUDB-ZEIT,
        CAUTHOR LIKE EUDB-VAUTOR,
        CDATE   LIKE EUDB-VDATUM,
        CTIME   LIKE EUDB-VZEIT,
        GDATE   LIKE EUDB-GDATUM,
        GTIME   LIKE EUDB-GZEIT,
        L_state like progdir-state.

  CALL FUNCTION 'RS_CUA_INTERNAL_GET_READ_STATE'
       EXPORTING
            P_PROGRAM      = program
            P_MODE         = scua_c_mode_display
       IMPORTING
            P_GET_STATE    = l_state.
  CALL FUNCTION 'RS_CUA_INTERNAL_FETCH'
       EXPORTING
            PROGRAM   = PROGRAM
            LANGUAGE  = SELECTIONS-LANGU
            state     = l_state
       IMPORTING
            ADM       = P_ADM
            LANGU     = MLANGU
            AUTHOR    = AUTHOR
            DATE      = DATE
            TIME      = TIME
            CAUTHOR   = CAUTHOR
            CDATE     = CDATE
            CTIME     = CTIME
            GDATE     = GDATE
            GTIME     = GTIME
       TABLES
            STA       = P_STA
            FUN       = P_FUN
            MEN       = P_MEN
            MTX       = P_MTX
            ACT       = P_ACT
            BUT       = P_BUT
            PFK       = P_PFK
            SET       = P_SET
            DOC       = P_DOC
            TIT       = P_TIT
            biv       = p_biv
       EXCEPTIONS
            OTHERS    = 0.
*
  CALL FUNCTION 'RS_CUA_PRINT_TABLES'
       EXPORTING
            PRINT_PROGRAM          = PROGRAM
            PRINT_PARAMETERS = PARAMETERS
            PRINT_SELECTIONS = SELECTIONS
            PRINT_ADM          = P_ADM
            PRINT_MASTER_LANGU = MLANGU
            PRINT_AUTHOR       = AUTHOR
            PRINT_DATE         = DATE
            PRINT_TIME         = TIME
            PRINT_CAUTHOR      = CAUTHOR
            PRINT_CDATE        = CDATE
            PRINT_CTIME        = CTIME
            PRINT_GDATE        = GDATE
            PRINT_GTIME        = GTIME
       TABLES
            PRINT_STA        = P_STA
            PRINT_FUN        = P_FUN
            PRINT_MEN        = P_MEN
            PRINT_MTX        = P_MTX
            PRINT_ACT        = P_ACT
            PRINT_BUT        = P_BUT
            print_biv        = p_biv
            PRINT_PFK        = P_PFK
            PRINT_SET        = P_SET
            PRINT_DOC        = P_DOC
            PRINT_TIT        = P_TIT
       EXCEPTIONS
            OTHERS           = 0.
ENDFORM.

FORM CHECK_PRINT_INPUT.
  DATA: EXISTS.

  IF RSMPE-B_SELOBJ = CON_TRUE AND
     RSMPE-B_STATUS NE SPACE   AND
     PRI_INTERNAL = CON_FALSE.
     CALL FUNCTION 'RS_CUA_INTERNAL_STATUS_CHECK'
          EXPORTING
               PROGRAM       = RSMPE-PROGRAM
               STATUS        = RSMPE-STATUS               "#EC DOM_EQUAL
          IMPORTING
               STATUS_EXISTS = EXISTS
          EXCEPTIONS
               UNKNOWN_VERSION = 1
               OTHERS          = 2.
     IF SY-SUBRC = 1.
         MESSAGE ID     SY-MSGID
                 TYPE   'E'
                 NUMBER SY-MSGNO
                 WITH   SY-MSGV1 SY-MSGV2
                        SY-MSGV3 SY-MSGV2.
     ELSEIF EXISTS = CON_FALSE.
        MESSAGE E121 WITH RSMPE-STATUS RSMPE-PROGRAM.
     ENDIF.
  ELSEIF RSMPE-B_STATUS NE SPACE AND RSMPE-B_SELOBJ = CON_TRUE.
     READ TABLE NEW_STA WITH KEY CODE = RSMPE-STATUS.
     IF SY-SUBRC NE 0.
        MESSAGE E121 WITH RSMPE-STATUS RSMPE-PROGRAM.
     ENDIF.
  ENDIF.
  IF RSMPE-B_SELOBJ  NE SPACE AND
     RSMPE-B_STATUS  =  SPACE AND
     RSMPE-B_BAR     =  SPACE AND
     RSMPE-B_MEN     =  SPACE AND
     RSMPE-B_FUN     =  SPACE AND
     RSMPE-B_PFK     =  SPACE AND
     RSMPE-B_BUT     =  SPACE AND
     RSMPE-B_TITLE   =  SPACE AND
     RSMPE-B_STATEXT =  SPACE.
     MESSAGE E397.
  ENDIF.
ENDFORM.                    " CHECK_PRI_STATUS
