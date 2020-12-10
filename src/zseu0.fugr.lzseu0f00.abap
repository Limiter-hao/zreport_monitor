***INCLUDE LSEU0F00 .
form get_master_language_trkey using trkey structure trkey
                                     m_langu.
  select single * from  tadir
                  where  pgmid       = 'R3TR'
                  and    object      = trkey-obj_type
                  and    obj_name    = trkey-obj_name.
  if sy-subrc = 0 and tadir-masterlang ne space.
         m_langu = tadir-masterlang.
  else.  m_langu = 'D'.
  endif.
endform.                    " GET_MASTER_LANGUAGE

form ok_code_copy.
  data: xcode like sy-ucomm,
        s_langu like sy-langu,
        t_langu like sy-langu,
        l_tr_request type korrnum,
        rcode type rcode.

  xcode = ok_code.
  clear ok_code.
  case xcode.
    when 'NEXT'.
      perform get_master_language_trkey using s_transport_key s_langu.
      perform get_master_language_trkey using   transport_key t_langu.
      case sy-dynnr.
        when 111.
          perform copy_frame using rsmpe-program rsmpe-cp_program
                                   s_langu t_langu
                                   transport_key con_true
                                   target_customer
                                   tr_corr
                             changing rcode.
          if rcode = con_rc_message.
             message id     sy-msgid
                     type   'E'
                     number sy-msgno
                     with   sy-msgv1 sy-msgv2
                            sy-msgv3 sy-msgv2.
          endif.
        when 112.
          perform copy_frame using rsmpe-program rsmpe-cp_program
                                   s_langu t_langu
                                   transport_key con_false
                                   target_customer
                                   tr_corr
                             changing rcode.
          if rcode = con_rc_message.
             message id     sy-msgid
                     type   'E'
                     number sy-msgno
                     with   sy-msgv1 sy-msgv2
                            sy-msgv3 sy-msgv2.
          endif.
          perform del_cua using rsmpe-program s_transport_key
                          changing l_tr_request.
          call function 'RS_ACCESS_PERMISSION'
               exporting
                    mode         = 'FREE'
                    object       = rsmpe-program
                    object_class = con_class_program.
      endcase.
      call function 'RS_ACCESS_PERMISSION'
           exporting
                mode         = 'FREE'
                object       = rsmpe-cp_program
                object_class = con_class_program.
      set screen 0. leave screen.
  endcase.
endform.

form modif_log_delete using transportkey structure trkey.
  delete from smodilog where obj_type = transportkey-obj_type
                       and   obj_name = transportkey-obj_name
                       and   sub_type = transportkey-sub_type
                       and   sub_name = transportkey-sub_name
                       and   ( operation = con_cus_modify or
                                operation = con_cus_insert ).
  delete from smodisrc where obj_type = transportkey-obj_type
                       and   obj_name = transportkey-obj_name
                       and   sub_type = transportkey-sub_type
                       and   sub_name = transportkey-sub_name.
  delete from smodilogi where obj_type = transportkey-obj_type
                        and   obj_name = transportkey-obj_name
                        and   sub_type = transportkey-sub_type
                        and   sub_name = transportkey-sub_name
                        and   ( operation = con_cus_modify or
                                operation = con_cus_insert ).
  delete from smodisrci where obj_type = transportkey-obj_type
                        and   obj_name = transportkey-obj_name
                        and   sub_type = transportkey-sub_type
                        and   sub_name = transportkey-sub_name.
endform.

form modif_log_create using p_state    type c
                            p_trkey    structure trkey
                            p_language like sy-langu
                            p_trkorr   like e071-trkorr.
  data: l_program type program.

  l_program = p_trkey-sub_name.
  call function 'RS_CUA_INTERNAL_MOD_FETCH'
    exporting
      transportkey                 = p_trkey
      suppress_source_select       = con_false
      state                        = p_state
    importing
      mod_object                   = mod_logobj
      adm                          = cli_adm
    tables
      sta                   = cli_sta
      fun                   = cli_fun
      men                   = cli_men
      mtx                   = cli_mtx
      act                   = cli_act
      but                   = cli_but
      pfk                   = cli_pfk
      set                   = cli_set
      doc                   = cli_doc
      tit                   = cli_tit
      biv                   = cli_biv
      mod_head              = mod_head
      mod_menus             = mod_menus
    exceptions
      others                       = 4.
  if sy-subrc <> 0.
     message id sy-msgid type 'S' number sy-msgno
             with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
     exit.
  endif.
*
  clear: mod_head[], mod_menus[].
  perform modif_log_create_details.
