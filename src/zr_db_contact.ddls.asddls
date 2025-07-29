@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: '###GENERATED Core Data Service Entity'
define root view entity ZR_DB_CONTACT
  as select from ZDB_CONTACT
{
  key contactuuid as Contactuuid,
  contactid as Contactid,
  contactname as Contactname,
  @Semantics.user.createdBy: true
  createdby as Createdby,
  @Semantics.systemDateTime.createdAt: true
  createdat as Createdat,
  @Semantics.user.localInstanceLastChangedBy: true
  lastchangedby as Lastchangedby,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  lastchangedat as Lastchangedat,
  @Semantics.systemDateTime.lastChangedAt: true
  locallastchangedat as Locallastchangedat
  
}
