*----------------------------------------------------------------------*
*   INCLUDE LSEU0F30                                                   *
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  CHECK_COPY_TITLE
*&---------------------------------------------------------------------*
form check_copy_title.
  data: customer,
        exists.

  select single * from trdir where name = rsmpe-program.
  if sy-subrc ne 0.
     message e303 with rsmpe-program raising program_not_found.
  endif.
*
* Quelle
  call function 'RS_CUA_INTERNAL_TITLE_CHECK'
       exporting
            program      = rsmpe-program                  "#EC DOM_EQUAL
            titcode      = rsmpe-titcode
       importing
            title_exists = exists
       exceptions
            unknown_version = 2
            others          = 1.
  if sy-subrc = 2.
     message id     sy-msgid
             type   'E'
             number sy-msgno
             with   sy-msgv1 sy-msgv2
                    sy-msgv3 sy-msgv2.
  endif.
  if exists = con_false. message e329 with rsmpe-titcode. endif.
* Ziel
  call function 'RS_CUA_INTERNAL_TITLE_CHECK'
       exporting
            program      = rsmpe-program                  "#EC DOM_EQUAL
            titcode      = rsmpe-cp_titcode
       importing
            title_exists = exists
       exceptions
            unknown_version = 2
            others          = 1.
  if sy-subrc = 2.
     message id     sy-msgid
             type   'E'
             number sy-msgno
             with   sy-msgv1 sy-msgv2
                    sy-msgv3 sy-msgv2.
  endif.
  if exists = con_true.
     message e310 with rsmpe-cp_titcode rsmpe-program.
  endif.
* Berechtigung
  call function 'RS_ACCESS_PERMISSION'
       exporting
            authority_check         = con_true
            mode                    = 'MODIFY'
            object                  = rsmpe-program
            object_class            = con_class_program
            suppress_language_check = con_false
            suppress_extend_dialog  = con_false
       importing
            transport_key         = transport_key
            modification_language = modification_language
            extend                = customer
       exceptions
            others          = 04.
  if sy-subrc ne 0.
     message id     sy-msgid
             type   'E'
             number sy-msgno
             with   sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
             raising permission_failure.
  endif.
  if customer ne space.
     message s349.
     call function 'RS_ACCESS_PERMISSION'
          exporting
               mode         = 'FREE'
               object       = rsmpe-program
               object_class = con_class_program.
    scr_return = con_rc_all.
    set screen 0. leave screen.
  endif.
endform.                    " CHECK_COPY_TITLE
*&---------------------------------------------------------------------*
*&      Form  COPY_TITLE
*&---------------------------------------------------------------------*
form copy_title_new.
  data: l_state like progdir-state.
  mkr_mp_source_tables s_.

  call function 'RS_CORR_INSERT'
       exporting
            object       = rsmpe-program
            object_class = con_class_program
            mode         = 'MODIFY'
            extend       = con_true
       exceptions
            permission_failure = 01
            others             = 02.
  if sy-subrc ne 0.
     message id     sy-msgid
             type   'E'
             number sy-msgno
             with   sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.
*
  call function 'RS_CUA_INTERNAL_GET_READ_STATE'
       exporting
            p_program      = rsmpe-program
            p_mode         = scua_c_mode_modify
       importing
            p_get_state    = l_state.
  call function 'RS_CUA_INTERNAL_FETCH'
       exporting
            program   = rsmpe-program                     "#EC DOM_EQUAL
            language  = modification_language
            state     = l_state
       importing
            adm       = s_adm
       tables
            sta       = s_sta
            fun       = s_fun
            men       = s_men
            mtx       = s_mtx
            act       = s_act
            but       = s_but
            pfk       = s_pfk
            set       = s_set
            doc       = s_doc
            tit       = s_tit
            biv       = s_biv
       exceptions
            not_found = 1
            others    = 2.
  check sy-subrc = 0.
  read table s_tit with key code = rsmpe-titcode.
  check sy-subrc = 0.
  s_tit-code = rsmpe-cp_titcode.
  read table s_tit with key code = rsmpe-cp_titcode
                   binary search transporting no fields.
  if sy-subrc ne 0. insert s_tit index sy-tabix.
  else.             modify s_tit index sy-tabix.
  endif.
