class lhc_Booking definition inheriting from cl_abap_behavior_handler.
  private section.

    methods calculateTotalPrice for determine on modify
      importing keys for Booking~calculateTotalPrice.

    methods setBookingDate for determine on save
      importing keys for Booking~setBookingDate.

    methods setBookingNumber for determine on save
      importing keys for Booking~setBookingNumber.

    methods validateConnection for validate on save
      importing keys for Booking~validateConnection.

    methods validateCustomer for validate on save
      importing keys for Booking~validateCustomer.

endclass.

class lhc_Booking implementation.

  method calculateTotalPrice.

    "Read all parent UUID
    read entities of zr_travel_prim00 in local mode
         entity Booking by \_Travel
         fields ( TravelUUID )
         with corresponding #( keys )
         result data(lt_travels).

    "Trigger internal action from parent
    modify entities of zr_travel_prim00 in local mode
           entity Travel
           execute reCalcTotalPrice
           from corresponding #( lt_travels ).

  endmethod.

  method setBookingDate.

   read entities of zr_travel_prim00 in local mode
        entity Booking
        fields ( BookingDate )
        with corresponding #( keys )
        result data(lt_bookings).

   delete lt_bookings where BookingDate is not initial.

   check lt_bookings is not initial.

   loop at lt_bookings assigning field-symbol(<ls_booking>).
      <ls_booking>-BookingDate = cl_abap_context_info=>get_system_date(  ).
   endloop.

   modify entities of zr_travel_prim00 in local mode
          entity Booking
          update fields ( BookingDate )
          with corresponding #( lt_bookings ).

  endmethod.

  method setBookingNumber.


    data: lv_max_bookingid   type /dmo/booking_id,
          lt_bookings_update type table for update zr_travel_prim00\\Booking,
          ls_booking         type structure for read result zr_booking_prim00.

    read entities of zr_travel_prim00 in local mode
         entity Booking by \_Travel
         fields ( TravelUUID )
         with corresponding #( keys )
         result data(lt_travels).

    read entities of zr_travel_prim00 in local mode
         entity Travel by \_Booking
         fields ( BookingID )
         with corresponding #( lt_travels )
         link data(lt_booking_links)
         result data(lt_bookinks).

    loop at lt_travels into data(travel).

      lv_max_bookingid = '0000'.
      loop at lt_booking_links into data(ls_booking_link) using key id where source-%tky = travel-%tky.
        ls_booking = lt_bookinks[ key id
                                  %tky = ls_booking_link-target-%tky ].
        if ls_booking-BookingID > lv_max_bookingid.
          lv_max_bookingid = ls_booking-BookingID.
        endif.
      endloop.


      loop at lt_booking_links into ls_booking_link using key id where source-%tky = travel-%tky.
        ls_booking = lt_bookinks[ key id
                                  %tky = ls_booking_link-target-%tky ].
        if ls_booking-BookingID is initial.
          lv_max_bookingid += 1.
          append value #( %tky = ls_booking-%tky
                          BookingID = lv_max_bookingid ) to lt_bookings_update.
        endif.
      endloop.
    endloop.

    modify entities of zr_travel_prim00 in local mode
           entity Booking
           update fields ( BookingID )
           with lt_bookings_update.

  endmethod.

  method validateConnection.
  endmethod.

  method validateCustomer.

    data lt_customers type sorted table of /dmo/customer with unique key customer_id.

    read entities of zr_travel_prim00 in local mode
         entity Booking
         fields ( CustomerID )
         with corresponding #( keys )
         result data(lt_bookings).

    read entities of zr_travel_prim00 in local mode
         entity Booking by \_Travel
         from corresponding #( lt_bookings )
         link data(travel_booking_links).


    lt_customers = corresponding #( lt_bookings discarding duplicates
                                    mapping customer_id = CustomerID except * ).

    delete lt_customers where customer_id is initial.

    if lt_customers is not initial.

      select from /dmo/customer
             fields customer_id
             for all entries in @lt_customers
             where customer_id = @lt_customers-customer_id
             into table @data(valid_customers).

*      select from @lt_customers as it_cust
*             inner join /dmo/customer as db_cust
*                     on it_cust~customer_id eq db_cust~customer_id
*             fields it_cust~customer_id
*             into table @data(lt_valid_customers).

    endif.

    loop at lt_bookings into data(ls_booking).

      if ls_booking-CustomerID is initial.


        append value #( %tky = ls_booking-%tky ) to failed-booking.

        append value #( %tky = ls_booking-%tky
                        %state_area = 'VALIDATE_CUSTOMER'
                        %msg = new /dmo/cm_flight_messages(
                                       textid = /dmo/cm_flight_messages=>enter_customer_id
                                       severity = if_abap_behv_message=>severity-error )
                         %path = value #( travel-%tky = travel_booking_links[ key id
                                                                              source-%tky = ls_booking-%tky ]-target-%tky )
                         %element-CustomerId = if_abap_behv=>mk-on
                         ) to reported-booking.

      elseif ls_booking-CustomerID is not initial
             and not line_exists( valid_customers[ customer_id = ls_booking-CustomerID ] ).

        append value #( %tky = ls_booking-%tky ) to failed-booking.



        append value #( %tky = ls_booking-%tky
                        %state_area = 'VALIDATE_CUSTOMER'
                        %msg = new /dmo/cm_flight_messages(
                                       customer_id = ls_booking-CustomerID
                                       textid = /dmo/cm_flight_messages=>customer_unkown
                                       severity = if_abap_behv_message=>severity-error )
                         %path = value #( travel-%tky = travel_booking_links[ key id
                                                                              source-%tky = ls_booking-%tky ]-target-%tky )
                         %element-CustomerId = if_abap_behv=>mk-on
                         ) to reported-booking.
      endif.


    endloop.


  endmethod.

endclass.
