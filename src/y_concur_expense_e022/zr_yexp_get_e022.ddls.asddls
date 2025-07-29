@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: '##GENERATED YEXP_GET_E022'
define root view entity ZR_YEXP_GET_E022
  as select from yexp_get_e022
  association [0..*] to ZR_YEXP_REPORT_E022 as _report on $projection.ZTaskUUID = _report.ZTaskUuid
  association [0..*] to ZR_YEXP_LOG_E022 as _log on $projection.ZTaskUUID = _log.ZTaskUuid
{
  key z_task_uuid             as ZTaskUUID,
      z_task_id               as ZTaskID,
      z_filter_by             as ZFilterBy,
      z_task_process_step     as ZTaskProcessStep,
      z_report_id             as ZReportID,
      z_filter_to             as ZFilterTo,
      z_filter_from           as ZFilterFrom,
      z_task_status           as ZTaskStatus,
      @Semantics.user.createdBy: true
      z_created_by            as ZCreatedBy,
      @Semantics.systemDateTime.createdAt: true
      z_created_at            as ZCreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      z_last_changed_by       as ZLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      z_last_changed_at       as ZLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      z_local_last_changed_at as ZLocalLastChangedAt,
      _report,
      _log

}
