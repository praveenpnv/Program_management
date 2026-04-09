import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import performCreditCheck from '@salesforce/apex/DNBCreditCheckCallout.performCreditCheck';
import checkCreditDataStatus from '@salesforce/apex/DNBCreditCheckCallout.checkCreditDataStatus';
import searchCompaniesByName from '@salesforce/apex/DNBCreditCheckCallout.searchCompaniesByName';
import updateAccountWithDUNSAndFetchCredit from '@salesforce/apex/DNBCreditCheckCallout.updateAccountWithDUNSAndFetchCredit';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

const columns = [
    { label: 'Company Name', fieldName: 'primaryName', type: 'text' },
    { label: 'DUNS Number', fieldName: 'duns', type: 'text' },
    { label: 'Address', fieldName: 'address', type: 'text', wrapText: true }
];

export default class DNBCreditCheck extends LightningElement {
    @api recordId; // Account ID
    @track currentStep = 'initial'; // 'initial', 'searching', 'companySelection', 'processing'
    @track isLoading = false;
    @track searchResults = [];
    @track selectedCompanies = [];
    @track accountName = '';
    @track processingMessage = 'Processing credit check...';
    
    columns = columns;
    pollInterval;
    maxPollAttempts = 30; // 30 attempts = 30 seconds
    currentPollAttempt = 0;

    connectedCallback() {
        console.log('Account ID:', this.recordId);
    }

    disconnectedCallback() {
        // Clean up polling interval
        if (this.pollInterval) {
            clearInterval(this.pollInterval);
        }
    }

    async handleClick() {
        this.isLoading = true;
        
        try {
            const result = await performCreditCheck({ accountId: this.recordId });
            
            if (result.success) {
                if (result.directCreditCheck) {
                    // Account had DUNS, credit check initiated
                    this.showToast('Credit Check Started', 'Credit check has been initiated. Please wait...', 'info');
                    this.startCreditCheckPolling();
                } else {
                    // No DUNS found, need to search for companies
                    this.accountName = result.accountName;
                    await this.searchForCompanies(this.accountName);
                }
            } else {
                throw new Error(result.message || 'Unknown error occurred');
            }
        } catch (error) {
            console.error('Error in handleClick:', error);
            this.showToast('Error', error.body?.message || error.message || 'Unknown error', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    startCreditCheckPolling() {
        this.currentStep = 'processing';
        this.currentPollAttempt = 0;
        this.processingMessage = 'Processing credit check... This may take up to 30 seconds.';
        
        this.pollInterval = setInterval(async () => {
            try {
                this.currentPollAttempt++;
                this.processingMessage = `Processing credit check... (${this.currentPollAttempt}/${this.maxPollAttempts})`;
                
                const statusResult = await checkCreditDataStatus({ accountId: this.recordId });
                
                if (statusResult.success && statusResult.hasCreditData) {
                    // Credit data found, stop polling
                    clearInterval(this.pollInterval);
                    this.showToast('Success', 'Credit check completed successfully!', 'success');
                    this.notifyRecordChange();
                    this.closeQuickAction();
                } else if (this.currentPollAttempt >= this.maxPollAttempts) {
                    // Max attempts reached, stop polling
                    clearInterval(this.pollInterval);
                    this.currentStep = 'initial';
                    this.showToast('Timeout', 'Credit check is taking longer than expected. Please check the record later or try again.', 'warning');
                }
            } catch (error) {
                console.error('Error polling credit data:', error);
                clearInterval(this.pollInterval);
                this.currentStep = 'initial';
                this.showToast('Error', 'Error checking credit data status', 'error');
            }
        }, 1000); // Poll every 1 second
    }

    async searchForCompanies(companyName) {
        try {
            this.currentStep = 'searching';
            console.log('Searching for companies with name:', companyName);
            const cleanedName = companyName.trim().replace(/^\.+/, '').replace(/[\/\\]/g, ' ');
            const companies = await searchCompaniesByName({ companyName: cleanedName });
            
            if (companies && companies.length > 0) {
                this.searchResults = companies.map(company => ({
                    ...company,
                    id: company.duns
                }));
                this.currentStep = 'companySelection';
                console.log('Found companies:', this.searchResults.length);
            }  if (!companies || companies.length === 0) {
                this.showToast('No Results', `No companies found matching "${companyName}".`, 'warning');
                this.currentStep = 'initial';
                return;
            }
        } catch (error) {
            console.error('Error in searchForCompanies:', error);
            this.currentStep = 'initial';
            throw error;
        }
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedCompanies = selectedRows;
        console.log('Selected companies:', this.selectedCompanies.length);
    }

    async handleSelectCompany() {
        if (this.selectedCompanies.length === 0) {
            this.showToast('Warning', 'Please select at least one company.', 'warning');
            return;
        }

        if (this.selectedCompanies.length > 1) {
            this.showToast('Warning', 'Please select only one company for credit check.', 'warning');
            return;
        }

        this.isLoading = true;
        
        try {
            const selectedCompany = this.selectedCompanies[0];
            console.log('Processing company:', selectedCompany.primaryName, 'DUNS:', selectedCompany.duns);
            
            const result = await updateAccountWithDUNSAndFetchCredit({ 
                accountId: this.recordId, 
                selectedDUNS: selectedCompany.duns.toString() 
            });
            this.isLoading = false;
            this.startCreditCheckPolling();
            
        } catch (error) {
            console.error('Error selecting company:', error);
            this.showToast('Error', error.body?.message || error.message || 'Error selecting company', 'error');
            this.isLoading = false;
        }
    }

    handleBackToInitial() {
        // Clean up polling if active
        if (this.pollInterval) {
            clearInterval(this.pollInterval);
        }
        
        this.currentStep = 'initial';
        this.searchResults = [];
        this.selectedCompanies = [];
    }

    handleCloseCard() {
        // Clean up polling if active
        if (this.pollInterval) {
            clearInterval(this.pollInterval);
        }
        
        this.closeQuickAction();
    }

    // Refresh data
    notifyRecordChange() {
        getRecordNotifyChange([{ recordId: this.recordId }]);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    closeQuickAction() {
        console.log('Attempting to close quick action');
        
        try {
            this.dispatchEvent(new CloseActionScreenEvent());
            console.log('CloseActionScreenEvent dispatched');
        } catch (error) {
            console.log('CloseActionScreenEvent failed:', error);
            
            try {
                this.dispatchEvent(new CustomEvent('close'));
                console.log('Custom close event dispatched');
            } catch (error2) {
                console.log('Custom close event failed:', error2);
                
                if (window.parent && window.parent !== window) {
                    window.parent.postMessage({ action: 'close' }, '*');
                    console.log('Parent window message sent');
                }
            }
        }
    }

    // Getter methods for conditional rendering
    get isInitialStep() {
        return this.currentStep === 'initial';
    }

    get isSearchingStep() {
        return this.currentStep === 'searching';
    }

    get isCompanySelectionStep() {
        return this.currentStep === 'companySelection';
    }

    get isProcessingStep() {
        return this.currentStep === 'processing';
    }

    get hasSearchResults() {
        return this.searchResults && this.searchResults.length > 0;
    }

    get searchMessage() {
        return `Searching for companies matching "${this.accountName}"...`;
    }

    get selectionMessage() {
        return `Found ${this.searchResults.length} companies matching "${this.accountName}". Please select one to proceed with credit check:`;
    }
}