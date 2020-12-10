***INCLUDE LSEU0I01 .
module back.
  case ok_code.
    when 'EBRK'. clear ok_code.
                 scr_return = con_cancel.
                 set screen 0. leave screen.
  endcase.
endmodule.

module continue.
  if     ok_code = 'EBRK'. scr_return = con_cancel.
  elseif ok_code = 'NEXT'. clear scr_return.
  endif.
  clear ok_code.
  set screen 0. leave screen.
endmodule.

module ok_code_add.

  xcode = ok_code.
  clear: ok_code, scr_return.
  case xcode.
    when 'BACK'. scr_return = con_cancel.
                 set screen 0. leave screen.
    when 'NEXT'.
      call function 'RS_CUA_INTERNAL_NAME_CHECK'
           exporting
                name                 = rsmpe-status   "#EC DOM_EQUAL
                name_type            = inttype
           exceptions
                excluded_characters  = 1
                name_space_violation = 2
                others               = 3.
      if sy-subrc ne 0.
        message id     sy-msgid
                type   sy-msgty
                number sy-msgno
                with   sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      endif.
      set screen 0. leave screen.
  endcase.
endmodule.

* Oberfläche kopieren
module check_copy_frame.
* Zielprogramm vorhanden / Programmtyp Prüfung
  select single * from trdir where name = rsmpe-cp_program.
  if sy-subrc ne 0. message e303 with rsmpe-cp_program. endif.
  if trdir-subc na '1MF'.
     message e433 with rsmpe-cp_program trdir-subc.
  endif.
* Quelle vorhanden ?
  select single * from trdir where name = rsmpe-program.
  if sy-subrc ne 0. message e303 with rsmpe-program. endif.
  select single * from eudb where relid = 'CU'
                     and   name  = rsmpe-program
                     and   sprsl = 'D'
                     and   srtf2 = 0.
  if sy-subrc ne 0.
     message e408 with rsmpe-program.
  endif.
* Ziel nicht vorhanden ?
  select single * from eudb where relid = 'CU'
                       and   name  = rsmpe-cp_program
                       and   sprsl = 'D'
                       and   srtf2 = 0.
  if sy-subrc = 0.
     message e434 with rsmpe-cp_program.
  endif.
endmodule.

module auth_copy_frame.
* Berechtigung und Sperren
* CUA-Sperre: Ziel
  call function 'RS_ACCESS_PERMISSION'
       exporting
            authority_check         = con_true
            mode                    = 'MODIFY'
            object                  = rsmpe-cp_program
            object_class            = con_class_program
            language_upd_exit       = language_exit_function
            suppress_language_check = con_true
            suppress_extend_dialog  = space
       importing
            transport_key   = transport_key
            extend          = target_customer
       exceptions
            others          = 04.
  if sy-subrc ne 0.
     message id     sy-msgid
             type   sy-msgty
             number sy-msgno
             with   sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.
* Anzeigeberechtigung Quelle
  call function 'RS_ACCESS_PERMISSION'
       exporting
            authority_check         = con_true
            mode                    = 'SHOW'
            object                  = rsmpe-program
            object_class            = con_class_program
            language_upd_exit       = language_exit_function
            suppress_language_check = con_true
            suppress_extend_dialog  = space
       importing
            transport_key   = s_transport_key
       exceptions
            others          = 04.
  if sy-subrc ne 0.
     message id     sy-msgid
             type   'E'
             number sy-msgno
             with   sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.
* Korrektureintrag
  call function 'RS_CORR_INSERT'
       exporting
            object       = rsmpe-cp_program
            object_class = con_class_program
            mode         = 'MODIFY'
            extend       = con_true
       importing
            ordernum     = tr_corr
       exceptions
            permission_failure = 01
            others             = 02.
  if sy-subrc ne 0.
     message id     sy-msgid
             type   'E'
             number sy-msgno
             with   sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.
endmodule.

module auth_rename_frame.
* Berechtigung und Sperren
* CUA-Sperre: Ziel
  call function 'RS_ACCESS_PERMISSION'
       exporting
            authority_check         = con_true
            mode                    = 'MODIFY'
            object                  = rsmpe-cp_program
            object_class            = con_class_program
            language_upd_exit       = language_exit_function
            suppress_language_check = con_true
            suppress_extend_dialog  = space
       importing
            transport_key   = transport_key
            extend          = target_customer
       exceptions
            others          = 04.
  if sy-subrc ne 0.
     message id     sy-msgid
             type   sy-msgty
             number sy-msgno
             with   sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.
* CUA-Sperre Quelle
  call function 'RS_ACCESS_PERMISSION'         " ENQ CUA Quelle
       exporting
            authority_check         = con_true
            mode                    = 'MODIFY'
            object                  = rsmpe-program
            object_class            = con_class_program
            suppress_language_check = con_true
            suppress_extend_dialog  = space
       importing
            transport_key   = s_transport_key
            extend          = source_customer
       exceptions
            others          = 04.
  if sy-subrc ne 0.
     call function 'RS_ACCESS_PERMISSION'       " dequeue CUA(Ziel)
          exporting
               mode         = 'FREE'
               object       = rsmpe-cp_program
               object_class = con_class_program.
     message id     sy-msgid
             type   sy-msgty
             number sy-msgno
             with   sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.
