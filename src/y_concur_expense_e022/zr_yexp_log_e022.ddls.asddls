@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZR_YEXP_LOG_E022'
define root view entity ZR_YEXP_LOG_E022
  as select from yexp_log_e022
  association [1..1] to ZR_YEXP_GET_E022    as _task    on $projection.ZTaskUuid = _task.ZTaskUUID
  association [1..1] to ZR_YEXP_REPORT_E022 as _report  on $projection.ZReportUuid = _report.ZReportUuid
  association [1..1] to ZR_YEXP_ENTRY_E022  as _expense on $projection.ZEntryUuid = _expense.ZEntryUuid
{
  key log_uuid                as LogUuid,
      log_created_on          as LogCreatedOn,
      log_comments            as LogComments,
      log_state               as LogState,
      z_task_uuid             as ZTaskUuid,
      z_report_uuid           as ZReportUuid,
      z_entry_uuid            as ZEntryUuid,
      z_created_by            as ZCreatedBy,
      z_created_at            as ZCreatedAt,
      z_last_changed_by       as ZLastChangedBy,
      z_last_changed_at       as ZLastChangedAt,
      z_local_last_changed_at as ZLocalLastChangedAt,
      _expense,
      _report,
      _task
}
