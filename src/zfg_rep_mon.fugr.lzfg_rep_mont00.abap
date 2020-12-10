*---------------------------------------------------------------------*
*    view related data declarations
*   generation date: 2020.09.29 at 10:05:08
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
*...processing: ZREPMOR_CONFIG..................................*
DATA:  BEGIN OF STATUS_ZREPMOR_CONFIG                .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZREPMOR_CONFIG                .
CONTROLS: TCTRL_ZREPMOR_CONFIG
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZREPMOR_CONFIG                .
TABLES: ZREPMOR_CONFIG                 .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
