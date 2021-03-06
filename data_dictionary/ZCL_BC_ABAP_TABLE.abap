CLASS zcl_bc_abap_table DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.

    TYPES:
      tt_dd03l TYPE STANDARD TABLE OF dd03l WITH DEFAULT KEY,

      BEGIN OF t_tabfld,
        tabname   TYPE dd03l-tabname,
        fieldname TYPE dd03l-fieldname,
        rollname  TYPE dd03l-rollname,
      END OF t_tabfld ,

      tt_tabfld       TYPE STANDARD TABLE OF t_tabfld WITH DEFAULT KEY,
      tt_tabfld_fsort TYPE SORTED TABLE OF t_tabfld WITH UNIQUE KEY primary_key COMPONENTS fieldname,

      BEGIN OF t_tabname,
        tabname TYPE tabname,
      END OF t_tabname,

      tt_tabname     TYPE STANDARD TABLE OF t_tabname WITH DEFAULT KEY,

      tt_tabname_rng TYPE RANGE OF tabname,

      BEGIN OF t_fldroll,
        fieldname TYPE dd03l-fieldname,
        rollname  TYPE dd03l-rollname,
      END OF t_fldroll,

      tt_fldroll TYPE STANDARD TABLE OF t_fldroll WITH DEFAULT KEY.

    DATA gs_def TYPE dd02l READ-ONLY.
    DATA core   TYPE REF TO ycl_addict_table READ-ONLY.

    CLASS-METHODS:

      get_dbfield_text
        IMPORTING !iv_dbfield      TYPE clike
        RETURNING VALUE(rv_ddtext) TYPE ddtext,

      get_instance
        IMPORTING !iv_tabname   TYPE tabname
        RETURNING VALUE(ro_obj) TYPE REF TO zcl_bc_abap_table
        RAISING   zcx_bc_table_content,

      get_rollname_pairs
        IMPORTING
          !iv_tabname1  TYPE tabname
          !iv_tabname2  TYPE tabname
        RETURNING
          VALUE(rt_ret) TYPE zbctt_rollname_pair
        RAISING
          zcx_bc_table_content ,

      get_tables_containing_dtel
        IMPORTING !iv_rollname      TYPE rollname
        RETURNING VALUE(rt_tabname) TYPE tt_tabname,

      get_tables_containing_fldroll
        IMPORTING
          !it_tabname_rng   TYPE tt_tabname_rng
          !it_fldroll       TYPE tt_fldroll
        RETURNING
          VALUE(rt_tabname) TYPE tt_tabname,

      set_editable_in_ze16n
        CHANGING
          !cv_edit    TYPE clike
          !cv_sapedit TYPE clike.

    METHODS:
      check_table_has_flds_of_tab
        IMPORTING !iv_tabname TYPE tabname
        RAISING   zcx_bc_table_content,


      check_table_has_field
        IMPORTING !iv_fieldname TYPE fieldname
        RAISING   zcx_bc_table_content,

      enqueue
        IMPORTING !iv_key TYPE clike OPTIONAL
        RAISING   cx_rs_foreign_lock ,

      get_field
        IMPORTING !iv_fnam        TYPE fieldname
        RETURNING VALUE(rs_dd03l) TYPE dd03l
        RAISING   zcx_bc_table_content,

      get_field_count RETURNING VALUE(rv_count) TYPE i,

      get_fields RETURNING VALUE(rt_dd03l) TYPE tt_dd03l,

      get_included_tables
        IMPORTING !iv_recursive     TYPE abap_bool
        RETURNING VALUE(rt_tabname) TYPE tt_tabname,

      get_key_fields
        IMPORTING !iv_with_mandt  TYPE abap_bool DEFAULT abap_true
        RETURNING VALUE(rt_dd03l) TYPE tt_dd03l,

      get_rollname_of_field
        IMPORTING !iv_fnam       TYPE fieldname
        RETURNING VALUE(rv_roll) TYPE rollname
        RAISING   zcx_bc_table_content,

      is_field_key
        IMPORTING !iv_fnam      TYPE fieldname
        RETURNING VALUE(rv_key) TYPE abap_bool.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF t_mt, " Multiton
        tabname TYPE dd02l,
        obj     TYPE REF TO zcl_bc_abap_table,
      END OF t_mt,

      tt_mt
        TYPE HASHED TABLE OF t_mt
        WITH UNIQUE KEY primary_key COMPONENTS tabname.


    CONSTANTS: BEGIN OF c_tcode,
                 edit_table TYPE sytcode VALUE 'ZE16N',
               END OF c_tcode.

    CLASS-DATA gt_mt TYPE tt_mt.
