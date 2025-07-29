@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: 'Projection View for ZR_YCONFIG_E022'
define root view entity ZC_YCONFIG_E022
  provider contract transactional_query
  as projection on ZR_YCONFIG_E022
{
  key ZUUID,
  ZClientID,
  ZClientSecret,
  ZGrantType,
  ZRefreshToken,
  ZStatuscode,
  ZLastChangedAt
  
}
