@EndUserText.label: 'HR - Interface'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity zi_hr_prim00
  provider contract transactional_interface
  as projection on zr_hr_prim00
{
  key ENumber,
      EName,
      EDepartment,
      Status,
      JobTitle,
      StartDate,
      EndDate,
      Email,
      MNumber,
      MName,
      MDepartment,
      CreaDateTime,
      CreaUname,
      LchgDateTime,
      LchgUname
}
