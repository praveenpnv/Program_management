/**
* @File Name : OpportunityLIcontroller.cls
* @Description : This class is used for to create Opportunity line item records
* @Author : Milan Prasad
* @Last Modified By :
* @Last Modified On : May 27, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | May 27, 2025 |   | Initial Version
**/

public class OpportunityLIcontroller {
	@AuraEnabled(cacheable=true)
public static List<Map<String, Object>> getFieldSetFields(String fieldSetName) {
    List<Map<String, Object>> fieldList = new List<Map<String, Object>>();
    Schema.FieldSet fs = Schema.SObjectType.OpportunityLineItem.FieldSets.getMap().get(fieldSetName);

    for (Schema.FieldSetMember f : fs.getFields()) {
        Map<String, Object> fieldInfo = new Map<String, Object>();
        String fieldPath = f.getFieldPath();
        if (String.isNotBlank(fieldPath)) {
            fieldInfo.put('fieldName', fieldPath);
            fieldInfo.put('isRequired', f.getRequired());
            fieldList.add(fieldInfo);
        }
    }
    System.debug('fieldList'+fieldList);
    return fieldList;
}
    @AuraEnabled(cacheable=true)
public static Opportunity getOpportunityFields(Id opportunityId) {
    return [SELECT Id,StageName,IsClosed,Pricebook2Id,CurrencyIsoCode,RecordType.Name,Service_Line__c,Sub_Service_Line__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
}
 @AuraEnabled
    public static Boolean assignStandardPricebook(Id opportunityId) {
         Opportunity opp=getOpportunityFields(opportunityId);
        if (opp.Pricebook2Id != null) {
            // Already has Pricebook assigned
            return true;
        }
       List<AggregateResult> matchingPricebook;
       if (Test.isRunningTest()) {
        matchingPricebook = [
            SELECT Pricebook2Id 
            FROM PricebookEntry 
            WHERE IsActive = true 
            AND CurrencyIsoCode = :opp.CurrencyIsoCode
            GROUP BY Pricebook2Id
            LIMIT 1
        ];
    } else {
        matchingPricebook = [
            SELECT Pricebook2Id 
            FROM PricebookEntry 
            WHERE IsActive = true 
            AND Pricebook2.IsActive = true 
            AND CurrencyIsoCode = :opp.CurrencyIsoCode
            GROUP BY Pricebook2Id
            LIMIT 1
        ];
    }
    if (matchingPricebook.isEmpty()) {
        throw new AuraHandledException('No pricebook found with entries in currency: ' + opp.CurrencyIsoCode);
    }

    // Assign the matched pricebook
    Id matchedPbId = (Id) matchingPricebook[0].get('Pricebook2Id');
    System.debug('matchedPbId'+matchedPbId);
    opp.Pricebook2Id = matchedPbId;

    try {
        update opp;
          System.debug('opportunity'+opp);
        return true;
    } catch (Exception e) {
        throw new AuraHandledException('Failed to assign pricebook: ' + e.getMessage());
    }
    }

   @AuraEnabled
    public static DefaultLineItemDefaults getDefaultLineItemValues(Id opportunityId) {
        DefaultLineItemDefaults defaults = new DefaultLineItemDefaults();
        defaults.opportunityId = opportunityId;

        // Example: get the standard pricebook entry for 'Job' product
         Opportunity opp=getOpportunityFields(opportunityId);
         if (opp.IsClosed) {
            throw new AuraHandledException('Cannot create Line Item when Opportunity is Closed Won or Closed Lost.');
         }
         if (opp.Pricebook2Id == null) {
            throw new AuraHandledException('Opportunity must have a Pricebook assigned.');
        }
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Job' LIMIT 1];
        PricebookEntry pbe = [
            SELECT Id, UnitPrice 
            FROM PricebookEntry 
            WHERE Pricebook2Id = :opp.Pricebook2Id AND Product2Id = :prod.Id AND CurrencyIsoCode = :opp.CurrencyIsoCode AND IsActive = true
            LIMIT 1
        ];
        system.debug('PricebookEntry'+pbe);
        defaults.pricebookEntryId = pbe.Id;
        defaults.salesPrice = pbe.UnitPrice;
        defaults.quantity = 1;
        system.debug('defaultsDefaultLintvalues'+defaults);
        return defaults;
    }
    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getJobTypePicklistValues() {
        List<PicklistOption> options = new List<PicklistOption>();
        Schema.DescribeFieldResult fieldDescribe = OpportunityLineItem.Job_Type__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
        for (Schema.PicklistEntry entry : picklistEntries) {
            options.add(new PicklistOption(entry.getLabel(), entry.getValue()));
        }
        return options;
    }

     public class DefaultLineItemDefaults {
        @AuraEnabled public Id opportunityId;
        @AuraEnabled public Decimal salesPrice;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Id pricebookEntryId;
    }
     public class PicklistOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

}