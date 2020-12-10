***INCLUDE LSEU0F09 .
form copy_frame using sname gname slangu glangu
                      g_trkey like trkey
                      p_active_to_inactive type sychar01
                      customer
                      tr_korr like e071-trkorr
                changing rcode type rcode.

  data: wa_obj_name like e071-obj_name,
        ieudb      like eudb      occurs 0 with header line,
        arsmptexts like rsmptexts occurs 0 with header line,
        irsmptexts like rsmptexts occurs 0 with header line,
        eudb_key like rseu1_key,
        l_ia_exists.

  call function 'RS_CUA_INTERNAL_VERSION_CHECK'
       exporting
            objectname = sname
       exceptions
            unknown_version = 4.
  if sy-subrc ne 0.
     rcode = con_rc_message.
     exit.
  endif.
*
  if slangu ne glangu.
     clear scr_return.
     call screen 113 starting at 15 7.
     check scr_return ne con_cancel.
  endif.
* Schmutzeinträge beim Ziel löschen
  delete from eudb where ( relid = scua_c_relid_active or
                           relid = scua_c_relid_inactive )
                   and   name  = gname
                   and   sprsl = scua_c_eudb_sprsl.
  delete from rsmptexts  where progname = gname.
  delete from rsmptextsi where progname = gname.

* Sourcen
  select * from eudb into table ieudb
                     where ( relid = scua_c_relid_active or
                             relid = scua_c_relid_inactive )
                     and   name  = sname
                     and   sprsl = scua_c_eudb_sprsl.
  loop at ieudb.
    clear: ieudb-vautor, ieudb-vdatum, ieudb-vzeit,
           ieudb-gdatum, ieudb-gzeit.
    if p_active_to_inactive = con_true and
       ieudb-relid = scua_c_relid_inactive.
       delete ieudb.
       continue.
    elseif p_active_to_inactive = con_false and
       ieudb-relid = scua_c_relid_inactive.
       l_ia_exists = con_true.
    elseif p_active_to_inactive = con_true.
       ieudb-relid  = scua_c_relid_inactive.
    endif.
    ieudb-name   = gname.
    ieudb-langu  = glangu.
    ieudb-autor  = sy-uname.
    ieudb-datum  = sy-datum.
    ieudb-zeit   = sy-uzeit.
    modify ieudb.
  endloop.
  insert eudb from table ieudb.
*
  if p_active_to_inactive = con_true.
     eudb_key-name  = gname.
     eudb_key-sprsl = scua_c_eudb_sprsl.
     export sy-uname to database eudb(cu) id eudb_key
                     from ieudb.
  endif.
* Texte
  select * from rsmptexts into table arsmptexts
           where progname = sname.
  loop at arsmptexts.
    arsmptexts-progname = gname.
    modify arsmptexts.
  endloop.

  if p_active_to_inactive = con_true.
*    Originaltexte inaktiv
*    Übersetzungen aktiv
     loop at arsmptexts where sprsl = glangu.
       append arsmptexts to irsmptexts.
       delete arsmptexts.
     endloop.
*    bei unterschiedlicher Sprache: auffüllen
     if slangu ne glangu.
        loop at arsmptexts where sprsl = slangu.
          read table irsmptexts
               with key progname = gname
               sprsl = glangu
               obj_type = arsmptexts-obj_type
               obj_code = arsmptexts-obj_code
               sub_code = arsmptexts-sub_code
               texttype = arsmptexts-texttype
               transporting no fields.
          if sy-subrc ne 0.
             arsmptexts-sprsl = glangu.
             append arsmptexts to irsmptexts.
          endif.
        endloop.
     endif.
*
     insert rsmptexts  from table arsmptexts.
     insert rsmptextsi from table irsmptexts.
  else.
*    Aktive Texte aktiv
*    Inaktive Texte inaktiv
     select * from rsmptextsi into table irsmptexts
              where progname = sname.
     loop at irsmptexts.
       irsmptexts-progname = gname.
       modify irsmptexts.
     endloop.
*    Bei unterschiedlicher Originalsprache: auffüllen
     if slangu ne glangu.
        loop at irsmptexts.
          read table arsmptexts
               with key progname = gname
               sprsl = glangu
               obj_type = irsmptexts-obj_type
               obj_code = irsmptexts-obj_code
               sub_code = irsmptexts-sub_code
               texttype = irsmptexts-texttype
               transporting no fields.
          if sy-subrc = 0.
             modify irsmptexts from arsmptexts.
          else.
             irsmptexts-sprsl = glangu.
             modify irsmptexts.
          endif.
        endloop.
     endif.
*
     insert rsmptexts  from table arsmptexts.
     insert rsmptextsi from table irsmptexts.
  endif.
* Indexupdate
  call function 'RS_CUA_INTERNAL_INDICES'
       exporting
            transportkey = g_trkey
            tcodeindex   = con_true
            treeupdate   = con_true
       exceptions
            others       = 0.
* Kundenerweiterung
  if customer ne space and p_active_to_inactive = con_true.
     perform modif_log_create using scua_c_state_inactive
                                    g_trkey glangu tr_korr.
  elseif customer ne space.
     perform modif_log_create using scua_c_state_active
                                    g_trkey glangu tr_korr.
     if l_ia_exists = con_true.
       perform modif_log_create using scua_c_state_inactive
                                      g_trkey glangu tr_korr.
     endif.
  endif.

* Eintrag in Arbeitsvorrat
  read table ieudb with key relid = scua_c_relid_inactive
                   transporting no fields.
  check sy-subrc = 0.
  wa_obj_name = gname.
  call function 'RS_INSERT_INTO_WORKING_AREA'
       exporting
            object   = 'CUAD'
            obj_name = wa_obj_name
       exceptions
            others   = 0.

endform.

form tree_upd using prog code operation kind.
  data: typ(3).

  case kind.
    when 'S'. typ = 'CPC'.
    when 'T'. typ = 'CPZ'.
    when 'M'. typ = 'CE'.
  endcase.
  call function 'RS_TREE_OBJECT_PLACEMENT'
       exporting
            object    = code
            operation = operation
            program   = prog
            type      = typ.
endform.