* Korrektureintrag Ziel
  call function 'RS_CORR_INSERT'
       exporting
            object       = rsmpe-cp_program
            object_class = con_class_program
            mode         = 'MODIFY'
            extend       = con_true
       importing
            ordernum     = tr_corr
       exceptions
            permission_failure = 01
            others             = 02.
  if sy-subrc ne 0.
     call function 'RS_ACCESS_PERMISSION'       " dequeue CUA(Ziel)
          exporting
               mode         = 'FREE'
               object       = rsmpe-program
               object_class = con_class_program.
     call function 'RS_ACCESS_PERMISSION'       " dequeue CUA(Ziel)
          exporting
               mode         = 'FREE'
               object       = rsmpe-cp_program
               object_class = con_class_program.
     message id     sy-msgid
             type   'E'
             number sy-msgno
             with   sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.
* Korrektureintrag  (Quelle)
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
     call function 'RS_ACCESS_PERMISSION'       " dequeue CUA(Ziel)
          exporting
               mode         = 'FREE'
               object       = rsmpe-program
               object_class = con_class_program.
     call function 'RS_ACCESS_PERMISSION'       " dequeue CUA(Ziel)
          exporting
               mode         = 'FREE'
               object       = rsmpe-cp_program
               object_class = con_class_program.
     message id     sy-msgid
             type   'E'
             number sy-msgno
             with   sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.
  if source_customer ne space.
     perform modif_check_object using s_transport_key
                                changing source_operation.
     if source_operation = con_cus_modify.
        message e350.
     elseif source_operation = con_cus_insert.
        source_operation = con_modif_delete.
     endif.
   endif.
endmodule.

* Kopieren
module ok_code_copy.
  perform ok_code_copy.
endmodule.

* Oberfläche kopieren
* Drucken
module ok_code_190.
  clear ok_code.
  set screen 0. leave screen.
endmodule.

module sta_list.
  call function 'REPOSITORY_INFO_SYSTEM_F4'
       exporting
            object_type               = 'PROG_STATUS'
            object_name               = rsmpe-status
            enclosing_object          = rsmpe-program
            suppress_selection        = 'X'
       importing
            object_name_selected      = rsmpe-status
       exceptions
            others                    = 0.
  leave screen.
endmodule.

*&---------------------------------------------------------------------*
*&      Module  CHECK_STATUS  INPUT
*&---------------------------------------------------------------------*
module check_print_params.
  perform check_print_input.
endmodule.                 " CHECK_STATUS  INPUT

*&---------------------------------------------------------------------*
*&      Module  VAL_REQ_PROG  INPUT
*&---------------------------------------------------------------------*
module val_req_prog input.
  get cursor field cursorfield.
  call function 'RS_HELP_HANDLING'
       exporting
            dynpfield                 = cursorfield
            dynpname                  = sy-dynnr
            object                    = 'PR  '
            progname                  = 'SAPLSEU0'
            suppress_selection_screen = 'X'.
endmodule.                 " VAL_REQ_PROG  INPUT
*&---------------------------------------------------------------------*
*&      Module  VAL_REQ_SAPM  INPUT
*&---------------------------------------------------------------------*
module val_req_tit input.
  perform valr_req_tit.
endmodule.                 " VAL_REQ_SAPM  INPUT
*&---------------------------------------------------------------------*
*&      Module  CHECK_COPY_TIT  INPUT
*&---------------------------------------------------------------------*
module check_copy_tit input.
  perform check_copy_title.
  perform copy_title_new.
  call function 'RS_ACCESS_PERMISSION'
       exporting
            mode         = 'FREE'
            object       = rsmpe-program
            object_class = con_class_program.
  message s135 with rsmpe-titcode rsmpe-program rsmpe-cp_titcode.
  set screen 0. leave screen.
endmodule.                 " CHECK_COPY_TIT  INPUT
*&---------------------------------------------------------------------*
*&      Module  CHECK_RENAME_TIT  INPUT
*&---------------------------------------------------------------------*
module check_rename_tit input.
  perform check_copy_title.
  perform rename_title.
  call function 'RS_ACCESS_PERMISSION'
       exporting
            mode         = 'FREE'
            object       = rsmpe-program
            object_class = con_class_program.
  message s138 with rsmpe-titcode rsmpe-program rsmpe-cp_titcode.
  set screen 0. leave screen.
endmodule.                 " CHECK_RENAME_TIT  INPUT

module check_program input.
  if rsmpe-program na '*+'.
     select single * from trdir where name = rsmpe-program.
     if sy-subrc ne 0.
        message e264 with rsmpe-program.
     endif.
  endif.
endmodule.                 " CHECK_PROGRAM  INPUT

module ok_code_search input.
  clear scr_return.
  set screen 0. leave screen.
endmodule.                 " OK_CODE_SEARCH  INPUT
