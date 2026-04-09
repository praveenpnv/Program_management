/**
 * Sales Territory Intelligence Controller
 * Manages territory analytics, performance tracking, and optimization
 */
public with sharing class SalesTerritoryController {
    
    /**
     * Get all active territories with performance metrics
     */
    @AuraEnabled(cacheable=true)
    public static List<TerritoryData> getTerritories() {
        
        // 1. FIX: Filter by the related Territory2Model's State field (Standard approach for ETM 'active')
        List<Territory2> territories = [
            SELECT Id, Name, Description, ParentTerritory2Id
            FROM Territory2
            WHERE Territory2Model.State = 'Active' 
            ORDER BY Name
        ];
        
        // Get territory IDs
        Set<Id> territoryIds = new Set<Id>();
        for (Territory2 territory : territories) {
            territoryIds.add(territory.Id);
        }
        
        // Maps to hold final metrics
        Map<Id, Integer> accountsByTerritory = new Map<Id, Integer>();
        Map<Id, Decimal> revenueByTerritory = new Map<Id, Decimal>();
        Map<Id, Decimal> pipelineByTerritory = new Map<Id, Decimal>();
        Map<Id, Integer> oppsByTerritory = new Map<Id, Integer>();
        
        // New map to store ALL associated Account IDs by Territory for aggregation (Crucial for Fix 2)
        Map<Id, Set<Id>> accountIdsByTerritory = new Map<Id, Set<Id>>();
        Set<Id> allAccountIds = new Set<Id>();

        // Get account assignments per territory
        // 2. REFACTOR: Collect all Account IDs associated with each Territory ID
        for (ObjectTerritory2Association ota : [
            SELECT Territory2Id, ObjectId // ObjectId is the Account ID
            FROM ObjectTerritory2Association
            WHERE Territory2Id IN :territoryIds
            AND ObjectId IN (SELECT Id FROM Account) // Ensures only Account associations
        ]) {
            Id terrId = ota.Territory2Id;
            Id accountId = ota.ObjectId;

            if (!accountIdsByTerritory.containsKey(terrId)) {
                accountIdsByTerritory.put(terrId, new Set<Id>());
            }
            accountIdsByTerritory.get(terrId).add(accountId);
            allAccountIds.add(accountId);
        }
        
        // Calculate total account count per territory
        for(Id terrId : accountIdsByTerritory.keySet()) {
            accountsByTerritory.put(terrId, accountIdsByTerritory.get(terrId).size());
        }
        
        // 3. FIX: Calculate revenue and pipeline by querying Opportunities on AccountId 
        //         and mapping the results back to Territory2Id in Apex.
        for (AggregateResult ar : [
            SELECT AccountId, SUM(Amount) totalAmount, StageName
            FROM Opportunity
            WHERE AccountId IN :allAccountIds 
            AND CloseDate = THIS_YEAR
            GROUP BY AccountId, StageName
        ]) {
            Id accountId = (Id)ar.get('AccountId');
            Decimal amount = (Decimal)ar.get('totalAmount');
            String stage = (String)ar.get('StageName');
            
            // Map the opportunity data back to the territory(s) the account belongs to
            for(Id territoryId : accountIdsByTerritory.keySet()) {
                if(accountIdsByTerritory.get(territoryId).contains(accountId)) {
                    if (stage == 'Closed Won') {
                        Decimal currentRevenue = revenueByTerritory.containsKey(territoryId) ? revenueByTerritory.get(territoryId) : 0;
                        revenueByTerritory.put(territoryId, currentRevenue + amount);
                    } else {
                        Decimal currentPipeline = pipelineByTerritory.containsKey(territoryId) ? pipelineByTerritory.get(territoryId) : 0;
                        pipelineByTerritory.put(territoryId, currentPipeline + amount);
                    }
                }
            }
        }
        
        // 4. FIX: Count open opportunities using AccountId and mapping back to Territory2Id.
        for (AggregateResult ar : [
            SELECT AccountId, COUNT(Id) cnt
            FROM Opportunity
            WHERE AccountId IN :allAccountIds 
            AND IsClosed = false
            GROUP BY AccountId
        ]) {
            Id accountId = (Id)ar.get('AccountId');
            Integer count = (Integer)ar.get('cnt');
            
            // Map the count back to the territory(s) the account belongs to
            for(Id territoryId : accountIdsByTerritory.keySet()) {
                if(accountIdsByTerritory.get(territoryId).contains(accountId)) {
                    Integer currentOpps = oppsByTerritory.containsKey(territoryId) ? oppsByTerritory.get(territoryId) : 0;
                    oppsByTerritory.put(territoryId, currentOpps + count);
                }
            }
        }
        
        // Build result
        List<TerritoryData> result = new List<TerritoryData>();
        
        for (Territory2 territory : territories) {
            TerritoryData data = new TerritoryData();
            data.id = territory.Id;
            data.name = territory.Name;
            data.description = territory.Description;
            
            // Get metrics
            data.accountCount = accountsByTerritory.containsKey(territory.Id) 
                ? accountsByTerritory.get(territory.Id) : 0;
            data.revenue = revenueByTerritory.containsKey(territory.Id) 
                ? revenueByTerritory.get(territory.Id) : 0;
            data.pipeline = pipelineByTerritory.containsKey(territory.Id) 
                ? pipelineByTerritory.get(territory.Id) : 0;
            data.openOpportunities = oppsByTerritory.containsKey(territory.Id) 
                ? oppsByTerritory.get(territory.Id) : 0;
            
            // Calculate quota attainment (assuming $2.5M target per territory)
            Decimal target = 2500000;
            data.quotaTarget = target;
            data.quotaAttainment = data.revenue > 0 ? (Integer)((data.revenue / target) * 100) : 0;
            
            // Determine status
            if (data.quotaAttainment >= 90) {
                data.status = 'On Track';
                data.statusColor = '#04844b'; // Green
            } else if (data.quotaAttainment >= 70) {
                data.status = 'At Risk';
                data.statusColor = '#ffb75d'; // Orange
            } else {
                data.status = 'Behind';
                data.statusColor = '#c23934'; // Red
            }
            
            // Mock coordinates (in real system, store on Territory2 or custom object)
            data.centerLat = 37.7749 + (Math.random() * 10 - 5);
            data.centerLng = -122.4194 + (Math.random() * 10 - 5);
            
            result.add(data);
        }
        
        return result;
    }
    
    /**
     * Get accounts for selected territory
     */
    @AuraEnabled(cacheable=true)
    public static List<AccountData> getAccountsByTerritory(Id territoryId) {
        Set<Id> accountIds = new Set<Id>();
        
        // Get accounts assigned to territory
        for (ObjectTerritory2Association ota : [
            SELECT ObjectId
            FROM ObjectTerritory2Association
            WHERE Territory2Id = :territoryId
            AND ObjectId IN (SELECT Id FROM Account)
        ]) {
            accountIds.add(ota.ObjectId);
        }
        
        List<Account> accounts = [
            SELECT Id, Name, Type, Industry, AnnualRevenue,
                   BillingCity, BillingState, BillingLatitude, BillingLongitude,
                   Owner.Name
            FROM Account
            WHERE Id IN :accountIds
            AND BillingLatitude != null
            AND BillingLongitude != null
            ORDER BY Name
            LIMIT 100
        ];
        
        // Get opportunity count and value per account
        Map<Id, Integer> oppCountByAccount = new Map<Id, Integer>();
        Map<Id, Decimal> oppValueByAccount = new Map<Id, Decimal>();
        
        for (AggregateResult ar : [
            SELECT AccountId, COUNT(Id) cnt, SUM(Amount) totalAmount
            FROM Opportunity
            WHERE AccountId IN :accountIds
            AND IsClosed = false
            GROUP BY AccountId
        ]) {
            Id accountId = (Id)ar.get('AccountId');
            oppCountByAccount.put(accountId, (Integer)ar.get('cnt'));
            oppValueByAccount.put(accountId, (Decimal)ar.get('totalAmount'));
        }
        
        List<AccountData> result = new List<AccountData>();
        
        for (Account acc : accounts) {
            AccountData data = new AccountData();
            data.id = acc.Id;
            data.name = acc.Name;
            data.type = acc.Type;
            data.industry = acc.Industry;
            data.annualRevenue = acc.AnnualRevenue;
            data.city = acc.BillingCity;
            data.state = acc.BillingState;
            data.latitude = acc.BillingLatitude;
            data.longitude = acc.BillingLongitude;
            data.ownerName = acc.Owner.Name;
            data.opportunityCount = oppCountByAccount.containsKey(acc.Id) 
                ? oppCountByAccount.get(acc.Id) : 0;
            data.opportunityValue = oppValueByAccount.containsKey(acc.Id) 
                ? oppValueByAccount.get(acc.Id) : 0;
            
            result.add(data);
        }
        
        return result;
    }
    
    /**
     * Get territory performance dashboard
     */
    @AuraEnabled(cacheable=true)
    public static PerformanceDashboard getPerformanceDashboard() {
        PerformanceDashboard dashboard = new PerformanceDashboard();
        dashboard.topPerformers = new List<PerformerData>();
        dashboard.needsAttention = new List<PerformerData>();
        
        List<TerritoryData> territories = getTerritories();
        
        // Sort by quota attainment
        territories.sort();
        
        // Top 3 performers
        for (Integer i = Math.max(0, territories.size() - 3); i < territories.size(); i++) {
            TerritoryData territory = territories[i];
            if (territory.quotaAttainment >= 90) {
                PerformerData performer = new PerformerData();
                performer.territoryName = territory.name;
                performer.quotaAttainment = territory.quotaAttainment;
                performer.revenue = territory.revenue;
                performer.target = territory.quotaTarget;
                performer.status = 'success';
                dashboard.topPerformers.add(0, performer);
            }
        }
        
        // Territories needing attention
        for (TerritoryData territory : territories) {
            if (territory.quotaAttainment < 70) {
                PerformerData performer = new PerformerData();
                performer.territoryName = territory.name;
                performer.quotaAttainment = territory.quotaAttainment;
                performer.revenue = territory.revenue;
                performer.target = territory.quotaTarget;
                performer.status = territory.quotaAttainment < 50 ? 'critical' : 'warning';
                performer.recommendation = buildRecommendation(territory);
                dashboard.needsAttention.add(performer);
            }
        }
        
        // Calculate totals
        Decimal totalRevenue = 0;
        Decimal totalTarget = 0;
        Decimal totalPipeline = 0;
        
        for (TerritoryData territory : territories) {
            totalRevenue += territory.revenue;
            totalTarget += territory.quotaTarget;
            totalPipeline += territory.pipeline;
        }
        
        dashboard.totalRevenue = totalRevenue;
        dashboard.totalTarget = totalTarget;
        dashboard.totalPipeline = totalPipeline;
        dashboard.overallAttainment = totalTarget > 0 ? (Integer)((totalRevenue / totalTarget) * 100) : 0;
        
        return dashboard;
    }
    
    /**
     * Get heat map data for market analysis
     */
    @AuraEnabled(cacheable=true)
    public static List<HeatMapPoint> getHeatMapData(String metricType) {
        List<HeatMapPoint> points = new List<HeatMapPoint>();
        
        List<Account> accounts = [
            SELECT Id, Name, BillingLatitude, BillingLongitude, AnnualRevenue,
                   (SELECT Amount FROM Opportunities WHERE IsClosed = false)
            FROM Account
            WHERE BillingLatitude != null
            AND BillingLongitude != null
            LIMIT 500
        ];
        
        for (Account acc : accounts) {
            HeatMapPoint point = new HeatMapPoint();
            point.latitude = acc.BillingLatitude;
            point.longitude = acc.BillingLongitude;
            point.accountName = acc.Name;
            
            if (metricType == 'revenue') {
                point.intensity = acc.AnnualRevenue != null ? acc.AnnualRevenue / 1000000 : 1;
            } else if (metricType == 'opportunities') {
                point.intensity = acc.Opportunities.size();
            } else {
                point.intensity = 1; // Customer density
            }
            
            points.add(point);
        }
        
        return points;
    }
    
    // Helper methods
    private static String buildRecommendation(TerritoryData territory) {
        if (territory.quotaAttainment < 50) {
            return territory.openOpportunities + ' open opportunities. Review pipeline quality and add coaching.';
        }
        return 'Monitor closely. Consider territory rebalancing.';
    }
    
    // Wrapper classes (Unchanged)
    public class TerritoryData implements Comparable {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String description;
        @AuraEnabled public Integer accountCount;
        @AuraEnabled public Decimal revenue;
        @AuraEnabled public Decimal pipeline;
        @AuraEnabled public Integer openOpportunities;
        @AuraEnabled public Decimal quotaTarget;
        @AuraEnabled public Integer quotaAttainment;
        @AuraEnabled public String status;
        @AuraEnabled public String statusColor;
        @AuraEnabled public Decimal centerLat;
        @AuraEnabled public Decimal centerLng;
        
        public Integer compareTo(Object obj) {
            TerritoryData other = (TerritoryData)obj;
            if (this.quotaAttainment > other.quotaAttainment) return 1;
            if (this.quotaAttainment < other.quotaAttainment) return -1;
            return 0;
        }
    }
    
    public class AccountData {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String type;
        @AuraEnabled public String industry;
        @AuraEnabled public Decimal annualRevenue;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public Decimal latitude;
        @AuraEnabled public Decimal longitude;
        @AuraEnabled public String ownerName;
        @AuraEnabled public Integer opportunityCount;
        @AuraEnabled public Decimal opportunityValue;
    }
    
    public class PerformanceDashboard {
        @AuraEnabled public List<PerformerData> topPerformers;
        @AuraEnabled public List<PerformerData> needsAttention;
        @AuraEnabled public Decimal totalRevenue;
        @AuraEnabled public Decimal totalTarget;
        @AuraEnabled public Decimal totalPipeline;
        @AuraEnabled public Integer overallAttainment;
    }
    
    public class PerformerData {
        @AuraEnabled public String territoryName;
        @AuraEnabled public Integer quotaAttainment;
        @AuraEnabled public Decimal revenue;
        @AuraEnabled public Decimal target;
        @AuraEnabled public String status;
        @AuraEnabled public String recommendation;
    }
    
    public class HeatMapPoint {
        @AuraEnabled public Decimal latitude;
        @AuraEnabled public Decimal longitude;
        @AuraEnabled public String accountName;
        @AuraEnabled public Decimal intensity;
    }
}