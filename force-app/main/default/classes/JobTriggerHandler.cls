public class JobTriggerHandler {
    public static void validateMinimumWage(List<TR1__Job__c> jobList) {
        Set<String> stateCodes = new Set<String>();
        Set<String> countryCodes = new Set<String>();
        Set<String> opcoNames = new Set<String>();

        for (TR1__Job__c job : jobList) {
            if (job.TR1__Status__c == 'Accepting Candidates') {
                if (String.isNotBlank(job.Worksite_Address__StateCode__s)) {
                    stateCodes.add(job.Worksite_Address__StateCode__s);
                }
                if (String.isNotBlank(job.Worksite_Address__CountryCode__s)) {
                    countryCodes.add(job.Worksite_Address__CountryCode__s);
                }
                if (String.isNotBlank(job.Responsible_Opco__c)) {
                    opcoNames.add(job.Responsible_Opco__c);
                }
            }
        }
        
        if (stateCodes.isEmpty() || countryCodes.isEmpty() || opcoNames.isEmpty()) {
            return;
        }

        Decimal minDeltaOverMinWage = 1;
        List<Wage_Rule_Setting__mdt> ruleSettings = [
            SELECT Min_Delta_Over_Min_Wage__c 
            FROM Wage_Rule_Setting__mdt 
            LIMIT 1
        ];
        if (!ruleSettings.isEmpty() && ruleSettings[0].Min_Delta_Over_Min_Wage__c != null) {
            minDeltaOverMinWage = ruleSettings[0].Min_Delta_Over_Min_Wage__c;
        }

        Map<String, Decimal> stateWageMap = new Map<String, Decimal>();
        List<Minimum_Wage_Config__mdt> wageRecords = [
            SELECT State__c, Country__c, Opco__c, Min_Wage__c 
            FROM Minimum_Wage_Config__mdt
            WHERE State__c IN :stateCodes 
              AND Country__c IN :countryCodes
              AND Opco__c IN :opcoNames
        ];
        for (Minimum_Wage_Config__mdt wage : wageRecords) {
            if (String.isNotBlank(wage.Min_Wage__c)) {
                try {
                    Decimal minWage = Decimal.valueOf(wage.Min_Wage__c.replace(',', '.'));
                    String key = wage.Opco__c + '_' + wage.Country__c + '_' + wage.State__c;
                    stateWageMap.put(key, minWage);
                } catch (Exception e) {
                    System.debug('Error converting Min_Wage__c to Decimal: ' + e.getMessage());
                }
            } else {
                System.debug('Min_Wage__c is Blank for ' + wage.Opco__c);
            }
        }
        Id permanentRecordTypeId = Schema.SObjectType.TR1__Job__c.getRecordTypeInfosByName().get('Permanent').getRecordTypeId();

        for (TR1__Job__c job : jobList) {
            if (job.TR1__Status__c == 'Accepting Candidates'
                && String.isNotBlank(job.Worksite_Address__StateCode__s)
                && String.isNotBlank(job.Worksite_Address__CountryCode__s)
                && String.isNotBlank(job.Responsible_Opco__c)) {
            if (job.RecordTypeId != permanentRecordTypeId) {
                //  Mandatory Field Validation
                if (job.TR1__Minimum_Pay_Rate__c == null) {
                    job.addError('TR1__Minimum_Pay_Rate__c', System.Label.MinPayRateRequired);
                }
                if (job.TR1__Maximum_Pay_Rate__c == null) {
                    job.addError('TR1__Maximum_Pay_Rate__c', System.Label.MaxPayRateRequired);
                }
}
                // Skip further checks if either field is missing
                if (job.TR1__Minimum_Pay_Rate__c == null || job.TR1__Maximum_Pay_Rate__c == null) {
                    continue;
                }

                String key = job.Responsible_Opco__c + '_' +
                             job.Worksite_Address__CountryCode__s + '_' +
                             job.Worksite_Address__StateCode__s;

                if (stateWageMap.containsKey(key)) {
                    Decimal minWage = stateWageMap.get(key);

                    // Minimum rate must be >= configured minimum
                    if (job.TR1__Minimum_Pay_Rate__c < minWage) {
                        job.addError('TR1__Minimum_Pay_Rate__c',
                            String.format(System.Label.MinPayRate_Error, 
                            new List<Object>{job.TR1__Minimum_Pay_Rate__c, minWage}));
                    }

                    // Max should be > min
                    if (job.TR1__Maximum_Pay_Rate__c <= job.TR1__Minimum_Pay_Rate__c) {
                        job.addError('TR1__Maximum_Pay_Rate__c',
                            String.format(System.Label.MaxPayRate_Error, 
                            new List<Object>{job.TR1__Maximum_Pay_Rate__c, job.TR1__Minimum_Pay_Rate__c}));
                    }

                    // Max should be at least $1 more than min
                    Decimal expectedMinMaxRate = job.TR1__Minimum_Pay_Rate__c + minDeltaOverMinWage;
                    if (job.TR1__Maximum_Pay_Rate__c < expectedMinMaxRate) {
                         job.addError('TR1__Maximum_Pay_Rate__c',
                            String.format(System.Label.MaxRateMinDeltaError,
                            new List<Object>{minDeltaOverMinWage}));
                    }
                }
            }
        }
    }
}