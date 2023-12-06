class lhc_HCM definition inheriting from cl_abap_behavior_handler.
  private section.

    methods get_instance_authorizations for instance authorization
      importing keys request requested_authorizations for hcm result result.

    methods create for modify
      importing entities for create hcm.

    methods update for modify
      importing entities for update hcm.

    methods delete for modify
      importing keys for delete hcm.

    methods read for read
      importing keys for read hcm result result.

    methods lock for lock
      importing keys for lock hcm.

endclass.

class lhc_HCM implementation.

  method get_instance_authorizations.
  endmethod.

  method create.
  endmethod.

  method update.
  endmethod.

  method delete.
  endmethod.

  method read.
  endmethod.

  method lock.
  endmethod.

endclass.

class lsc_ZR_HR_PRIM00 definition inheriting from cl_abap_behavior_saver.
  protected section.

    methods finalize redefinition.

    methods check_before_save redefinition.

    methods save redefinition.

    methods cleanup redefinition.

    methods cleanup_finalize redefinition.

endclass.

class lsc_ZR_HR_PRIM00 implementation.

  method finalize.
  endmethod.

  method check_before_save.
  endmethod.

  method save.
  endmethod.

  method cleanup.
  endmethod.

  method cleanup_finalize.
  endmethod.

endclass.
