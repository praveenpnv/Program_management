import { LightningElement, track } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LEAFLET from '@salesforce/resourceUrl/leaflet';

// Apex
import getTerritories from '@salesforce/apex/SalesTerritoryController.getTerritories';
import getAccountsByTerritory from '@salesforce/apex/SalesTerritoryController.getAccountsByTerritory';
import getPerformanceDashboard from '@salesforce/apex/SalesTerritoryController.getPerformanceDashboard';
import getHeatMapData from '@salesforce/apex/SalesTerritoryController.getHeatMapData';

export default class SalesTerritoryMap extends LightningElement {

    // ============================
    // STATE
    // ============================
    @track territories = [];
    @track territorySummaries = [];
    @track selectedTerritory;
    @track accounts = [];
    @track dashboard;

    currentView = 'performance';

    leafletMap;
    mapInitialized = false;
    territoryLayers = new Map();
    accountMarkers = [];
    heatMapLayer;

    @track kpis = {
        revenue: 0,
        pipeline: 0,
        accounts: 0,
        opportunities: 0
    };

    // ============================
    // GETTERS
    // ============================
    get showPerformanceView() {
        return this.currentView === 'performance';
    }

    get isPerformanceView() {
        return this.currentView === 'performance' ? 'brand' : 'neutral';
    }

    get isOptimizationView() {
        return this.currentView === 'optimization' ? 'brand' : 'neutral';
    }

    get isMarketView() {
        return this.currentView === 'market' ? 'brand' : 'neutral';
    }

    get sidePanelClass() {
        return this.selectedTerritory
            ? 'side-panel'
            : 'side-panel side-panel-hidden';
    }

    get territoryHealthScore() {
        return this.selectedTerritory?.quotaAttainment || 0;
    }

    get performanceStatus() {
        return this.selectedTerritory?.status || 'Unknown';
    }

    // ============================
    // LIFECYCLE
    // ============================
    renderedCallback() {
        if (this.mapInitialized) return;
        this.mapInitialized = true;
        this.loadLeaflet();
    }

    // ============================
    // MAP INIT
    // ============================
    loadLeaflet() {
        Promise.all([
            loadStyle(this, LEAFLET + '/dist/leaflet.css'),
            loadScript(this, LEAFLET + '/dist/leaflet.js')
        ])
        .then(() => this.initializeMap())
        .catch(err => this.showError('Map Error', err.message));
    }

    initializeMap() {
        const el = this.template.querySelector('.map-container');
        if (!el) return;

        this.leafletMap = L.map(el).setView([39.8283, -98.5795], 4);

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 18,
            attribution: '© OpenStreetMap'
        }).addTo(this.leafletMap);

        this.loadData();
    }

    // ============================
    // DATA LOAD
    // ============================
    loadData() {
        getTerritories()
            .then(data => {
                this.territories = data;
                this.processTerritories(data);
                this.renderTerritories(data);
            })
            .catch(err => this.showError('Territory Error', err.message));

        getPerformanceDashboard()
            .then(data => this.dashboard = data)
            .catch(() => {});
    }

    processTerritories(data) {
        this.territorySummaries = data.map(t => ({
            id: t.id,
            name: t.name,
            revenue: t.revenue,
            quotaAttainment: t.quotaAttainment,
            accounts: t.accountCount,
            status: t.status,
            colorStyle: `background:${t.statusColor}`
        }));
    }

    // ============================
    // MAP RENDER
    // ============================
    renderTerritories(data) {
        this.territoryLayers.clear();

        data.forEach(t => {
            if (!t.centerLat || !t.centerLng) return;

            const marker = L.circleMarker(
                [t.centerLat, t.centerLng],
                {
                    radius: Math.max(14, Math.sqrt(t.accountCount + 1) * 4),
                    fillColor: t.statusColor,
                    color: '#fff',
                    weight: 2,
                    fillOpacity: 0.75
                }
            ).addTo(this.leafletMap);

            marker.bindPopup(`
                <strong>${t.name}</strong><br/>
                Quota: ${t.quotaAttainment}%<br/>
                Revenue: $${(t.revenue / 1000).toFixed(0)}K<br/>
                Pipeline: $${(t.pipeline / 1000).toFixed(0)}K<br/>
                Accounts: ${t.accountCount}
            `);

            marker.on('click', () => this.selectTerritory(t));

            this.territoryLayers.set(t.id, marker);
        });
    }

    // ============================
    // TERRITORY SELECT
    // ============================
    selectTerritory(t) {
        this.selectedTerritory = t;

        this.leafletMap.setView([t.centerLat, t.centerLng], 6);

        this.kpis = {
            revenue: t.revenue,
            pipeline: t.pipeline,
            accounts: t.accountCount,
            opportunities: t.openOpportunities
        };

        this.loadAccounts(t.id);

        this.territoryLayers.forEach((layer, id) => {
            layer.setStyle({
                weight: id === t.id ? 4 : 2
            });
        });
    }

    // ============================
    // ACCOUNTS
    // ============================
    loadAccounts(territoryId) {
        getAccountsByTerritory({ territoryId })
            .then(data => {
                this.accounts = data;
                this.renderAccounts(data);
            })
            .catch(() => {});
    }

    renderAccounts(accounts) {
        this.accountMarkers.forEach(m => this.leafletMap.removeLayer(m));
        this.accountMarkers = [];

        accounts.forEach(a => {
            if (!a.latitude || !a.longitude) return;

            const m = L.marker([a.latitude, a.longitude])
                .addTo(this.leafletMap)
                .bindPopup(`
                    <strong>${a.name}</strong><br/>
                    ${a.industry || ''}<br/>
                    Revenue: $${(a.annualRevenue || 0) / 1e6}M<br/>
                    Opps: ${a.opportunityCount}
                `);

            this.accountMarkers.push(m);
        });
    }

    // ============================
    // VIEW SWITCH
    // ============================
    handlePerformanceView() {
        this.currentView = 'performance';
    }

    handleOptimizationView() {
        this.currentView = 'optimization';
    }

    handleMarketView() {
        this.currentView = 'market';
        this.loadHeatMap();
    }

    loadHeatMap() {
        getHeatMapData({ metricType: 'revenue' })
            .then(data => {
                if (this.heatMapLayer) {
                    this.leafletMap.removeLayer(this.heatMapLayer);
                }

                this.heatMapLayer = L.layerGroup(
                    data.map(p =>
                        L.circle([p.latitude, p.longitude], {
                            radius: p.intensity * 1000,
                            color: '#ff0000',
                            fillOpacity: 0.25
                        })
                    )
                ).addTo(this.leafletMap);
            });
    }

    handleCloseSidePanel() {
        this.selectedTerritory = null;
        this.accounts = [];
    }

    // ============================
    // UTIL
    // ============================
    showError(title, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant: 'error'
            })
        );
    }
}