*
  call function 'RS_CUA_INTERNAL_MOD_WRITE'
    exporting
      transportkey             = p_trkey
      mod_langu                = p_language
      adm                      = cli_adm
      customer_operation       = con_cus_insert
      mod_namespace            = space
      TRKORR                   = p_trkorr
      STATE                    = p_state
      mod_object               = mod_logobj
    tables
      sta                   = cli_sta
      fun                   = cli_fun
      men                   = cli_men
      mtx                   = cli_mtx
      act                   = cli_act
      but                   = cli_but
      pfk                   = cli_pfk
      set                   = cli_set
      doc                   = cli_doc
      tit                   = cli_tit
      biv                   = cli_biv
      mod_head              = mod_head
      mod_menus             = mod_menus
    EXCEPTIONS
      OTHERS                   = 0.
endform.

form modif_log_create_details.
  data: code like mod_head-obj_name,
        sub_code like mod_head-sub_name.
  loop at cli_act.
    if code ne cli_act-code.
       perform modification_log_object using con_cus_abar cli_act-code
                                             space.
       code = cli_act-code.
    endif.
  endloop.
  clear code.
*
  loop at cli_sta.
    perform modification_log_object using con_cus_status cli_sta-code
                                          space.
  endloop.
*
  loop at cli_men.
    if cli_men-code ne code.
       perform modification_log_object using con_cus_menu cli_men-code
                                             space.
       code = cli_men-code.
    endif.
  endloop.
  clear code.
*
  loop at cli_pfk.
    if cli_pfk-code ne code.
       perform modification_log_object using con_cus_fkey cli_pfk-code
                                             space.
       code = cli_pfk-code.
    endif.
  endloop.
  clear code.
*
  loop at cli_but.
    if cli_but-pfk_code ne code or cli_but-code ne sub_code.
      perform modification_log_object using con_cus_pbut
                                            cli_but-pfk_code
                                            cli_but-code.
      code = cli_but-pfk_code.
      sub_code = cli_but-code.
    endif.
  endloop.
  clear: code, sub_code.
*
  loop at cli_fun.
    if cli_fun-code ne code.
      perform modification_log_object using con_cus_fcode cli_fun-code
                                            space.
      code = cli_fun-code.
    endif.
    perform modification_log_object using con_cus_ftext cli_fun-code
                                          cli_fun-textno.
  endloop.
  clear: code.
*
  loop at cli_tit.
    perform modification_log_object using con_cus_title cli_tit-code
                                          space.
  endloop.
endform.

form modification_log_object using obj_type  like smodilog-sub_type
                                   code1     type c
                                   code2     type c.
  mod_head-obj_type  = obj_type.
  mod_head-obj_name  = code1.
  mod_head-sub_name  = code2.
  mod_head-operation = con_cus_insert.
  mod_head-user      = sy-uname.
  mod_head-date      = sy-datum.
  mod_head-time      = sy-uzeit.
  append mod_head.
endform.

form modif_check_object using transportkey structure trkey
                        changing operation like smodilog-operation.
  select * from smodilog up to 1 rows
                         where obj_type = transportkey-obj_type
                         and   obj_name = transportkey-obj_name
                         and   sub_type = transportkey-sub_type
                         and   sub_name = transportkey-sub_name
                         and   ( operation = con_cus_insert or
                                 operation = con_cus_modify ).
  endselect.
  if sy-subrc = 0. operation = smodilog-operation.
  else.            operation = space.
  endif.
endform.

form wm_init_manager using p_navigation type rsmp_navi.
  data: l_object          type seu_objkey,
        l_operation       type seu_action,
        l_obj_type        type seu_objtyp,
        l_wb_request      type ref to cl_wb_request,
        l_wb_request_set  type swbm_wb_request_set,
        l_wb_obj_state    type ref to cl_wb_cua_state,
        l_wb_startup      type ref to cl_wb_startup.

* *if p_monitor_activate = con_true.
    create object l_wb_startup.
* *endif.
*
  create object l_wb_obj_state.
*
  l_object = p_navigation-program.
