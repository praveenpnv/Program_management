import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchDNB from '@salesforce/apex/DNBTypeaheadSearch.searchDNB';
import checkDunsNumber from '@salesforce/apex/DnBAccountImport.checkDunsNumber';
import getAccountMaps from '@salesforce/apex/DnBAccountImport.getAccountMaps';
import getRecordTypes from '@salesforce/apex/DNBTypeaheadSearch.getRecordTypes';

export default class DnbSearchComponent extends NavigationMixin(LightningElement) {
    @track searchTerm = '';
    @track companies = [];
    @track error;
    @track isExistingAccount;
    @api recordId;
    @track showNewAccountModal = false;
    @track selectedRow = null;
    @track dunsError = '';
    @track existingAccountId = null;
    @track showDunsErrorModal = false;
    @track showSpinner = false;
    @api objectApiName;
    @api fieldName;
    @track selectedRecordTypeId;
    @track showRecordPicker = false;
    @track selectedRows = [];
    @track selectedRowId = null;
    @track availableRecordTypes = [];
    @track showRecordTypeModal = false;

    columns = [
        { label: 'Company Name', fieldName: 'name', type: 'text' },
        { label: 'DUNS', fieldName: 'duns', type: 'text' },
        { label: 'Address', fieldName: 'address', type: 'text' },
        { label: 'Currency', fieldName: 'currency', type: 'text' },
        { label: 'Yearly Revenue', fieldName: 'yearlyRevenue', type: 'number' },
        { label: 'SIC Code', fieldName: 'IndustrySICCode', type: 'number' },
        { label: 'Phone Number', fieldName: 'PhoneNumber', type: 'text' },
        { label: 'Description', fieldName: 'Description', type: 'text' }
    ];

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
    }

    handleSearch() {
        if (!this.searchTerm) {
            this.error = 'Please enter a search term';
            return;
        }
        this.error = '';
        this.companies = [];
        this.selectedRows = [];
        this.selectedRowId = null;

        searchDNB({ searchTerm: this.searchTerm })
            .then(response => {
                console.log('Raw API Response:', response);
                let parsedResponse;
                try {
                    parsedResponse = JSON.parse(response);
                    console.log('Parsed Response:', parsedResponse);
                } catch (error) {
                    console.error('Error parsing API response:', error);
                    this.error = 'Error parsing response';
                    return;
                }

                if (parsedResponse.searchCandidates && parsedResponse.searchCandidates.length > 0) {
                    this.companies = parsedResponse.searchCandidates.map((company, index) => ({
                        id: index + 1,
                        name: company.organization?.primaryName || 'N/A',
                        duns: company.organization?.duns || 'N/A',
                        address: this.buildFormattedAddress(company.organization),
                        PhoneNumber: this.formatPhoneNumber(company.organization?.telephone?.[0]?.telephoneNumber),
                        OperatingStatus: company.organization?.dunsControlStatus?.operatingStatus?.description || 'N/A',
                        yearlyRevenue: company.organization?.financials?.[0]?.yearlyRevenue?.[0]?.value || 'N/A',
                        currency: company.organization?.financials?.[0]?.yearlyRevenue?.[0]?.currency || 'N/A',
                        IndustrySICCode: company.organization?.primaryIndustryCodes?.[0]?.usSicV4 || 'N/A',
                        Description: company.organization?.primaryIndustryCodes?.[0]?.usSicV4Description || 'N/A',
                        // Store original organization data for address parsing
                        originalData: company.organization
                    }));
                } else {
                    this.error = 'No results found.';
                    this.companies = [];
                }
            })
            .catch(error => {
                console.error('API Error:', error);
                this.error = 'Error fetching data';
            });
    }

    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
        this.selectedRowId = this.selectedRows.length > 0 ? this.selectedRows[0].id : null;
    }

    handleCreateAccount() {
        if (!this.selectedRowId) {
            this.showToast('Error', 'Please select a row first', 'error');
            return;
        }
        
        const selectedRow = this.companies.find(company => company.id === this.selectedRowId);
        if (selectedRow) {
            this.checkDunsAndCreateAccount(selectedRow);
        }
    }

    checkDunsAndCreateAccount(row) {
        const dunsAsDecimal = parseFloat(row.duns);
        
        checkDunsNumber({ dunsNumber: dunsAsDecimal })
            .then(result => {
                console.log('DUNS Check Result:', result);
                
                if (result && result.exists) {
                    this.existingAccountId = result.accountId;
                    this.dunsError = `There is already an account existing with the same DUNS number: ${row.duns}`;
                    this.showDunsErrorModal = true;
                    this.isExistingAccount = true;
                } else {
                    this.createAccountFromRow(row);
                }
            })
            .catch(error => {
                console.error('Error checking DUNS:', error);
                this.error = 'Error checking existing accounts. Please try again.';
            });
    }

    viewExistingAccount() {
        console.log('Viewing existing account:', this.existingAccountId);
        window.open(`/${this.existingAccountId}`, '_blank');
        this.closeDunsErrorModal();
    }

    closeDunsErrorModal() {
        this.showDunsErrorModal = false;
        this.dunsError = '';
        this.existingAccountId = null;
    }

    createAccountFromRow(row) {
        this.selectedRow = JSON.parse(JSON.stringify(row));
        this.showSpinner = true;

        getAccountMaps({ recordId: this.recordId })
            .then(result => {
                console.log('Mandatory fields result:', result);
                
                const mandatoryFields = {};
                if (result && result.length > 0) {
                    result.forEach(item => {
                        if (item.fieldName && item.value) {
                            mandatoryFields[item.fieldName] = item.value;
                        }
                    });
                }

                const rowDefaults = this.buildRowDefaults(row);
                const finalDefaults = Object.assign({}, mandatoryFields, rowDefaults);
                
                console.log('🔍 Final default values:', JSON.stringify(finalDefaults));
                this.showSpinner = false;
                this.openNewAccount(finalDefaults);
            })
            .catch(error => {
                console.error('Error fetching mandatory fields:', error);
                this.showToast('Error', 'Could not fetch mandatory field mappings.', 'error');
                this.showSpinner = false;
                
                const fallbackDefaults = this.buildRowDefaults(row);
                console.log('🔍 Fallback defaults:', JSON.stringify(fallbackDefaults));
                this.openNewAccount(fallbackDefaults);
            });
    }

    buildRowDefaults(row) {
        const defaults = {};
        
        if (row.name && row.name !== 'N/A' && row.name.trim() !== '') {
            defaults.Name = String(row.name).trim();
        }
        
        if (row.duns && row.duns !== 'N/A' && row.duns.trim() !== '') {
            defaults.D_U_N_S_Number__c = String(row.duns).trim();
        }
        
        if (row.yearlyRevenue && row.yearlyRevenue !== 'N/A' && !isNaN(row.yearlyRevenue)) {
            defaults.AnnualRevenue = Number(row.yearlyRevenue);
        }
        
        if (row.PhoneNumber && row.PhoneNumber !== 'N/A' && row.PhoneNumber.trim() !== '') {
            defaults.Phone = String(row.PhoneNumber).trim();
        }
        
        if (row.originalData && row.originalData.primaryAddress) {
            const addressData = this.parseAddressFromOrganization(row.originalData);
            Object.assign(defaults, addressData);
        }
        
        return defaults;
    }

    parseAddressFromOrganization(organization) {
        const addressDefaults = {};
        
        if (organization.primaryAddress) {
            const address = organization.primaryAddress;
            
            // Street Address - combining line1 and line2 if available
            const streetParts = [];
            if (address.streetAddress?.line1) {
                streetParts.push(String(address.streetAddress.line1).trim());
            }
            if (address.streetAddress?.line2) {
                streetParts.push(String(address.streetAddress.line2).trim());
            }
            if (streetParts.length > 0) {
                addressDefaults.BillingStreet = streetParts.join(', ');
            }
            
            // City
            if (address.addressLocality?.name) {
                addressDefaults.BillingCity = String(address.addressLocality.name).trim();
            }
            
            // State/Province
            if (address.addressRegion?.name) {
                addressDefaults.BillingState = String(address.addressRegion.name).trim();
            }
            
            // Postal Code
            if (address.postalCode) {
                addressDefaults.BillingPostalCode = String(address.postalCode).trim();
            }
            
            // Country
            if (address.addressCountry?.name) {
                addressDefaults.BillingCountry = String(address.addressCountry.name).trim();
            }
        }
        
        return addressDefaults;
    }

    buildFormattedAddress(organization) {
        const addressParts = [];
        if (organization && organization.primaryAddress) {
            const address = organization.primaryAddress;
            if (address.streetAddress && address.streetAddress.line1) {
                addressParts.push(address.streetAddress.line1);
            }
            if (address.addressLocality && address.addressLocality.name) {
                addressParts.push(address.addressLocality.name);
            }
            if (address.addressRegion && address.addressRegion.name) {
                addressParts.push(address.addressRegion.name);
            }
            if (address.postalCode) {
                addressParts.push(address.postalCode);
            }
        }
        return addressParts.length > 0 ? addressParts.join(', ') : 'Address not available';
    }

    formatPhoneNumber(phone) {
        if (!phone || phone === 'N/A') return 'N/A';
        
        if (!phone.startsWith('+') && phone.length === 10) {
            return '+1' + phone;
        }
        return phone;
    }

    openNewAccount(dynamicDefaults) {
        if (!dynamicDefaults || typeof dynamicDefaults !== 'object') {
            console.error('❌ Invalid dynamicDefaults received:', dynamicDefaults);
            this.showToast('Error', 'Invalid default values received', 'error');
            return;
        }
        
        this.pendingDefaults = {};
        Object.keys(dynamicDefaults).forEach(key => {
            const value = dynamicDefaults[key];
            if (value !== null && value !== undefined && value !== '') {
                this.pendingDefaults[key] = value;
            }
        });
        
        // Fetch available record types before showing the picker
        this.fetchRecordTypes();
    }

    fetchRecordTypes() {
        console.log('🔍 Fetching record types for Account...');
        this.showSpinner = true;
        
        getRecordTypes({ objectApiName: 'Account' })
            .then(result => {
                console.log('✅ Record types fetched:', result);
                
                // Filter out Master and Global record types
                const filteredRecordTypes = (result || []).filter(recordType => {
                    const name = recordType.Name ? recordType.Name.toLowerCase() : '';
                    const developerName = recordType.DeveloperName ? recordType.DeveloperName.toLowerCase() : '';
                    
                    // Filter out Master and Global record types
                    return !name.includes('master') && 
                           !name.includes('global') && 
                           !developerName.includes('master') && 
                           !developerName.includes('global');
                });
                
                this.availableRecordTypes = filteredRecordTypes;
                this.showSpinner = false;
                
                if (this.availableRecordTypes.length === 0) {
                    this.showToast('Warning', 'No available record types found for Account object', 'warning');
                    return;
                }
                
                if (this.availableRecordTypes.length === 1) {
                    // If only one record type, select it automatically
                    this.selectedRecordTypeId = this.availableRecordTypes[0].Id;
                    this.proceedToAccountCreation();
                } else {
                    // Show record type picker modal
                    this.selectedRecordTypeId = this.availableRecordTypes[0].Id; // Pre-select first option
                    this.showRecordTypeModal = true;
                }
            })
            .catch(error => {
                console.error('❌ Error fetching record types:', error);
                this.showSpinner = false;
                this.showToast('Error', 'Failed to fetch record types: ' + error.body?.message || error.message, 'error');
            });
    }

    handleRecordTypeSelection(event) {
        const selectedRecordTypeId = event.target.value;
        this.selectedRecordTypeId = selectedRecordTypeId;
        console.log('✅ Record Type Selected:', this.selectedRecordTypeId);
    }

    proceedWithSelectedRecordType() {
        this.showRecordTypeModal = false;
        this.proceedToAccountCreation();
    }

    proceedToAccountCreation() {
        try {
            const defaultValues = encodeDefaultFieldValues(this.pendingDefaults || {});
            const url = `/lightning/o/Account/new?recordTypeId=${this.selectedRecordTypeId}&defaultFieldValues=${defaultValues}`;
            console.log('Navigating to:', url);
            window.open(url);
        } catch (error) {
            console.error('❌ Failed to navigate:', error);
            this.showToast('Error', 'Navigation to new Account failed.', 'error');
        }
    }

    handleRecordTypeSelected(event) {
        //this.selectedRecordTypeId = event.detail.recordTypeId;
        this.showRecordPicker = false;
        console.log('✅ Record Type Selected:', this.selectedRecordTypeId);
        this.proceedToAccountCreation();
    }

    handleCloseModal() {
        this.showRecordPicker = false;
        this.showRecordTypeModal = false;
    }

    closeRecordTypeModal() {
        this.showRecordTypeModal = false;
        this.availableRecordTypes = [];
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    // Getter for button container styling
    get createButtonClass() {
        return 'slds-m-top_medium slds-text-align_right';
    }

    // Getter to check if create button should be enabled
    get isCreateButtonDisabled() {
        return !this.selectedRowId;
    }
}