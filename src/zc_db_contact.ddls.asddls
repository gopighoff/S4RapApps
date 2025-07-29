@Metadata.allowExtensions: true
@EndUserText.label: '###GENERATED Core Data Service Entity'
@AccessControl.authorizationCheck: #CHECK
define root view entity ZC_DB_CONTACT
  provider contract TRANSACTIONAL_QUERY
  as projection on ZR_DB_CONTACT
{
  key Contactuuid,
  Contactid,
  Contactname,
  Createdby,
  Createdat,
  Lastchangedby,
  Lastchangedat,
  Locallastchangedat
  
}
