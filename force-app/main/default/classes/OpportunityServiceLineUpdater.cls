public class OpportunityServiceLineUpdater {
    public static void updateOpportunityLines(Set<Id> oppIds) {
        if (oppIds.isEmpty()) return;

        // Fetch related Opportunities (include existing SL/SSL values)
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
            [SELECT Id, Service_Line__c, Sub_Service_Line__c FROM Opportunity WHERE Id IN :oppIds]
        );

        // Fetch related OpportunityLineItems
        Map<Id, List<OpportunityLineItem>> oliMap = new Map<Id, List<OpportunityLineItem>>();
        for (OpportunityLineItem oli : [
            SELECT OpportunityId, Service_Line__c, Sub_Service_Line__c
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIds
        ]) {
            if (!oliMap.containsKey(oli.OpportunityId)) {
                oliMap.put(oli.OpportunityId, new List<OpportunityLineItem>());
            }
            oliMap.get(oli.OpportunityId).add(oli);
        }

        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for (Id oppId : oppIds) {
            Set<String> slSet = new Set<String>();
            Set<String> sslSet = new Set<String>();

            Opportunity opp = oppMap.get(oppId);

            // Include existing Service Line values
            if (opp.Service_Line__c != null) {
                for (String s : opp.Service_Line__c.split(';')) {
                    slSet.add(s.trim());
                }
            }

            // Include existing Sub Service Line values
            if (opp.Sub_Service_Line__c != null) {
                for (String s : opp.Sub_Service_Line__c.split(';')) {
                    sslSet.add(s.trim());
                }
            }

            // Include values from line items
            if (oliMap.containsKey(oppId)) {
                for (OpportunityLineItem oli : oliMap.get(oppId)) {
                    if (oli.Service_Line__c != null) {
                        for (String s : oli.Service_Line__c.split(';')) {
                            slSet.add(s.trim());
                        }
                    }
                    if (oli.Sub_Service_Line__c != null) {
                        for (String s : oli.Sub_Service_Line__c.split(';')) {
                            sslSet.add(s.trim());
                        }
                    }
                }
            }

            // Convert sets to sorted lists to keep value order consistent (optional)
            List<String> slList = new List<String>(slSet);
            List<String> sslList = new List<String>(sslSet);

            slList.sort();
            sslList.sort();

            opp.Service_Line__c = String.join(slList, ';');
            opp.Sub_Service_Line__c = String.join(sslList, ';');

            oppsToUpdate.add(opp);
        }

        if (!oppsToUpdate.isEmpty()) {
            system.debug('oppsToUpdate--'+oppsToUpdate);
            update oppsToUpdate;
        }
    }
}