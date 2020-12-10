FUNCTION-POOL ZSEU0       MESSAGE-ID EC NO STANDARD PAGE HEADING
                         line-size 200.
  type-pools: smodi, scua, swbm.
  types: rcode(5).
  tables: rsmpe,
          trdir,
          tadir,
          eudb,
          rsmptexts,
          tstc,
          tstct,
          smodilog.                     " Kundenerweiterung

* include mseuxcom.                     " Tabellen und Key der EUDB
  include rsmpsmkr.
  mkr_mp_source_tables new_.
  mkr_mp_source_tables cli_.
  mkr_mp_mod_tables mod_.

  data: exit_func_name like tfdir-funcname.       " FB beim Sichern
  data: navigation_memo(10) value '**MP_MEMO',
        memory_id like rsmp_navi-memo_id,
        modification_language like sy-langu.

  data: ok_code like sy-ucomm,
        xcode   like sy-ucomm,
        scr_return type rcode,
        cursorfield like dynpread-fieldname.
  data: cua_active,                     " U = Ändern, D = Anzeigen
        inttype.

  data: pri_langu,
        pri_internal.

* Protokoll für Übersetzung (RS_ACCESS_PERMISSION --> RS_TEXTLOG_CHNAGE)
  data: transport_key type trkey,
        s_transport_key type trkey,
        tr_corr like e071-trkorr.
  data: source_operation like smodilog-operation,
        source_customer,
        target_customer.

* allgemeine Konstanten
  include rsmpecon.

* Returncodes
  constants: con_cancel    type rcode value 'CANC',
             con_rc_all    type rcode value 'ALL',
             con_continue  type rcode value 'CONT',
             con_rc_message type rcode value 'MESS'.
* Konstante
  constants: language_exit_function like tfdir-funcname
                                    value 'RS_PROG_CHANGE_LANGUAGE_UPD'.
* Kundenwerweiterung
  constants: con_modif_delete like smodilog-operation value 'DELE'.

* Makros
  define mkr_textlog_append.
    clear textlog.
    textlog-priority  = &1.
    textlog-text_type = &2.
    textlog-operation = &3.
    textlog-text_id   = &4.
    append textlog.
  end-of-definition.
