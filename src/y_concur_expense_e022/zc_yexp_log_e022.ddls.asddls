@EndUserText.label: 'ZC_YEXP_ENTRY_E022'
@Metadata.allowExtensions: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity ZC_YEXP_LOG_E022
  provider contract transactional_query
  as projection on ZR_YEXP_LOG_E022
{
  key LogUuid,
      LogCreatedOn,
      LogComments,
      LogState,
      ZTaskUuid,
      ZReportUuid,
      ZEntryUuid,
      ZCreatedBy,
      ZCreatedAt,
      ZLastChangedBy,
      ZLastChangedAt,
      ZLocalLastChangedAt,
      _expense,
      _report,
      _task
}
