@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZR_YEXP_ENTRY_E022'
define root view entity ZR_YEXP_ENTRY_E022
  as select from yexp_entry_e022
  association [1..1] to ZR_YEXP_REPORT_E022 as _report on $projection.ZReportUuid = _report.ZReportUuid
  association [0..*] to ZR_YEXP_LOG_E022 as _log on $projection.ZEntryUuid = _log.ZEntryUuid
{
  key z_entry_uuid               as ZEntryUuid,
      z_report_uuid              as ZReportUuid,
      z_report_id                as ZReportId,
      z_entry_id                 as ZEntryId,
      z_entry_status             as ZEntryStatus,
      z_entry_description        as ZEntryDescription,
      z_entry_typecode           as ZEntryTypecode,
      z_entry_typename           as ZEntryTypename,
      z_entry_spend_categorycode as ZEntrySpendCategorycode,
      z_entry_spend_categoryname as ZEntrySpendCategoryname,
      z_entry_transaction_date   as ZEntryTransactionDate,
      z_entry_transaction_curr   as ZEntryTransactionCurr,
      z_entry_transaction_amt    as ZEntryTransactionAmt,
      z_entry_approved_amt       as ZEntryApprovedAmt,
      z_entry_last_modified      as ZEntryLastModified,
      z_entry_vendor_description as ZEntryVendorDescription,
      z_supplier_invoice_id      as ZSupplierInvoiceId,
      z_supplier_invoice_fiscal  as zsupplierinvoicefiscal,
      z_created_by               as ZCreatedBy,
      z_created_at               as ZCreatedAt,
      z_last_changed_by          as ZLastChangedBy,
      z_last_changed_at          as ZLastChangedAt,
      z_local_last_changed_at    as ZLocalLastChangedAt,
      _report,
      _log
}
