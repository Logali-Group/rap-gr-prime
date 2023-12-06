class lhc_Travel definition inheriting from cl_abap_behavior_handler.
  private section.

    constants:
      begin of travel_status,
        open     type c length 1 value 'O', "Open
        accepted type c length 1 value 'A', "Accepted
        rejected type c length 1 value 'X', "Rejected
      end of travel_status.


    methods get_instance_features for instance features
      importing keys request requested_features for Travel result result.

    methods get_instance_authorizations for instance authorization
      importing keys request requested_authorizations for Travel result result.

    methods get_global_authorizations for global authorization
      importing request requested_authorizations for Travel result result.

    methods precheck_create for precheck
      importing entities for create Travel.

    methods precheck_update for precheck
      importing entities for update Travel.

    methods acceptTravel for modify
      importing keys for action Travel~acceptTravel result result.

    methods deductDiscount for modify
      importing keys for action Travel~deductDiscount result result.

    methods reCalcTotalPrice for modify
      importing keys for action Travel~reCalcTotalPrice.

    methods rejectTravel for modify
      importing keys for action Travel~rejectTravel result result.

    methods Resume for modify
      importing keys for action Travel~Resume.

    methods calculateTotalPrice for determine on modify
      importing keys for Travel~calculateTotalPrice.

    methods setStatusToOpen for determine on modify
      importing keys for Travel~setStatusToOpen.

    methods setTravelNumber for determine on save
      importing keys for Travel~setTravelNumber.

    methods validateAgency for validate on save
      importing keys for Travel~validateAgency.

    methods validateCustomer for validate on save
      importing keys for Travel~validateCustomer.

    methods validateDates for validate on save
      importing keys for Travel~validateDates.

    types:
      t_entities_create type table for create zr_travel_prim00\\Travel,
      t_entities_update type table for update zr_travel_prim00\\Travel,
      t_failed_travel   type table for failed early zr_travel_prim00\\Travel,
      t_reported_travel type table for reported early zr_travel_prim00\\Travel.

    methods prechek_auth importing entities_create type t_entities_create optional
                                   entities_update type t_entities_update optional
                         changing  failed          type t_failed_travel
                                   reported        type t_reported_travel.

    types: t_actionImp_AcceptTravel type table for action import zr_travel_prim00~acceptTravel,
           t_actionImp_RejectTravel type table for action import zr_travel_prim00~rejectTravel,
           t_actionRes_AcceptTravel type table for action result zr_travel_prim00~acceptTravel,
           t_actionRes_RejectTravel type table for action result zr_travel_prim00~rejectTravel.

    methods changeTravelStatus importing keys_AcceptTravel   type t_actionImp_AcceptTravel optional
                                         keys_RejectTravel   type t_actionImp_RejectTravel optional
                               changing  result_AcceptTravel type t_actionRes_AcceptTravel optional
                                         result_RejectTravel type t_actionRes_RejectTravel optional.

endclass.

class lhc_Travel implementation.

  method get_instance_features.

  read entities of zr_travel_prim00 in local mode
         entity Travel
         fields ( OverallStatus )
         with corresponding #( keys )
         result data(lt_travels)
         failed failed.

