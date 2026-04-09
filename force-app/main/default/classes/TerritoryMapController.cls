/**
 * TerritoryMapController
 * Implements FR-21, FR-22, FR-23: Backend services for territory map visualization
 * Supports both Region__c and Territory2 integration
 */
public with sharing class TerritoryMapController {
    
    /**
     * FR-21: Region Data Service
     * Get all active regions with GeoJSON boundaries
     */
    @AuraEnabled(cacheable=true)
    public static List<RegionWrapper> getActiveRegions() {
        try {
            List<Region__c> regions = [
                SELECT Id, Region_Label__c, Region_Type__c, State_Code__c,
                       GeoJSON_Boundary__c, Center_Latitude__c, Center_Longitude__c,
                       Border_Color__c, Fill_Color__c, Fill_Opacity__c,
                       Territory_ID__c, Status__c
                FROM Region__c
                WHERE Status__c = 'Active'
                WITH SECURITY_ENFORCED
                ORDER BY Region_Label__c ASC
            ];
            
            List<RegionWrapper> wrappers = new List<RegionWrapper>();
            for (Region__c region : regions) {
                RegionWrapper wrapper = new RegionWrapper();
                wrapper.Id = region.Id;
                wrapper.Name = region.Region_Label__c;
                wrapper.RegionType = region.Region_Type__c;
                wrapper.StateCode = region.State_Code__c;
                wrapper.GeoJSONBoundary = region.GeoJSON_Boundary__c;
                wrapper.CenterLat = region.Center_Latitude__c;
                wrapper.CenterLng = region.Center_Longitude__c;
                wrapper.BorderColor = region.Border_Color__c != null ? region.Border_Color__c : '#3388ff';
                wrapper.FillColor = region.Fill_Color__c != null ? region.Fill_Color__c : '#3388ff';
                wrapper.FillOpacity = region.Fill_Opacity__c != null ? region.Fill_Opacity__c / 100 : 0.25;
                wrapper.TerritoryId = region.Territory_ID__c;
                wrapper.Status = region.Status__c;
                wrappers.add(wrapper);
            }
            
            return wrappers;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching regions: ' + e.getMessage());
        }
    }
    
    /**
     * FR-22: Region-Based Record Service
     * FR-10, FR-11: Region-based job/account filtering
     * Get jobs or accounts for selected region
     */
    @AuraEnabled(cacheable=true)
    public static List<RecordWrapper> getRecordsByRegion(Id regionId, String objectType) {
        try {
            if (objectType == 'Job') {
                return getJobsByRegion(regionId);
            } else if (objectType == 'Account') {
                return getAccountsByRegion(regionId);
            } else if (objectType == 'Opportunity') {
                return getOpportunitiesByRegion(regionId);
            }
            throw new AuraHandledException('Unsupported object type: ' + objectType);
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching records: ' + e.getMessage());
        }
    }
    
    /**
     * Get jobs mapped to region via address matching
     * FR-24: Address-based region mapping
     * Using Opportunity as "Jobs" for recruiting
     */
    private static List<RecordWrapper> getJobsByRegion(Id regionId) {
        Region__c region = [
            SELECT Id, State_Code__c, FIPS_Code__c, Territory_ID__c
            FROM Region__c 
            WHERE Id = :regionId 
            LIMIT 1
        ];
        
        // For Jobs, we'll use Opportunities as job requisitions
        // Get accounts in this territory first
        Set<Id> accountIds = new Set<Id>();
        if (String.isNotBlank(region.Territory_ID__c)) {
            for (ObjectTerritory2Association ota : [
                SELECT ObjectId 
                FROM ObjectTerritory2Association
                WHERE Territory2Id = :region.Territory_ID__c
                AND IsDeleted = false
            ]) {
                accountIds.add(ota.ObjectId);
            }
        }
        
        // Query opportunities (representing job requisitions)
        List<Opportunity> jobs = [
            SELECT Id, Name, StageName, Type, CloseDate, Amount,
                   Owner.Name, Account.Name, Account.BillingLatitude, 
                   Account.BillingLongitude
            FROM Opportunity
            WHERE AccountId IN :accountIds
            AND IsClosed = false
            AND Account.BillingLatitude != null
            AND Account.BillingLongitude != null
            WITH SECURITY_ENFORCED
            ORDER BY CloseDate ASC
            LIMIT 100
        ];
        
        List<RecordWrapper> wrappers = new List<RecordWrapper>();
        for (Opportunity job : jobs) {
            RecordWrapper wrapper = new RecordWrapper();
            wrapper.Id = job.Id;
            wrapper.Name = job.Name;
            wrapper.Status = job.StageName;
            wrapper.Priority = determinePriority(job.CloseDate, job.Amount);
            wrapper.Latitude = job.Account.BillingLatitude;
            wrapper.Longitude = job.Account.BillingLongitude;
            wrapper.OwnerName = job.Owner.Name;
            wrapper.DueDate = job.CloseDate;
            wrapper.AccountName = job.Account.Name;
            wrapper.IsOverdue = job.CloseDate != null && job.CloseDate < Date.today();
            wrappers.add(wrapper);
        }
        
        return wrappers;
    }
    
    /**
     * Get accounts via territory association
     */
    private static List<RecordWrapper> getAccountsByRegion(Id regionId) {
        Region__c region = [
            SELECT Id, Territory_ID__c 
            FROM Region__c 
            WHERE Id = :regionId 
            LIMIT 1
        ];
        
        if (String.isBlank(region.Territory_ID__c)) {
            return new List<RecordWrapper>();
        }
        
        Set<Id> accountIds = new Set<Id>();
        for (ObjectTerritory2Association ota : [
            SELECT ObjectId 
            FROM ObjectTerritory2Association
            WHERE Territory2Id = :region.Territory_ID__c
            AND IsDeleted = false
        ]) {
            accountIds.add(ota.ObjectId);
        }
        
        List<Account> accounts = [
            SELECT Id, Name, Type, Industry, Owner.Name,
                   BillingCity, BillingState, BillingLatitude, BillingLongitude
            FROM Account
            WHERE Id IN :accountIds
            AND BillingLatitude != null
            AND BillingLongitude != null
            WITH SECURITY_ENFORCED
            ORDER BY Name ASC
            LIMIT 100
        ];
        
        List<RecordWrapper> wrappers = new List<RecordWrapper>();
        for (Account acc : accounts) {
            RecordWrapper wrapper = new RecordWrapper();
            wrapper.Id = acc.Id;
            wrapper.Name = acc.Name;
            wrapper.Status = acc.Type;
            wrapper.Priority = 'Normal';
            wrapper.Latitude = acc.BillingLatitude;
            wrapper.Longitude = acc.BillingLongitude;
            wrapper.OwnerName = acc.Owner.Name;
            wrapper.AccountName = acc.Name;
            wrappers.add(wrapper);
        }
        
        return wrappers;
    }
    
    /**
     * Get opportunities for region
     */
    private static List<RecordWrapper> getOpportunitiesByRegion(Id regionId) {
        Region__c region = [
            SELECT Id, Territory_ID__c 
            FROM Region__c 
            WHERE Id = :regionId 
            LIMIT 1
        ];
        
        if (String.isBlank(region.Territory_ID__c)) {
            return new List<RecordWrapper>();
        }
        
        Set<Id> accountIds = new Set<Id>();
        for (ObjectTerritory2Association ota : [
            SELECT ObjectId 
            FROM ObjectTerritory2Association
            WHERE Territory2Id = :region.Territory_ID__c
        ]) {
            accountIds.add(ota.ObjectId);
        }
        
        List<Opportunity> opps = [
            SELECT Id, Name, StageName, Type, CloseDate, Amount,
                   Owner.Name, Account.Name, Account.BillingLatitude, Account.BillingLongitude
            FROM Opportunity
            WHERE AccountId IN :accountIds
            AND IsClosed = false
            AND Account.BillingLatitude != null
            WITH SECURITY_ENFORCED
            ORDER BY CloseDate ASC
            LIMIT 100
        ];
        
        List<RecordWrapper> wrappers = new List<RecordWrapper>();
        for (Opportunity opp : opps) {
            RecordWrapper wrapper = new RecordWrapper();
            wrapper.Id = opp.Id;
            wrapper.Name = opp.Name;
            wrapper.Status = opp.StageName;
            wrapper.Priority = determinePriority(opp.CloseDate, opp.Amount);
            wrapper.Latitude = opp.Account.BillingLatitude;
            wrapper.Longitude = opp.Account.BillingLongitude;
            wrapper.OwnerName = opp.Owner.Name;
            wrapper.AccountName = opp.Account.Name;
            wrapper.DueDate = opp.CloseDate;
            wrapper.IsOverdue = opp.CloseDate < Date.today();
            wrappers.add(wrapper);
        }
        
        return wrappers;
    }
    
    /**
     * FR-12: Region KPI Display
     * Calculate KPIs for selected region
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getRegionKPIs(Id regionId, String objectType) {
        try {
            Map<String, Object> kpis = new Map<String, Object>();
            
            if (objectType == 'Job') {
                kpis = calculateJobKPIs(regionId);
            } else if (objectType == 'Account') {
                kpis = calculateAccountKPIs(regionId);
            } else if (objectType == 'Opportunity') {
                kpis = calculateOpportunityKPIs(regionId);
            }
            
            return kpis;
        } catch (Exception e) {
            throw new AuraHandledException('Error calculating KPIs: ' + e.getMessage());
        }
    }
    
    private static Map<String, Object> calculateJobKPIs(Id regionId) {
        Region__c region = [SELECT State_Code__c, Territory_ID__c FROM Region__c WHERE Id = :regionId LIMIT 1];
        
        Set<Id> accountIds = new Set<Id>();
        if (String.isNotBlank(region.Territory_ID__c)) {
            for (ObjectTerritory2Association ota : [
                SELECT ObjectId 
                FROM ObjectTerritory2Association
                WHERE Territory2Id = :region.Territory_ID__c
            ]) {
                accountIds.add(ota.ObjectId);
            }
        }
        
        // Use Opportunities as job requisitions
        AggregateResult[] results = [
            SELECT StageName, COUNT(Id) cnt
            FROM Opportunity
            WHERE AccountId IN :accountIds
            AND IsClosed = false
            GROUP BY StageName
        ];
        
        Integer total = 0;
        Integer open = 0;
        Integer filled = 0;
        Integer inProgress = 0;
        
        for (AggregateResult ar : results) {
            String stage = (String)ar.get('StageName');
            Integer count = (Integer)ar.get('cnt');
            total += count;
            
            if (stage == 'Prospecting') open = count;
            else if (stage == 'Closed Won') filled = count;
            else if (stage == 'Negotiation/Review') inProgress = count;
        }
        
        Integer overdue = [
            SELECT COUNT()
            FROM Opportunity
            WHERE AccountId IN :accountIds
            AND IsClosed = false
            AND CloseDate < TODAY
        ];
        
        return new Map<String, Object>{
            'total' => total,
            'completed' => filled,
            'inProgress' => inProgress,
            'overdue' => overdue,
            'open' => open
        };
    }
    
    private static Map<String, Object> calculateAccountKPIs(Id regionId) {
        Region__c region = [SELECT Territory_ID__c FROM Region__c WHERE Id = :regionId LIMIT 1];
        
        Integer totalAccounts = 0;
        if (String.isNotBlank(region.Territory_ID__c)) {
            totalAccounts = [
                SELECT COUNT()
                FROM ObjectTerritory2Association
                WHERE Territory2Id = :region.Territory_ID__c
            ];
        }
        
        return new Map<String, Object>{
            'total' => totalAccounts,
            'completed' => 0,
            'inProgress' => 0,
            'overdue' => 0
        };
    }
    
    private static Map<String, Object> calculateOpportunityKPIs(Id regionId) {
        Region__c region = [SELECT Territory_ID__c FROM Region__c WHERE Id = :regionId LIMIT 1];
        
        if (String.isBlank(region.Territory_ID__c)) {
            return new Map<String, Object>{
                'total' => 0,
                'totalPipeline' => 0,
                'completed' => 0,
                'inProgress' => 0,
                'overdue' => 0
            };
        }
        
        Set<Id> accountIds = new Set<Id>();
        for (ObjectTerritory2Association ota : [
            SELECT ObjectId FROM ObjectTerritory2Association WHERE Territory2Id = :region.Territory_ID__c
        ]) {
            accountIds.add(ota.ObjectId);
        }
        
        AggregateResult[] results = [
            SELECT StageName, COUNT(Id) cnt, SUM(Amount) totalAmount
            FROM Opportunity
            WHERE AccountId IN :accountIds
            AND IsClosed = false
            GROUP BY StageName
        ];
        
        Integer total = 0;
        Decimal totalPipeline = 0;
        
        for (AggregateResult ar : results) {
            total += (Integer)ar.get('cnt');
            totalPipeline += (Decimal)ar.get('totalAmount');
        }
        
        return new Map<String, Object>{
            'total' => total,
            'totalPipeline' => totalPipeline,
            'completed' => 0,
            'inProgress' => 0,
            'overdue' => 0
        };
    }
    
    /**
     * FR-23: Bulk Update Service
     * FR-18: Ownership Reassignment
     * FR-19: ETM Rule Compliance
     * FR-20: Audit Logging (automatic via Salesforce)
     */
    @AuraEnabled
    public static String reassignRecords(List<Id> recordIds, Id newOwnerId, String objectType) {
        try {
            if (objectType == 'Job') {
                return reassignJobs(recordIds, newOwnerId);
            } else if (objectType == 'Account') {
                return reassignAccounts(recordIds, newOwnerId);
            } else if (objectType == 'Opportunity') {
                return reassignOpportunities(recordIds, newOwnerId);
            }
            throw new AuraHandledException('Unsupported object type');
        } catch (Exception e) {
            throw new AuraHandledException('Error reassigning records: ' + e.getMessage());
        }
    }
    
    private static String reassignJobs(List<Id> jobIds, Id newOwnerId) {
        // For "Job" object type, we're using Opportunities
        List<Opportunity> jobs = [SELECT Id, OwnerId FROM Opportunity WHERE Id IN :jobIds];
        for (Opportunity job : jobs) {
            job.OwnerId = newOwnerId;
        }
        update jobs;
        return 'Successfully reassigned ' + jobs.size() + ' jobs';
    }
    
    private static String reassignAccounts(List<Id> accountIds, Id newOwnerId) {
        List<Account> accounts = [SELECT Id, OwnerId FROM Account WHERE Id IN :accountIds];
        for (Account acc : accounts) {
            acc.OwnerId = newOwnerId;
        }
        update accounts;
        return 'Successfully reassigned ' + accounts.size() + ' accounts';
    }
    
    private static String reassignOpportunities(List<Id> oppIds, Id newOwnerId) {
        List<Opportunity> opps = [SELECT Id, OwnerId FROM Opportunity WHERE Id IN :oppIds];
        for (Opportunity opp : opps) {
            opp.OwnerId = newOwnerId;
        }
        update opps;
        return 'Successfully reassigned ' + opps.size() + ' opportunities';
    }
    
    /**
     * Get available users for reassignment
     * FR-26: Role-based feature access
     */
    @AuraEnabled(cacheable=true)
    public static List<UserOption> getAvailableUsers(Id regionId) {
        try {
            Region__c region = [SELECT Territory_ID__c FROM Region__c WHERE Id = :regionId LIMIT 1];
            
            Set<Id> userIds = new Set<Id>();
            if (String.isNotBlank(region.Territory_ID__c)) {
                for (UserTerritory2Association uta : [
                    SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :region.Territory_ID__c
                ]) {
                    userIds.add(uta.UserId);
                }
            }
            
            List<User> users = [
                SELECT Id, Name, Title, Email
                FROM User
                WHERE Id IN :userIds
                AND IsActive = true
                WITH SECURITY_ENFORCED
                ORDER BY Name ASC
            ];
            
            List<UserOption> options = new List<UserOption>();
            for (User u : users) {
                UserOption option = new UserOption();
                option.value = u.Id;
                option.label = u.Name + ' (' + u.Title + ')';
                options.add(option);
            }
            
            return options;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching users: ' + e.getMessage());
        }
    }
    
    // Helper methods
    private static String determinePriority(Date dueDate, Decimal amount) {
        if (dueDate < Date.today()) return 'Critical';
        if (dueDate <= Date.today().addDays(7)) return 'High';
        if (amount != null && amount > 100000) return 'High';
        return 'Normal';
    }
    
    // Wrapper Classes
    public class RegionWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String RegionType;
        @AuraEnabled public String StateCode;
        @AuraEnabled public String GeoJSONBoundary;
        @AuraEnabled public Decimal CenterLat;
        @AuraEnabled public Decimal CenterLng;
        @AuraEnabled public String BorderColor;
        @AuraEnabled public String FillColor;
        @AuraEnabled public Decimal FillOpacity;
        @AuraEnabled public Id TerritoryId;
        @AuraEnabled public String Status;
    }
    
    public class RecordWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String Status;
        @AuraEnabled public String Priority;
        @AuraEnabled public Decimal Latitude;
        @AuraEnabled public Decimal Longitude;
        @AuraEnabled public String OwnerName;
        @AuraEnabled public Date DueDate;
        @AuraEnabled public String AccountName;
        @AuraEnabled public Boolean IsOverdue;
    }
    
    public class UserOption {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
    }
}