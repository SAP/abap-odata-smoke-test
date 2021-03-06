*&---------------------------------------------------------------------*
*& Report Z_ODATA_SMOKE_TEST
*&---------------------------------------------------------------------*
*& PURPOSE: RETRIEVE ALL ACTIVE ODATA SERVICES AND PERFORM A $METADATA
*& AS WELL AS A RANDOM ENTITY CALL (OPTIONAL => FLAG test_entity)
*&---------------------------------------------------------------------*
REPORT Z_ODATA_SMOKE_TEST.

DATA:
lv_status_code TYPE INTEGER,
ss_status_code TYPE STRING,
lv_service_string TYPE STRING,
mo_client_proxy TYPE REF TO /iwfnd/cl_sutil_client_proxy,
lt_request_header TYPE /iwfnd/sutil_property_t,
ls_request_header TYPE /iwfnd/sutil_property,
my_message1 TYPE STRING,
my_message2 TYPE STRING,
my_message3 TYPE STRING,
lv_srv_name TYPE STRING,
lv_system_url TYPE STRING,
lv_service_version TYPE STRING,
lv_status_text    TYPE string,
lv_content_type   TYPE string,
lv_error_text     TYPE string,
lv_response_body  TYPE xstring,
lv_namespace TYPE STRING,
lv_index          TYPE i,
ls_document       TYPE /iwfnd/sutil_xml_data,
ls_doc_check      TYPE /iwfnd/sutil_xml_data,
lt_document       TYPE /iwfnd/sutil_xml_data_t,
lv_is_func_imp    TYPE abap_bool,
lt_dynp_output    TYPE STANDARD TABLE OF /iwfnd/sh_entityset_name,
ls_dynp_result    TYPE ddshretval,
lt_dynp_result    TYPE STANDARD TABLE OF ddshretval,
mv_etext          TYPE STRING,
ls_entities       TYPE STRING,
ls_entity        TYPE STRING,
lt_msg        TYPE balmi_tab,
ls_msg        TYPE balmi,
test_entity   TYPE abap_bool.

DATA:
it_services TYPE table of /IWFND/I_MED_SIN with header line.

* ENABLE/DISABLE GET ENTITYSET CALLS
test_entity = abap_false.

*&---------------------------------------------------------------------*
*& FETCH ALL ODATA SERVICES
*&---------------------------------------------------------------------*

SELECT * FROM /IWFND/I_MED_SIN WHERE NAME = 'BEP_SVC_EXT_SERVICE_NAME' INTO TABLE @it_services.

loop at it_services.

  lv_srv_name = it_services-VALUE.

  lv_namespace = ''.
  my_message1 = ''.
  my_message2 = ''.
  my_message3 = ''.

  SELECT VALUE FROM /IWFND/I_MED_SIN WHERE SRV_IDENTIFIER = @it_services-SRV_IDENTIFIER AND NAME = 'BEP_SVC_ORG_NAMESPACE' INTO @lv_namespace.
  ENDSELECT.

  IF lv_namespace = ''.
  lv_namespace = '/sap/'.
  ENDIF.

  lv_service_version = ''.

  SELECT VALUE FROM /IWFND/I_MED_SIN WHERE SRV_IDENTIFIER = @it_services-SRV_IDENTIFIER AND NAME = 'BEP_SVC_SERVICE_VERSION' INTO @lv_service_version.
  ENDSELECT.

  IF lv_service_version = '0002'.
  CONCATENATE lv_srv_name ';v=2' INTO lv_srv_name.
  ENDIF.

  IF lv_service_version = '0003'.
  CONCATENATE lv_srv_name ';v=3' INTO lv_srv_name.
  ENDIF.

  CONCATENATE `/sap/opu/odata` lv_namespace lv_srv_name INTO lv_service_string.

  lv_system_url = ''.