*   result[ 1 ]-%action-acceptTravel =
*   result[ 1 ]-%field-BookingFee = if_abap_behv=>fc-f-unrestricted

   result = value #( for ls_travel in lt_travels (
                         %tky = ls_travel-%tky
                         %field-BookingFee = cond #( when ls_travel-OverallStatus = travel_status-accepted
                                                     then if_abap_behv=>fc-f-read_only
                                                     else if_abap_behv=>fc-f-unrestricted )
                         %action-acceptTravel = cond #( when ls_travel-OverallStatus = travel_status-accepted
                                                     then if_abap_behv=>fc-o-disabled
                                                     else if_abap_behv=>fc-o-enabled )
                         %action-rejectTravel = cond #( when ls_travel-OverallStatus = travel_status-rejected
                                                     then if_abap_behv=>fc-o-disabled
                                                     else if_abap_behv=>fc-o-enabled )
                         %action-deductDiscount = cond #( when ls_travel-OverallStatus = travel_status-accepted
                                                     then if_abap_behv=>fc-o-disabled
                                                     else if_abap_behv=>fc-o-enabled )
                      ) ).

  endmethod.

  method get_instance_authorizations.

    check 1 = 2.

    read entities of zr_travel_prim00 in local mode
         entity Travel
         fields ( AgencyID )
         with corresponding #( keys )
         result data(lt_travels).


    data(lv_update_del_requested) = cond #( when requested_authorizations-%update = if_abap_behv=>mk-on
                                              or requested_authorizations-%delete = if_abap_behv=>mk-on
                                        then abap_true
                                        else abap_false ).

    check lv_update_del_requested = abap_true.

    loop at lt_travels into data(travel).

      if cl_abap_context_info=>get_user_alias(  ) eq 'CB9980005947'.
        data(lv_granted) = abap_true.
      else.
        lv_granted = abap_false.
      endif.

      "reported-travel[ 1 ]-%element-agencyid

      append value #( %tky = travel-%tky
                      %msg = new /dmo/cm_flight_messages(
                                      textid   = /dmo/cm_flight_messages=>not_authorized
                                      severity = if_abap_behv_message=>severity-error )
                      %element-CustomerId = if_abap_behv=>mk-on
                                      ) to reported-travel.
      "result[ 1 ]-%action-Edit
      append value #( let upd_auth = cond #( when lv_granted = abap_true
                                             then if_abap_behv=>auth-allowed
                                             else if_abap_behv=>auth-unauthorized )

                          del_auth = cond #( when lv_granted = abap_true
                                             then if_abap_behv=>auth-allowed
                                             else if_abap_behv=>auth-unauthorized )
                      in
                      %tky = travel-%tky
                      %update = upd_auth
                      %action-Edit = upd_auth
                      %delete = del_auth
                       ) to result.

    endloop.

  endmethod.

  method get_global_authorizations.
  endmethod.

  method precheck_create.
    me->prechek_auth(
      exporting
        entities_create = entities
*       entities_update =
      changing
        failed          = failed-travel
        reported        = reported-travel ).

  endmethod.

  method precheck_update.
    me->prechek_auth(
      exporting
*       entities_create =
        entities_update = entities
      changing
        failed          = failed-travel
        reported        = reported-travel ).
  endmethod.

  method acceptTravel.

* EML - Entity Manipulation Language

* keys[ 1 ]-%tky
* result[ 1 ]-%key-
* mapped-travel[ 1 ]-
* failed-travel[ 1 ]-
* reported-travel[ 1 ]-

*    modify entities of zr_travel_prim00 in local mode
*           entity Travel
*           update
*           fields ( OverallStatus )
*           with value #( for key in keys ( %tky = key-%tky
*                                            OverallStatus = travel_status-accepted ) ).
*
*    read entities of zr_travel_prim00 in local mode
*         entity Travel
*         all fields
*         with corresponding #( keys )
*         result data(travels).
*
*    result = value #( for <travel> in travels ( %tky   = <travel>-%tky
*                                                %param = <travel>  )  ).

    me->changetravelstatus( exporting keys_accepttravel   = keys
                            changing  result_accepttravel = result ).

  endmethod.

  method deductDiscount.

    data lt_travels_for_update type table for update zr_travel_prim00.
    data(lt_keys_with_valid_discount) = keys.

    loop at lt_keys_with_valid_discount assigning field-symbol(<key_with_valid_discount>)
            where %param-discount_percent is initial
               or %param-discount_percent > 100
               or %param-discount_percent < 1.

      append value #( %tky = <key_with_valid_discount>-%tky ) to failed-travel.

      append value #( %tky = <key_with_valid_discount>-%tky
                      %msg = new /dmo/cm_flight_messages(
                                     textid = /dmo/cm_flight_messages=>discount_invalid
                                     severity = if_abap_behv_message=>severity-warning )