*
  call function 'RS_CUA_INTERNAL_GET_WRIT_STATE'
       exporting
            p_mode        = scua_c_mode_modify
       importing
            p_write_state = l_state.
  call function 'RS_CUA_INTERNAL_WRITE'
       exporting
            program   = rsmpe-program                     "#EC DOM_EQUAL
            language  = modification_language
            tr_key    = transport_key
            adm       = s_adm
            state     = l_state
       tables
            sta       = s_sta
            fun       = s_fun
            men       = s_men
            mtx       = s_mtx
            act       = s_act
            but       = s_but
            pfk       = s_pfk
            set       = s_set
            doc       = s_doc
            tit       = s_tit
            biv       = s_biv
       exceptions
            others    = 0.
endform.                    " COPY_TITLE

form rename_title.
  data: language like sy-langu,
        l_state  like progdir-state.
  mkr_mp_source_tables s_.

  call function 'RS_CORR_INSERT'
       exporting
            object       = rsmpe-program
            object_class = con_class_program
            mode         = 'MODIFY'
            extend       = con_true
       exceptions
            permission_failure = 01
            others             = 02.
  if sy-subrc ne 0.
     message id     sy-msgid
             type   'E'
             number sy-msgno
             with   sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.
*
  call function 'RS_CUA_INTERNAL_GET_READ_STATE'
       exporting
            p_program      = rsmpe-program
            p_mode         = scua_c_mode_modify
       importing
            p_get_state    = l_state.
  call function 'RS_CUA_INTERNAL_FETCH'
       exporting
            program   = rsmpe-program                     "#EC DOM_EQUAL
            state     = l_state
       importing
            adm       = s_adm
            langu     = language
       tables
            sta       = s_sta
            fun       = s_fun
            men       = s_men
            mtx       = s_mtx
            act       = s_act
            but       = s_but
            pfk       = s_pfk
            set       = s_set
            doc       = s_doc
            tit       = s_tit
            biv       = s_biv
       exceptions
            not_found = 1
            others    = 2.
  check sy-subrc = 0.
  read table s_tit with key code = rsmpe-titcode.
  check sy-subrc = 0.
  s_tit-code = rsmpe-cp_titcode.
  modify s_tit index sy-tabix.
  sort s_tit by code.
*
  call function 'RS_CUA_INTERNAL_GET_WRIT_STATE'
       exporting
            p_mode        = scua_c_mode_modify
       importing
            p_write_state = l_state.
  call function 'RS_CUA_INTERNAL_WRITE'
       exporting
            program   = rsmpe-program                     "#EC DOM_EQUAL
            language  = language
            tr_key    = transport_key
            adm       = s_adm
            state     = l_state
       tables
            sta       = s_sta
            fun       = s_fun
            men       = s_men
            mtx       = s_mtx
            act       = s_act
            but       = s_but
            pfk       = s_pfk
            set       = s_set
            doc       = s_doc
            tit       = s_tit
            biv       = s_biv
       exceptions
            others    = 0.
endform.
*&---------------------------------------------------------------------*
*&      Form  VALR_REQ_TIT
*&---------------------------------------------------------------------*
form valr_req_tit.
  data: dyfields like dynpread occurs 1 with header line,
        pname    like trdir-name,
        tit_code like rsmpe-titcode.

  dyfields-fieldname = 'RSMPE-PROGRAM'.
  append dyfields.
  dyfields-fieldname = 'RSMPE-TITCODE'.
  append dyfields.

  call function 'DYNP_VALUES_READ'
       exporting
            dyname     = 'SAPLSEU0'
            dynumb     = sy-dynnr
       tables
            dynpfields = dyfields
       exceptions
            others     = 01.
  if sy-subrc ne 0. message s143. exit. endif.

  read table dyfields index 1.
  if dyfields-fieldvalue = space. message s149. exit. endif.
  pname = dyfields-fieldvalue.
  read table dyfields index 1.
  tit_code = dyfields-fieldvalue.

  call function 'F4_PROG_TITLE'
       exporting
            object             = tit_code
            program            = pname
            suppress_selection = 'X'
       importing
            result             = tit_code
            program            = pname
       exceptions
            others             = 1.
  check sy-subrc = 0.

  read table dyfields index 2.
  dyfields-fieldvalue = tit_code.
  modify dyfields index 2.

  call function 'DYNP_VALUES_UPDATE'
       exporting
            dyname     = 'SAPLSEU0'
            dynumb     = sy-dynnr
       tables
            dynpfields = dyfields
       exceptions
            others     = 0.

endform.                    " VALR_REQ_TIT