*&---------------------------------------------------------------------*
*& PERFORM $metadata CALL
*&---------------------------------------------------------------------*

  IF mo_client_proxy IS INITIAL.
    mo_client_proxy     = /iwfnd/cl_sutil_client_proxy=>get_instance( ).
  ENDIF.

  ls_request_header-name = '~request_method'.
  ls_request_header-value = 'GET'.

  APPEND ls_request_header TO lt_request_header.
  ls_request_header-name = '~request_uri'.

  CONCATENATE lv_system_url lv_service_string '/' '$metadata' INTO ls_request_header-value.
  APPEND ls_request_header TO lt_request_header.

  mo_client_proxy->web_request(
    EXPORTING
      it_request_header     =     lt_request_header
    IMPORTING
      ev_status_code        =     lv_status_code ).

  ss_status_code = lv_status_code.

  CONCATENATE lv_service_string '/' INTO my_message1.

  CONCATENATE '$metadata' `` INTO my_message2.

  CONCATENATE `[HTTP` ss_status_code `]` INTO my_message3.
  CONDENSE my_message3 NO-GAPS.

  IF lv_status_code = 200.
    ls_msg-msgty = 'I'.
    ls_msg-msgid = '00'.
    ls_msg-msgno = '398'.
    ls_msg-msgv1 = my_message1.
    ls_msg-msgv2 = my_message2.
    ls_msg-msgv3 = my_message3.
  ELSE.
    ls_msg-msgty = 'E'.
    ls_msg-msgid = '00'.
    ls_msg-msgno = '398'.
    ls_msg-msgv1 = my_message1.
    ls_msg-msgv2 = my_message2.
    ls_msg-msgv3 = my_message3.
  ENDIF.
  APPEND ls_msg TO lt_msg.

*&---------------------------------------------------------------------*
*& PERFORM SERVICE DOCUMENT CALL
*&---------------------------------------------------------------------*

IF lv_status_code = 200 AND test_entity = abap_true.

  CLEAR lt_request_header.

  ls_request_header-name = '~request_method'.
  ls_request_header-value = 'GET'.

  APPEND ls_request_header TO lt_request_header.
  ls_request_header-name = '~request_uri'.

  CONCATENATE lv_system_url lv_service_string '/' INTO ls_request_header-value.
  APPEND ls_request_header TO lt_request_header.

  mo_client_proxy->web_request(
    EXPORTING
      it_request_header     =     lt_request_header
    IMPORTING
      ev_status_code      = lv_status_code
      ev_status_text      = lv_status_text
      ev_content_type     = lv_content_type
      ev_response_body    = lv_response_body
      ev_error_text       = lv_error_text ).

  CLEAR my_message1.
  CLEAR my_message2.
  CLEAR my_message3.
  ss_status_code = lv_status_code.

  CONCATENATE lv_service_string '/' INTO my_message1.

  CONCATENATE `(ServiceDocument)` `` INTO my_message2.

  CONCATENATE `[HTTP` ss_status_code `]` INTO my_message3.
  CONDENSE my_message3 NO-GAPS.

  IF lv_status_code = 200.
    ls_msg-msgty = 'I'.
    ls_msg-msgid = '00'.
    ls_msg-msgno = '398'.
    ls_msg-msgv1 = my_message1.
    ls_msg-msgv2 = my_message2.
    ls_msg-msgv3 = my_message3.
  ELSE.
    ls_msg-msgty = 'E'.
    ls_msg-msgid = '00'.
    ls_msg-msgno = '398'.
    ls_msg-msgv1 = my_message1.
    ls_msg-msgv2 = my_message2.
    ls_msg-msgv3 = my_message3.
  ENDIF.
  APPEND ls_msg TO lt_msg.

*&---------------------------------------------------------------------*
*& READ ENTITIES
*&---------------------------------------------------------------------*

IF lv_response_body IS NOT INITIAL AND lv_status_code = 200 AND test_entity = abap_true.

        CLEAR lt_dynp_output.
        CLEAR ls_entity.

*       V4 service document has the json format
        IF lv_content_type CS 'json'.

