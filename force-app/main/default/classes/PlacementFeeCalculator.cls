/**
* @File Name         : PlacementFeeCalculator.cls
* @Description       : This Apex class contains logic to calculate the fee percentage on the Closing Report based on the flat placement fee and the candidate’s salary.				   
* @Author            : Rizwan Ahmed
* @Last Modified By  : Rizwan Ahmed
* @Created On		 : Jun 14, 2025
* @Last Modified On  : Jul 16, 2025
* @Modification Log  :
*/
public class PlacementFeeCalculator {

    // For insert – no oldMap
    public static void beforeInsertOrUpdate(List<TR1__Closing_Report__c> records) {
        beforeInsertOrUpdate(records, new Map<Id, TR1__Closing_Report__c>());
    }

    // Main method for update – uses oldMap
    public static void beforeInsertOrUpdate(
        List<TR1__Closing_Report__c> newList,
        Map<Id, TR1__Closing_Report__c> oldMap
    ) {
        for (TR1__Closing_Report__c newRec : newList) {
            TR1__Closing_Report__c oldRec = oldMap != null ? oldMap.get(newRec.Id) : null;

            if (newRec.TR1__Salary__c != null) {
                Boolean flatFeeChanged = oldRec == null || newRec.Placement_Fee_Flat__c != oldRec.Placement_Fee_Flat__c;
                Boolean percentChanged = oldRec == null || newRec.TR1__Fee_Percentage__c != oldRec.TR1__Fee_Percentage__c;

                // Flat Fee changed (not null), calculate %
                if (flatFeeChanged && newRec.Placement_Fee_Flat__c != null) {
                    newRec.TR1__Fee_Percentage__c = (newRec.Placement_Fee_Flat__c / newRec.TR1__Salary__c) * 100;
                }
                // % changed, and Flat Fee is blank => calculate Flat Fee
                else if (percentChanged && newRec.TR1__Fee_Percentage__c != null) {
                    newRec.Placement_Fee_Flat__c = newRec.TR1__Salary__c * (newRec.TR1__Fee_Percentage__c / 100);
                }

            }
        }
    }
}