ENDCLASS.



CLASS zcl_bc_abap_table IMPLEMENTATION.
  METHOD check_table_has_field.
    TRY.
        me->core->check_table_has_field( iv_fieldname ).
      CATCH ycx_addict_table_content INTO DATA(tc).
        zcx_bc_table_content=>raise_from_addict( tc ).
    ENDTRY.
  ENDMETHOD.


  METHOD check_table_has_flds_of_tab.
    TRY.
        me->core->check_table_has_flds_of_tab( iv_tabname ).
      CATCH ycx_addict_table_content INTO DATA(tc).
        zcx_bc_table_content=>raise_from_addict( tc ).
    ENDTRY.
  ENDMETHOD.


  METHOD enqueue.
    me->core->enqueue( key = iv_key ).
  ENDMETHOD.


  METHOD get_dbfield_text.
    rv_ddtext = ycl_addict_table=>get_dbfield_text( iv_dbfield ).
  ENDMETHOD.


  METHOD get_field.
    TRY.
        rs_dd03l = me->core->get_field( iv_fnam ).
      CATCH ycx_addict_table_content INTO DATA(tc).
        zcx_bc_table_content=>raise_from_addict( tc ).
    ENDTRY.
  ENDMETHOD.


  METHOD get_field_count.
    rv_count = me->core->get_field_count( ).
  ENDMETHOD.


  METHOD get_fields.
    rt_dd03l = me->core->get_fields( ).
  ENDMETHOD.


  METHOD get_included_tables.
    rt_tabname = me->core->get_included_tables( iv_recursive ).
  ENDMETHOD.


  METHOD get_instance.
    ASSIGN gt_mt[ KEY primary_key COMPONENTS tabname = iv_tabname ] TO FIELD-SYMBOL(<ls_mt>).

    IF sy-subrc <> 0.
      DATA(ls_mt) = VALUE t_mt( tabname = iv_tabname ).
      ls_mt-obj = NEW #( ).

      TRY.
          ls_mt-obj->core = ycl_addict_table=>get_instance( iv_tabname ).
        CATCH ycx_addict_table_content INTO DATA(tce).
          zcx_bc_table_content=>raise_from_addict( tce ).
      ENDTRY.

      ls_mt-obj->gs_def = CORRESPONDING #( ls_mt-obj->core->def ).
      INSERT ls_mt INTO TABLE gt_mt ASSIGNING <ls_mt>.
    ENDIF.

    ro_obj = <ls_mt>-obj.
  ENDMETHOD.


  METHOD get_key_fields.
    rt_dd03l = me->core->get_key_fields( with_mandt = iv_with_mandt ).
  ENDMETHOD.


  METHOD get_rollname_of_field.
    TRY.
        rv_roll = me->core->get_rollname_of_field( iv_fnam ).
      CATCH ycx_addict_table_content INTO DATA(tc).
        zcx_bc_table_content=>raise_from_addict( tc ).
    ENDTRY.
  ENDMETHOD.


  METHOD get_rollname_pairs.
    TRY.
        rt_ret = ycl_addict_table=>get_rollname_pairs(
            tabname1 = iv_tabname1
            tabname2 = iv_tabname1 ).
      CATCH ycx_addict_table_content INTO DATA(tc).
        zcx_bc_table_content=>raise_from_addict( tc ).
    ENDTRY.
  ENDMETHOD.


  METHOD get_tables_containing_dtel.
    rt_Tabname = ycl_Addict_Table=>get_tables_containing_dtel( iv_rollname ).
  ENDMETHOD.


  METHOD get_tables_containing_fldroll.
    rt_tabname = ycl_Addict_Table=>get_tables_containing_fldroll(
        tabname_rng = it_tabname_rng
        fldroll     = corresponding #( it_fldroll ) ).
  ENDMETHOD.


  METHOD is_field_key.
    rv_key = me->core->is_field_key( iv_fnam ).
  ENDMETHOD.


  METHOD set_editable_in_ze16n.
    CHECK sy-tcode = c_tcode-edit_table.

    TRY.
        IF NOT zcl_bc_sap_user=>get_instance( sy-uname )->can_debug_change( ).
          RETURN.
        ENDIF.
      CATCH cx_root.
        RETURN.
    ENDTRY.

    cv_edit    = abap_true.
    cv_sapedit = abap_true.
  ENDMETHOD.
ENDCLASS.