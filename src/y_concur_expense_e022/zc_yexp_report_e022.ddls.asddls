@EndUserText.label: 'ZC_YEXP_REPORT_E022'
@Metadata.allowExtensions: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity ZC_YEXP_REPORT_E022
  provider contract transactional_query
  as projection on ZR_YEXP_REPORT_E022
{
  key ZReportUuid,
      ZTaskUuid,
      ZReportStatus,
      ZReportId,
      ZReportName,
      ZReportCreatedon,
      ZReportLastchangedon,
      ZReportSubmittedon,
      ZOwnerId,
      ZOwnerName,
      ZReportApprovalcode,
      ZReportApprovalname,
      ZTransactionCurrency,
      ZTotalAmt,
      ZTotalClaimedAmt,
      ZCreatedBy,
      ZCreatedAt,
      ZLastChangedBy,
      ZLastChangedAt,
      ZLocalLastChangedAt,
      _task  : redirected to ZC_YEXP_GET_E022,
      _entry : redirected to ZC_YEXP_ENTRY_E022,
      _log   : redirected to ZC_YEXP_LOG_E022
}