*
  case p_navigation-mode.
  when 'I'.     l_operation = swbm_c_op_create.
  when 'M'.     l_operation = swbm_c_op_edit.
  when 'D'.     l_operation = swbm_c_op_display.
  when others.  l_operation = swbm_c_op_display.
  endcase.

  case p_navigation-type.
    when space.
      l_obj_type = swbm_c_type_cua_status.
      call method cl_wb_object_type=>get_concatenated_key_from_id
                  exporting p_key_component1 = p_navigation-program
                            p_key_component2 = p_navigation-status
                            p_external_id    = l_obj_type
                  receiving  p_key = l_object.
    when 'TEXT_STA'. l_obj_type = swbm_c_type_cua_status.
                     l_wb_obj_state->overview = con_true.
    when 'TEXT_ACT'. l_obj_type = swbm_c_type_cua_menubar.
                     l_wb_obj_state->overview = con_true.
    when 'TEXT_ATS'.
      l_obj_type = swbm_c_type_cua_menubar.
      call method cl_wb_object_type=>get_concatenated_key_from_id
                  exporting p_key_component1 = p_navigation-program
                            p_key_component2 = p_navigation-obj_name
                            p_external_id    = l_obj_type
                  receiving  p_key = l_object.
    when 'TEXT_MEN'. l_obj_type = swbm_c_type_cua_menu.
                     l_wb_obj_state->overview = con_true.
    when 'TEXT_MNS'.
      l_obj_type = swbm_c_type_cua_menu.
      call method cl_wb_object_type=>get_concatenated_key_from_id
                  exporting p_key_component1 = p_navigation-program
                            p_key_component2 = p_navigation-obj_name
                            p_external_id    = l_obj_type
                  receiving  p_key = l_object.
    when 'TEXT_PFK'. l_obj_type = swbm_c_type_cua_funcassignmnt.
                     l_wb_obj_state->overview = con_true.
    when 'TEXT_PFS'.
      l_obj_type = swbm_c_type_cua_funcassignmnt.
      call method cl_wb_object_type=>get_concatenated_key_from_id
                  exporting p_key_component1 = p_navigation-program
                            p_key_component2 = p_navigation-obj_name
                            p_external_id    = l_obj_type
                  receiving  p_key = l_object.
     when 'TEXT_FUN'.
      l_obj_type = swbm_c_type_cua_function.
      call method cl_wb_object_type=>get_concatenated_key_from_id
                  exporting p_key_component1 = p_navigation-program
                            p_key_component2 = p_navigation-obj_name
                            p_external_id    = l_obj_type
                  receiving  p_key = l_object.
      l_wb_obj_state->overview = con_true.
    when 'TITLE'.
      l_obj_type = swbm_c_type_cua_title.
      if p_navigation-kind = 'P'.
         l_wb_obj_state->overview = con_true.
      elseif p_navigation-kind = '1'.
         call method cl_wb_object_type=>get_concatenated_key_from_id
                     exporting p_key_component1 = p_navigation-program
                               p_key_component2 = p_navigation-obj_name
                               p_external_id    = l_obj_type
                     receiving  p_key = l_object.
      endif.
*
    when 'OBJ_TREE'.
      l_obj_type = swbm_c_type_cua_tree.
      if p_navigation-kind = 'O'.
         l_wb_obj_state->original = con_true.
      endif.
*
    when 'VERSION'.
      l_obj_type = swbm_c_type_cua_tree.
      l_wb_obj_state->version = p_navigation-versno.
      l_wb_obj_state->is_version = con_true.
      call method cl_wb_object_type=>get_concatenated_key_from_id
                  exporting p_key_component1 = p_navigation-program
                            p_key_component2 = space
                            p_external_id    = l_obj_type
                  receiving  p_key = l_object.
    when 'INT_VERS'.
      l_obj_type = swbm_c_type_cua_tree.
      l_wb_obj_state->int_vers = con_true.
      call method cl_wb_object_type=>get_concatenated_key_from_id
                  exporting p_key_component1 = p_navigation-program
                            p_key_component2 = space
                            p_external_id    = l_obj_type
                  receiving  p_key = l_object.
*
    when '*REF_LIST*'.
      l_operation = swbm_c_op_where_used_list.
      case p_navigation-ref_type.
        when con_inttype_function.
          l_obj_type = swbm_c_type_cua_function.
        when con_inttype_menu.
          l_obj_type = swbm_c_type_cua_menu.
        when  con_inttype_fkeyset.
          l_obj_type = swbm_c_type_cua_funcassignmnt.
      endcase.
      call method cl_wb_object_type=>get_concatenated_key_from_id
                  exporting p_key_component1 = p_navigation-program
                            p_key_component2 = p_navigation-obj_name
                            p_external_id    = l_obj_type
                  receiving  p_key = l_object.
*
    when '*CHECK*'.
      l_operation = swbm_c_op_check.
      l_obj_type  = swbm_c_type_cua.
      l_wb_obj_state->checktype = p_navigation-obj_name.
*
    when '*SIMULATE*'.
      l_operation = swbm_c_op_execute.
      l_obj_type  = swbm_c_type_cua_status.
      call method cl_wb_object_type=>get_concatenated_key_from_id
                  exporting p_key_component1 = p_navigation-program
                            p_key_component2 = p_navigation-status
                            p_external_id    = l_obj_type
                  receiving  p_key = l_object.
    when 'INIT'.
      if p_navigation-kind = 'S'.
         l_operation = swbm_c_op_find.
         l_obj_type  = swbm_c_type_cua.
         l_object    = p_navigation-program.
      endif.
*
  endcase.
*
  create object l_wb_request
         exporting
           p_object_type   = l_obj_type
           p_object_name   = l_object
           p_operation     = l_operation
           p_object_state  = l_wb_obj_state.
  append l_wb_request to l_wb_request_set.

  call method l_wb_startup->start
    exporting
      p_wb_request_set = l_wb_request_set
    exceptions
      manager_not_yet_released = 0.
endform.                    " WM_INIT_MANAGER
