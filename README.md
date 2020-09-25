Self-developed program monitoring report

ABAP version: 740 or higher

Design goals Can monitor the frequency of use and usage events of self-developed programs, 

and provide a selection screen storage at runtime, which can be directly called through the log program

Contains objects


Ztabap_rep_mon (Log storage table)


Zrepmor_config (monitoring configuration table)


Zcl_report_monitor (monitoring class)


zgit_monitor (monitoring report)


usage


1: In the code, you can enable the log function according to the following method. If you need to turn it off, please turn off the monitoring function of the changed program in the configuration table




2: Declare the monitoring class


DATA(gcl_monitor) = NEW zcl_report_monitor( sy-repid ).


PARAMETERS p_debug TYPE abap_bool NO-DISPLAY.





3: Call the method in the start-of-selection event to start recording


gcl_monitor->start( p_debug ).



4: Before calling the alv display, the development habits are different, please select a suitable location and use the following code


gcl_monitor->end( ).




5. Since the zgit_monitor program uses Falv when displaying the selection conditions, you need to import the falv project


https://github.com/fidley/falv


Of course, you can also modify this to change the alv display method 

6: Thanks to the code of an unknown developer (the original author was not found), which gave me inspiration
