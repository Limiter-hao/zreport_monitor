自开发程序监控报表

ABAP版本：740或更高

设计目标
可以监控自开发程序的使用频率以及使用事件，而且提供了运行时的选择屏幕存储，可通过日志程序直接调用该程序

包含对象

ZTABAP_REP_MON（日志存储表）

Zrepmor_config(监控配置表)

Zcl_report_monitor(监控类)

zgit_monitor(监控报表)

用法

1：在代码中按照以下方法即可启用日志功能，如需关闭，请在配置表中对改程序的监控功能给与关闭
  
  
2：声明alv的监控类

    DATA(gcl_monitor) = NEW zcl_report_monitor( sy-repid ).
    
    PARAMETERS p_debug TYPE abap_bool NO-DISPLAY. 
    
    
    
3：在start-of-selection事件中调用一下方法开始记录

    gcl_monitor->start( p_debug ).
    
    
    
4：在调用alv显示之前，开发习惯不同，请选择合适的位置，使用以下代码

    gcl_monitor->end( ).
    

5.由于zgit_monitor程序在展示选择条件的时候使用了Falv，因此，你需要导入一下falv项目


https://github.com/fidley/falv

当然你也可以修改此处，改为你喜欢的alv展示方式


6：感谢不知名开发者的代码（未找到原作者），让我有了灵感
