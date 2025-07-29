@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: '##GENERATED YCONFIG_E022'
define root view entity ZR_YCONFIG_E022
  as select from yconfig_e022
{
  key z_uuid as ZUUID,
  z_client_id as ZClientID,
  z_client_secret as ZClientSecret,
  z_grant_type as ZGrantType,
  z_statuscode as ZStatuscode,
  z_refresh_token as ZRefreshToken,
  @Semantics.user.createdBy: true
  z_created_by as ZCreatedBy,
  @Semantics.systemDateTime.createdAt: true
  z_created_at as ZCreatedAt,
  @Semantics.user.localInstanceLastChangedBy: true
  z_last_changed_by as ZLastChangedBy,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  z_last_changed_at as ZLastChangedAt,
  @Semantics.systemDateTime.lastChangedAt: true
  z_local_last_changed_at as ZLocalLastChangedAt
  
}
