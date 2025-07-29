@EndUserText.label: 'ZC_YEXP_ENTRY_E022'
@Metadata.allowExtensions: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity ZC_YEXP_ENTRY_E022
  provider contract transactional_query
  as projection on ZR_YEXP_ENTRY_E022
{
  key ZEntryUuid,
      ZReportUuid,
      ZReportId,
      ZEntryId,
      ZEntryStatus,
      ZEntryDescription,
      ZEntryTypecode,
      ZEntryTypename,
      ZEntrySpendCategorycode,
      ZEntrySpendCategoryname,
      ZEntryTransactionDate,
      ZEntryTransactionCurr,
      ZEntryTransactionAmt,
      ZEntryApprovedAmt,
      ZEntryLastModified,
      ZEntryVendorDescription,
      ZSupplierInvoiceId,
      zsupplierinvoicefiscal,
      ZCreatedBy,
      ZCreatedAt,
      ZLastChangedBy,
      ZLastChangedAt,
      ZLocalLastChangedAt,
      _report : redirected to ZC_YEXP_REPORT_E022,
      _log    : redirected to ZC_YEXP_LOG_E022
}
