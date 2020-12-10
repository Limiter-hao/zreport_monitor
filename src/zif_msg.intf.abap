interface ZIF_MSG
  public .


  data HANDLE_MSG type C .

  events DISPLAY_MSG
    exporting
      value(TYPE) type BAPI_MTYPE optional
      value(MSG) type BAPI_MSG optional .
endinterface.