*       Create Table of Entitysets
          /iwfnd/cl_sutil_xml_helper=>shift_json_to_table(
            EXPORTING
              iv_xdoc       = lv_response_body
            IMPORTING
              et_data       = lt_document ).

          "Create Table of EntitySets
          LOOP AT lt_document INTO ls_document
            WHERE tag_name = 'name'.                              "#EC NOTEXT

            lv_index = sy-tabix + 1.
            lv_is_func_imp = abap_false.

            "in V4 the service document can contain also FunctionImports
            " these need to be filtered out
            LOOP AT lt_document FROM lv_index INTO ls_doc_check.
              IF ls_doc_check-tag_name = 'name'.                  "#EC NOTEXT
                EXIT.
              ELSEIF ls_doc_check-tag_name = 'kind' AND
                     ls_doc_check-tag_value EQ 'FunctionImport'.  "#EC NOTEXT
                lv_is_func_imp = abap_true.
              ENDIF.
            ENDLOOP.

            IF lv_is_func_imp = abap_false.
              APPEND ls_document-tag_value TO lt_dynp_output.
            ENDIF.
          ENDLOOP.

*       V2 service document has the xml format
        ELSEIF lv_content_type CS 'xml'.

*       Create Table of Entitysets
          /iwfnd/cl_sutil_xml_helper=>shift_xml_to_table(
            EXPORTING
              iv_xdoc       = lv_response_body
            IMPORTING
              et_data       = lt_document
              ev_error_text = lv_error_text
          ).
          IF lv_error_text IS NOT INITIAL.
            mv_etext = lv_status_text.
            MESSAGE mv_etext TYPE 'I' DISPLAY LIKE 'E'.
            RETURN.
          ENDIF.

*       "Create Table of EntitySets
          LOOP AT lt_document INTO ls_document
            WHERE tag_name = 'app:collection'
               OR tag_name = 'collection'.                        "#EC NOTEXT
            lv_index = sy-tabix + 1.
            LOOP AT lt_document INTO ls_document FROM lv_index.
              IF ls_document-tag_type <> /iwfnd/cl_sutil_xml_helper=>gc_tag_type_attribute.
                mv_etext = 'Invalid Collection Data'.             "#EC NOTEXT
                MESSAGE mv_etext TYPE 'I'.
                EXIT.
              ENDIF.
              IF ls_document-tag_name = 'href'. EXIT. ENDIF.
            ENDLOOP.
            IF mv_etext IS NOT INITIAL. EXIT. ENDIF.
            APPEND ls_document-tag_value TO lt_dynp_output.
          ENDLOOP.
          IF mv_etext IS NOT INITIAL. RETURN. ENDIF.

        ELSE.                                                     "#EC NOTEXT
          mv_etext = 'Function not available for this service request'(e30).
          MESSAGE mv_etext TYPE 'I'.
          CLEAR mv_etext.
          RETURN.
        ENDIF.

        SORT lt_dynp_output.

*      &---------------------------------------------------------------------*
*      & PERFORM ARBITARY ENTITY REQUEST (IDEALLY F4 or VH or VL)
*      &---------------------------------------------------------------------*

      DATA: gv_linno TYPE i.

      DESCRIBE TABLE lt_dynp_output LINES gv_linno.
      READ TABLE lt_dynp_output INDEX gv_linno INTO ls_entity.

      LOOP AT lt_dynp_output INTO ls_entities.

        IF ls_entities CS 'VH' OR ls_entities CS 'F4' OR ls_entities CS 'VL'.
         ls_entity = ls_entities.
        ENDIF.

      ENDLOOP.

