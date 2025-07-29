@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: 'Projection View for ZR_YEXP_GET_E022'
define root view entity ZC_YEXP_GET_E022
  provider contract transactional_query
  as projection on ZR_YEXP_GET_E022
{
  key ZTaskUUID,
  ZTaskID,
  ZFilterBy,
  ZTaskStatus,
  ZTaskProcessStep,
  ZReportID,
  ZFilterFrom,
  ZFilterTo,
  ZLastChangedAt,
  _report: redirected to ZC_YEXP_REPORT_E022,
  _log: redirected to ZC_YEXP_LOG_E022
  
}
