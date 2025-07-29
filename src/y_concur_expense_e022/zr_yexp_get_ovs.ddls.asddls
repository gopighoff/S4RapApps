@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Domain Read'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZR_YEXP_GET_OVS 
       as select from DDCDS_CUSTOMER_DOMAIN_VALUE_T( p_domain_name: 'Y_CONCUR_EXPENSE') {
  @UI.hidden: true
  key domain_name,
      @UI.hidden: true
  key value_position,
      @UI.hidden: true
      @Semantics.language: true
  key language,
      value_low,
      @Semantics.text: true
      text
}