*       PERFORM REQUEST

        IF ls_entity IS NOT INITIAL.

          CLEAR lt_request_header.

          ls_request_header-name = '~request_method'.
          ls_request_header-value = 'GET'.

          APPEND ls_request_header TO lt_request_header.
          ls_request_header-name = '~request_uri'.

          CONCATENATE lv_system_url lv_service_string '/' ls_entity INTO ls_request_header-value.
          APPEND ls_request_header TO lt_request_header.

          mo_client_proxy->web_request(
            EXPORTING
              it_request_header     =     lt_request_header
            IMPORTING
              ev_status_code      = lv_status_code
              ev_status_text      = lv_status_text
              ev_content_type     = lv_content_type
              ev_response_body    = lv_response_body
              ev_error_text       = lv_error_text ).

          CLEAR my_message1.
          CLEAR my_message2.
          CLEAR my_message3.
          ss_status_code = lv_status_code.

          CONCATENATE lv_service_string '/' INTO my_message1.

          CONCATENATE ls_entity `` INTO my_message2.

          CONCATENATE `[HTTP` ss_status_code `]` INTO my_message3.
          CONDENSE my_message3 NO-GAPS.

          IF lv_status_code = 200.
            ls_msg-msgty = 'I'.
            ls_msg-msgid = '00'.
            ls_msg-msgno = '398'.
            ls_msg-msgv1 = my_message1.
            ls_msg-msgv2 = my_message2.
            ls_msg-msgv3 = my_message3.
          ELSE.
            ls_msg-msgty = 'E'.
            ls_msg-msgid = '00'.
            ls_msg-msgno = '398'.
            ls_msg-msgv1 = my_message1.
            ls_msg-msgv2 = my_message2.
            ls_msg-msgv3 = my_message3.
          ENDIF.
          APPEND ls_msg TO lt_msg.
      ENDIF.

      ENDIF.

  ENDIF.

ENDLOOP.

*&---------------------------------------------------------------------*
*& These code snippets will generate the Application log = output only
*&---------------------------------------------------------------------*

DATA: lf_obj        TYPE balobj_d,
      lf_subobj     TYPE balsubobj,
      ls_header     TYPE balhdri,
      lf_log_handle TYPE balloghndl,
      lf_log_number TYPE balognr,
      lt_lognum     TYPE TABLE OF balnri,
      ls_lognum     TYPE balnri.

* Application Log object & Subobject
  lf_obj     = '/IWFND/'.
  lf_subobj  = 'RUNTIM'.

* Header information for the log
  ls_header-object     = lf_obj.
  ls_header-subobject  = lf_subobj.
  ls_header-aldate     = sy-datum.
  ls_header-altime     = sy-uzeit.
  ls_header-aluser     = sy-uname.
  ls_header-aldate_del = sy-datum + 1.

* Get the Log handle using the header
  CALL FUNCTION 'APPL_LOG_WRITE_HEADER'
    EXPORTING
      header              = ls_header
    IMPORTING
      e_log_handle        = lf_log_handle
    EXCEPTIONS
      object_not_found    = 1
      subobject_not_found = 2
      error               = 3
      OTHERS              = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

* Get the next avaliable Log number
  CALL FUNCTION 'BAL_DB_LOGNUMBER_GET'
    EXPORTING
      i_client                 = sy-mandt
      i_log_handle             = lf_log_handle
    IMPORTING
      e_lognumber              = lf_log_number
    EXCEPTIONS
      log_not_found            = 1
      lognumber_already_exists = 2
      numbering_error          = 3
      OTHERS                   = 4.

* Write the Log mesages to the memory
  CALL FUNCTION 'APPL_LOG_WRITE_MESSAGES'
    EXPORTING
      object              = lf_obj
      subobject           = lf_subobj
      log_handle          = lf_log_handle
    TABLES
      messages            = lt_msg
    EXCEPTIONS
      object_not_found    = 1
      subobject_not_found = 2
      OTHERS              = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

* write the log message to Database which can be later analyzed from transaction SLG1

  MOVE-CORRESPONDING ls_header TO ls_lognum.
  ls_lognum-lognumber = lf_log_number.
  APPEND ls_lognum TO lt_lognum.

  CALL FUNCTION 'APPL_LOG_WRITE_DB'
    EXPORTING
      object                = lf_obj
      subobject             = lf_subobj
      log_handle            = lf_log_handle
    TABLES
      object_with_lognumber = lt_lognum
    EXCEPTIONS
      object_not_found      = 1
      subobject_not_found   = 2
      internal_error        = 3
      OTHERS                = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

* display the generate log from the memory.
CALL FUNCTION 'BAL_DSP_LOG_DISPLAY'.
