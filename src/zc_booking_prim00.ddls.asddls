@EndUserText.label: 'Booking - Consumption'
@AccessControl.authorizationCheck: #NOT_REQUIRED

@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: [ 'BookingID' ]

define view entity zc_booking_prim00
  as projection on zr_booking_prim00
{
  key BookingUUID,
      TravelUUID,
      
      @Search.defaultSearchElement: true
      BookingID,
      BookingDate,
      
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: [ 'CustomerName' ]
      CustomerID,
      _Customer.LastName as CustomerName,
      
      @ObjectModel.text.element: [ 'CarrierName' ]
      AirlineID,
      _Carrier.Name as CarrierName, 
      ConnectionID,
      FlightDate,
      FlightPrice,
      CurrencyCode,
      
      @ObjectModel.text.element: [ 'BookingStatusText' ]
      BookingStatus,
      _BookingStatus._Text.Text as BookingStatusText : localized,
      
      LocalLastChangedAt,
      
      /* Associations */
      _BookingStatus,
      _Carrier,
      _Connection,
      _Customer,
      _Travel : redirected to parent zc_travel_prim00
}
