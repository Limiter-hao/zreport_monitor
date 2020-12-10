***INCLUDE LSEU0F03 .
* Status löschen
form del_cua_status using name status tr_key.
  data: langu like sy-langu,
        linno type i,
        index like sy-tabix,
        first_line(70),
        second_line(70),
        l_state like progdir-state,
        l_tr_request type trkorr,
        answer.
  mkr_mp_source_tables s_.

  call function 'RS_CUA_INTERNAL_GET_READ_STATE'
       exporting
            p_program      = name
            p_mode         = scua_c_mode_modify
       importing
            p_get_state    = l_state.
  call function 'RS_CUA_INTERNAL_FETCH'
       exporting
            program   = name
            state     = l_state
       importing
            adm       = s_adm
            langu     = langu
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
  describe table s_sta lines linno.
  read table s_sta with key code = status binary search.
  index = sy-tabix.
  if sy-subrc = 0.
*    Beim letzen Status alles Löschen?
     if linno = 1.
        describe table s_tit lines linno.
        if linno = 0.
           first_line  = text-061.
           second_line = text-062.
           replace '&' with name into second_line.
           call function 'POPUP_TO_CONFIRM_STEP'
                exporting
                     defaultoption = 'N'
                     textline1 = first_line
                     textline2 = second_line
                     titel = text-063
                importing
                     answer = answer.
           case answer.
             when 'J'. perform del_cua using name tr_key
                                       changing l_tr_request.
                       exit.
            when 'A'. exit.
           endcase.
       endif.
     endif.
     delete s_sta index index.
     read table s_set with key status = status binary search.
     loop at s_set from sy-tabix.
       if s_set-status ne status. exit. endif.
       delete s_set.
     endloop.
*    Korrektureintrag
     call function 'RS_CORR_INSERT'
          exporting
               object       = name
               object_class = con_class_program
               mode         = 'MODIFY'
               extend       = con_true
          exceptions
               permission_failure = 01
               others             = 02.
     if sy-subrc ne 0.
        message id     sy-msgid
                type   'S'
                number sy-msgno
                with   sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        exit.
     endif.
*    Sichern
     call function 'RS_CUA_INTERNAL_GET_WRIT_STATE'
          exporting
               p_mode        = scua_c_mode_modify
          importing
               p_write_state = l_state.
     call function 'RS_CUA_INTERNAL_WRITE'
          exporting
               program   = name
               language  = langu
               tr_key    = tr_key
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
               others    = 2.
     if sy-subrc = 0.
        message s161 with status.
     else.
        message id sy-msgid type 'S' number sy-msgno
                with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 display like 'E'.
     endif.
  endif.
endform.

* Gesamtoberfläche löschen
form del_cua using name tr_key like trkey
             changing p_tr_request type korrnum.
  data: i_type,
        ind_name like trdir-name,
        wa_object   like e071-object,
        wa_obj_name like e071-obj_name.

* Korrektureintrag
  call function 'RS_CORR_INSERT'
       exporting
             object       = name
             object_class = con_class_program
             mode         = 'DELETE'
             extend       = con_true
             korrnum      = p_tr_request
       importing
             korrnum      = p_tr_request
       exceptions
             permission_failure = 01
             others             = 02.
  if sy-subrc ne 0.
    message id     sy-msgid
            type   'S'
            number sy-msgno
            with   sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    exit.
  endif.

* Löschen
  delete from eudb where ( relid = scua_c_relid_active or
                           relid = scua_c_relid_inactive )
                   and   name  = name.
* Texte löschen
  delete from rsmptexts  where progname = name.
  delete from rsmptextsi where progname = name.

  delete from cross where type    = 'Y'
                    and   include = ind_name.

* Laufzeitobjekt
  call 'DBCUADEL' id   'PROG' field name.
  case sy-subrc.
    when 1. message e050 with name raising failure_del_load.
    when 2. message e051 raising failure_del_load.
    when 3. message e052 raising failure_del_load.
  endcase.
* Title
  delete from d347t where progname = name.

* Kundenerweiterungen
  perform modif_log_delete using tr_key.
* Arbeitsvorrat
  wa_object   = tr_key-sub_type.
  wa_obj_name = tr_key-sub_name.
  call function 'RS_DELETE_FROM_WORKING_AREA'
       exporting
            object                 = wa_object
            obj_name               = wa_obj_name
            actualize_working_area = con_true
       exceptions
            others    = 0.

* Baumabgleich
  perform tree_upd using name space '*DELETE' 'S'.
  perform tree_upd using name space '*DELETE' 'T'.

* Exit-Funktionsaufruf
  if exit_func_name ne space.
     call function exit_func_name
          exporting program = name.
  endif.
endform.
