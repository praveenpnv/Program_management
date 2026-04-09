public class PlacementTriggerHandller {
    public static void validateMinimumWage(List<TR1__Closing_Report__c> placementList) {
        Set<String> stateCodes = new Set<String>();
        Set<String> countryCodes = new Set<String>();
        Set<String> opcoNames = new Set<String>();
        
        for (TR1__Closing_Report__c placement : placementList) {
            system.debug('placementList'+placementList);
            String recordTypeName = Schema.SObjectType.TR1__Closing_Report__c.getRecordTypeInfosById().get(placement.RecordTypeId).getDeveloperName();
             system.debug('recordTypeName'+recordTypeName);
            if (recordTypeName == 'Consulting' || recordTypeName == 'Change_Request' || recordTypeName == 'Solutions'){
                if (placement.Line_of_Business__c == 'RD') {
                    system.debug('placement1'+placement.Worksite_Address__StateCode__s);
                    if (String.isNotBlank(placement.Worksite_Address__StateCode__s)) {
                        stateCodes.add(placement.Worksite_Address__StateCode__s);
                    }
                    if (String.isNotBlank(placement.Worksite_Address__CountryCode__s)) {
                        countryCodes.add(placement.Worksite_Address__CountryCode__s);
                    }
                    if (String.isNotBlank(placement.Responsible_Opco__c)) {
                        opcoNames.add(placement.Responsible_Opco__c);
                    }
                }
            }
        }
        
        if (stateCodes.isEmpty() || countryCodes.isEmpty() || opcoNames.isEmpty()) {
            return;
        }
        
        Map<String, Decimal> stateWageMap = new Map<String, Decimal>();
        List<Minimum_Wage_Config__mdt> wageRecords = [
            SELECT State__c, Country__c, Opco__c, Min_Wage_Placement__c 
            FROM Minimum_Wage_Config__mdt
            WHERE State__c IN :stateCodes 
            AND Country__c IN :countryCodes
            AND Opco__c IN :opcoNames
        ];
        System.debug('wageRecords'+wageRecords);
        for (Minimum_Wage_Config__mdt wage : wageRecords) {
            if (String.isNotBlank(wage.Min_Wage_Placement__c)) {
                try {
                    Decimal minWage = Decimal.valueOf(wage.Min_Wage_Placement__c.replace(',', '.'));
                    String key = wage.Opco__c + '_' + wage.Country__c + '_' + wage.State__c;
                    stateWageMap.put(key, minWage);
                    System.debug('stateWageMap'+stateWageMap);
                } catch (Exception e) {
                    System.debug('Error converting Min_Wage__c to Decimal: ' + e.getMessage());
                }
            } else {
                System.debug('Min_Wage__c is Blank for ' + wage.Opco__c);
            }
        }
        
        Set<String> cpeStates = new Set<String>{'CO', 'CA', 'WA'};
            Set<String> excludedStates = new Set<String>{'MN', 'PA', 'HI', 'CT', 'NV', 'ME'};  
                
                
                for (TR1__Closing_Report__c placement : placementList) {
                    System.debug('placement 3'+placement);
                    String stateCode = placement.Worksite_Address__StateCode__s;   
                    if (placement.Line_of_Business__c == 'RD'
                        && String.isNotBlank(placement.Worksite_Address__StateCode__s)
                        && String.isNotBlank(placement.Worksite_Address__CountryCode__s)
                        && String.isNotBlank(placement.Responsible_Opco__c)) {
                            
                            String key = placement.Responsible_Opco__c + '_' +           
                                placement.Worksite_Address__CountryCode__s + '_' +
                                placement.Worksite_Address__StateCode__s;
                            
                            if (stateWageMap.containsKey(key)) {
                                Decimal minWage = stateWageMap.get(key);
                                
                                System.debug('minWage 3'+minWage);
                                
                                
                                
                                if(placement.Exempt_or_NonExempt__c != 'NonExempt'&& placement.Employee_Type__c=='W2 Employee'){
                                    if (cpeStates.contains(stateCode)) {
                                        // Pay rate must be >= configured minimum
                                        if (placement.TR1__Pay_Rate__c < minWage) {
                                            System.debug('minWage 4'+minWage);
                                            placement.addError('TR1__Pay_Rate__c',
                                                               String.format(System.Label.Placement_PayRate_Error, 
                                                                             new List<Object>{placement.Worksite_Address__StateCode__s, minWage}));
                                        }
                                        
                                    }else if(!excludedStates.contains(stateCode)){
                                        if (placement.TR1__Pay_Rate__c < minWage) {
                                            System.debug('minWage 4'+minWage);
                                            placement.addError('TR1__Pay_Rate__c',
                                                               String.format(System.Label.Placement_PayRate_Error, 
                                                                             new List<Object>{placement.Worksite_Address__StateCode__s, minWage}));
                                        }
                                        
                                    }
                                }
                                
                            }
                            system.debug('excludedStates'+excludedStates);
                            if(excludedStates.contains(stateCode))
                            {
                                system.debug('stateCode'+stateCode);
                                if(placement.Exempt_or_NonExempt__c == 'Exempt'){
                                    placement.addError('Exempt_or_NonExempt__c',
                                                       String.format(System.Label.Placement_Non_Exempt_Error, 
                                                                     new List<Object>{placement.Worksite_Address__StateCode__s}));
                                }
                            }
                            if ((placement.Double_Time_Pay_Rate_US__c != placement.TR1__Pay_Rate__c || placement.Overtime_Pay_Rate_US__c != placement.TR1__Pay_Rate__c) && (placement.Exempt_or_NonExempt__c != 'NonExempt'&& placement.Employee_Type__c=='W2 Employee')) {
                                placement.addError('Double_Time_Pay_Rate_US__c', System.Label.Placement_Overtime_and_Doubletime_Error);
                                placement.addError('Overtime_Pay_Rate_US__c', System.Label.Placement_Overtime_and_Doubletime_Error);
                            }
                        }
                }
    }
}