*                      %element-TotalPrice = if_abap_behv=>mk-on
*                      %op-%action-deductDiscount = if_abap_behv=>mk-on
                      ) to reported-travel.
      delete lt_keys_with_valid_discount.
    endloop.


    check lt_keys_with_valid_discount is not initial.

    read entities of zr_travel_prim00 in local mode
         entity Travel
         fields (  BookingFee )
         with corresponding #( lt_keys_with_valid_discount )
         result data(lt_travels).

    loop at lt_travels assigning field-symbol(<travels>).

      data percentage type decfloat16.

      data(discount_percentage) = lt_keys_with_valid_discount[ key id
                                                              %tky = <travels>-%tky ]-%param-discount_percent.

      percentage = discount_percentage / 100.
      data(reduce_fee) = <travels>-BookingFee * ( 1 - percentage ).

      append value #( %tky = <travels>-%tky
                      BookingFee = reduce_fee ) to lt_travels_for_update.

    endloop.

    modify entities of zr_travel_prim00 in local mode
          entity Travel
          update fields (  BookingFee )
          with lt_travels_for_update.

    read entities of zr_travel_prim00 in local mode
         entity Travel
         all fields
         with corresponding #( lt_travels )
         result data(lt_travels_with_discount).

    result = value #( for travel in lt_travels_with_discount ( %tky   = travel-%tky
                                                               %param = travel ) ).


  endmethod.

  method reCalcTotalPrice.

    types: begin of ty_amount_per_currencycode,
             amount        type /dmo/total_price,
             currency_code type /dmo/currency_code,
           end of ty_amount_per_currencycode.

    data lt_amounts_per_currencycode type standard table of ty_amount_per_currencycode.

    read entities of zr_travel_prim00 in local mode
         entity Travel
         fields ( BookingFee CurrencyCode )
         with corresponding #( keys )
         result data(lt_travels).

    delete lt_travels where CurrencyCode is initial.

    read entities of zr_travel_prim00 in local mode
         entity Travel by \_Booking
         fields ( FlightPrice CurrencyCode )
         with corresponding #( lt_travels )
         link data(lt_booking_links)
         result data(lt_bookings).

    loop at lt_travels assigning field-symbol(<travel>).

      lt_amounts_per_currencycode = value #( ( amount = <travel>-BookingFee
                                               currency_code = <travel>-CurrencyCode ) ).

      loop at lt_booking_links into data(booking_link) using key id
                               where source-%tky = <travel>-%tky.

        data(booking) =  lt_bookings[ key id
                                      %tky = booking_link-target-%tky ].

        collect value ty_amount_per_currencycode( amount        = booking-FlightPrice
                                                  currency_code = booking-CurrencyCode )
                     into lt_amounts_per_currencycode.

      endloop.

      delete lt_amounts_per_currencycode where currency_code is initial.

      clear <travel>-TotalPrice.

      loop at lt_amounts_per_currencycode into data(ls_amount_per_currencycode).

        if ls_amount_per_currencycode-currency_code = <travel>-CurrencyCode.
          <travel>-TotalPrice += ls_amount_per_currencycode-amount.
        else.
          /dmo/cl_flight_amdp=>convert_currency(
            exporting
              iv_amount               = ls_amount_per_currencycode-amount
              iv_currency_code_source = ls_amount_per_currencycode-currency_code
              iv_currency_code_target = <travel>-CurrencyCode
              iv_exchange_rate_date   = cl_abap_context_info=>get_system_date( )
            importing
              ev_amount               = data(lv_total_book_price_per_curr) ).
          <travel>-TotalPrice += lv_total_book_price_per_curr.
        endif.

      endloop.
    endloop.

    modify entities of zr_travel_prim00 in local mode
         entity Travel
         update fields ( TotalPrice )
         with corresponding #( lt_travels ).

  endmethod.

  method rejectTravel.
    me->changetravelstatus( exporting keys_rejecttravel   = keys
                            changing  result_rejecttravel = result ).
  endmethod.

  method Resume.
  endmethod.

  method calculateTotalPrice.

    modify entities of zr_travel_prim00 in local mode
           entity Travel
           execute reCalcTotalPrice
           from corresponding #( keys ).

  endmethod.

  method setStatusToOpen.


    read entities of zr_travel_prim00 in local mode
         entity Travel
         fields ( OverallStatus )
         with corresponding #( keys )
         result data(lt_travels).

    delete lt_travels where OverallStatus is not initial.
    check lt_travels is not initial.

    modify entities of zr_travel_prim00 in local mode
           entity Travel
           update fields ( OverallStatus )
           with value #( for <travel> in lt_travels (
                              %tky = <travel>-%tky
                              OverallStatus = travel_status-open ) ).

  endmethod.

  method setTravelNumber.

    read entities of zr_travel_prim00 in local mode
         entity Travel
         fields ( TravelID )
         with corresponding #( keys )
         result data(lt_travels).

    delete lt_travels where TravelID is not initial.

    check lt_travels is not initial.

    select single from ztravel_prim_a
           fields max( travel_id )
           into @data(lv_max_travelid).

    modify entities of zr_travel_prim00 in local mode
           entity Travel
           update fields ( TravelID )
           with value #( for travel in lt_travels index into i (
                                  %tky = travel-%tky
                                  TravelID = lv_max_travelid + i ) ).

  endmethod.

  method validateAgency.
  endmethod.

  method validateCustomer.

    data lt_customers type sorted table of /dmo/customer with unique key client customer_id.

    read entities of zr_travel_prim00 in local mode
         entity Travel
         fields ( CustomerID )
         with corresponding #( keys )
         result data(lt_travels).

    lt_customers = corresponding #( lt_travels discarding duplicates
                                    mapping customer_id = CustomerID except * ).

    delete lt_customers where customer_id is initial.

    if lt_customers is not initial.

      select from @lt_customers as it_cust
             inner join /dmo/customer as db_cust
                     on it_cust~customer_id eq db_cust~customer_id
             fields it_cust~customer_id
             into table @data(lt_valid_customers).

    endif.

    loop at lt_travels into data(ls_travel).

      if ls_travel-CustomerID is initial.

        "failed-travel[ 1 ]-%tky
        append value #( %tky = ls_travel-%tky ) to failed-travel.

        "reported-travel[ 1 ]-%state_area

        append value #( %tky = ls_travel-%tky
                        %state_area = 'VALIDATE_CUSTOMER'
                        %msg = new /dmo/cm_flight_messages(
                                       textid = /dmo/cm_flight_messages=>enter_customer_id
                                       severity = if_abap_behv_message=>severity-error )
                         %element-CustomerId = if_abap_behv=>mk-on
                         ) to reported-travel.

      elseif ls_travel-CustomerID is not initial
             and not line_exists( lt_valid_customers[ customer_id = ls_travel-CustomerID ] ).

        append value #( %tky = ls_travel-%tky ) to failed-travel.

        append value #( %tky = ls_travel-%tky
                        %state_area = 'VALIDATE_CUSTOMER'
                        %msg = new /dmo/cm_flight_messages(
                                       customer_id = ls_travel-CustomerID
                                       textid = /dmo/cm_flight_messages=>customer_unkown
                                       severity = if_abap_behv_message=>severity-error )
                         %element-CustomerId = if_abap_behv=>mk-on
                         ) to reported-travel.
      endif.


    endloop.


  endmethod.

  method validateDates.
  endmethod.

  method prechek_auth.

    data: entities          type t_entities_update,
          operation         type if_abap_behv=>t_char01,
          is_modify_granted type abap_boolean.

    if entities_create is not initial.
      entities = corresponding #( entities_create mapping %cid_ref = %cid ).
      operation = if_abap_behv=>op-m-create.
    elseif entities_update is not initial.
      entities = entities_update.
      operation = if_abap_behv=>op-m-update.
    endif.

    loop at entities into data(entity).

      is_modify_granted = abap_false.

      case operation.
        when if_abap_behv=>op-m-create.
          authority-check object '/DMO/TRVL' id '/DMO/CNTRY' field 'US'
                                             id 'ACTVT'      field '01'.
          is_modify_granted = cond #( when sy-subrc = 0
                                      then abap_true
                                      else abap_false ).
        when if_abap_behv=>op-m-update.
          authority-check object '/DMO/TRVL' id '/DMO/CNTRY' field 'US'
                                             id 'ACTVT'      field '02'.
          is_modify_granted = cond #( when sy-subrc = 0
                                      then abap_true
                                      else abap_false ).
      endcase.

      "failed[ 1 ]-%cid

      if is_modify_granted = abap_false.

        append value #( %cid = cond #( when operation = if_abap_behv=>op-m-create
                                       then entity-%cid_ref )
                        %tky = entity-%tky ) to failed.

        append value #( %cid = cond #( when operation = if_abap_behv=>op-m-create
                                       then entity-%cid_ref )
                        %tky = entity-%tky
                        %msg = new /dmo/cm_flight_messages(
                                       textid = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                       agency_id = entity-AgencyID
                                       severity = if_abap_behv_message=>severity-error
                                       )
                        %element-AgencyId = if_abap_behv=>mk-on
                        ) to reported.
      endif.

    endloop.


  endmethod.

  method changetravelstatus.

    if keys_accepttravel is not initial.

      modify entities of zr_travel_prim00 in local mode
             entity Travel
             update
             fields ( OverallStatus )
             with value #( for key in keys_accepttravel ( %tky = key-%tky
                                              OverallStatus = travel_status-accepted ) ).

      read entities of zr_travel_prim00 in local mode
           entity Travel
           all fields
           with corresponding #( keys_accepttravel )
           result data(travels).


      result_accepttravel = value #( for <travel> in travels ( %tky   = <travel>-%tky
                                                                %param = <travel>  )  ).

    elseif keys_rejecttravel is not initial.

      modify entities of zr_travel_prim00 in local mode
             entity Travel
             update
             fields ( OverallStatus )
             with value #( for <key> in keys_rejecttravel ( %tky = <key>-%tky
                                                            OverallStatus = travel_status-rejected ) ).

      read entities of zr_travel_prim00 in local mode
           entity Travel
           all fields
           with corresponding #( keys_rejecttravel )
           result travels.

      result_rejecttravel = value #( for <travel> in travels ( %tky   = <travel>-%tky
                                                               %param = <travel>  )  ).

    endif.
  endmethod.

endclass.
