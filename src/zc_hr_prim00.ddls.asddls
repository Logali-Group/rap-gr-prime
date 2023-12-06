@EndUserText.label: 'HR - Consumption'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity zc_hr_prim00
  provider contract transactional_query
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
