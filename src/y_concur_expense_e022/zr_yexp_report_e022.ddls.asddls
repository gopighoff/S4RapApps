@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZR_YEXP_REPORT_E022'
define root view entity ZR_YEXP_REPORT_E022
  as select from yexp_report_e022
  association [1..1] to ZR_YEXP_GET_E022 as _task on $projection.ZTaskUuid = _task.ZTaskUUID
  association [0..*] to ZR_YEXP_ENTRY_E022 as _entry on $projection.ZReportUuid = _entry.ZReportUuid
  association [0..*] to ZR_YEXP_LOG_E022 as _log on $projection.ZReportUuid = _log.ZReportUuid
{
  key z_report_uuid           as ZReportUuid,
      z_task_uuid             as ZTaskUuid,
      z_report_status         as ZReportStatus,
      z_report_id             as ZReportId,
      z_report_name           as ZReportName,
      z_report_createdon      as ZReportCreatedon,
      z_report_lastchangedon  as ZReportLastchangedon,
      z_report_submittedon    as ZReportSubmittedon,
      z_owner_id              as ZOwnerId,
      z_owner_name            as ZOwnerName,
      z_report_approvalcode   as ZReportApprovalcode,
      z_report_approvalname   as ZReportApprovalname,
      z_transaction_currency  as ZTransactionCurrency,
      z_total_amt             as ZTotalAmt,
      z_total_claimed_amt     as ZTotalClaimedAmt,
      z_created_by            as ZCreatedBy,
      z_created_at            as ZCreatedAt,
      z_last_changed_by       as ZLastChangedBy,
      z_last_changed_at       as ZLastChangedAt,
      z_local_last_changed_at as ZLocalLastChangedAt,
      _task,
      _entry,
      _log
}
