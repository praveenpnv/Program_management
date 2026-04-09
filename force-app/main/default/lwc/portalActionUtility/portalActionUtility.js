import { LightningElement, track, wire, api } from 'lwc';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { NavigationMixin } from 'lightning/navigation';
import USER_ID from '@salesforce/user/Id';
import PortalActionModal from 'c/portalActionModal';
import { getRecords } from 'lightning/uiRecordApi';
import CONTACT_NAME_FIELD from '@salesforce/schema/Contact.Name';
import CONTACT_EMAIL_FIELD from '@salesforce/schema/Contact.Email';
import TR1_JOB_NAME from '@salesforce/schema/TR1__Job__c.Name';
import saveApplications from '@salesforce/apex/PortalActionController.saveApplications';
import saveLonglistRecords from '@salesforce/apex/PortalActionController.saveLonglistRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { publish,subscribe as lmsSubscribe, unsubscribe as lmsUnsubscribe,  MessageContext } from 'lightning/messageService';
import contactActionMC from '@salesforce/messageChannel/TR1__contactRunAction__c';
import contactRunActionResultMC from '@salesforce/messageChannel/TR1__contactRunActionResult__c';


export default class PortalActionUtility extends NavigationMixin(LightningElement) {
    channelName = '/event/Textkernel1__PortalAction__e';
    subscription = null;
    @api label;
    @api iconName;
    @track receivedEvents = [];
    isConnected = false;
    currentUserId = USER_ID;
    @api showSpinner = false;
    @api contactData = [];
    @api jobData =[];
    @api contactIds = [];
    @api jobId;
    @api jobIds = [];

    modalInstance;
    portalAction;

    connectedCallback() {
        this.isConnected = true;
        this.handleSubscribe();
        this.registerErrorListener();
        this.subscribeToContactRunActionResult(); // Subscribe to the new channel

    }

    disconnectedCallback() {
        this.isConnected = false;
        this.handleUnsubscribe();
        this.unsubscribeToContactRunActionResult();
    }

    columns =[];
    /*columns = [
        { label: 'Name', fieldName: 'Name', type: 'text' },
        { label: 'Email', fieldName: 'Email', type: 'email' },
        {
            label: 'Status',
            fieldName: 'Status',
            type: 'text',
                cellAttributes: {
                    iconName: { fieldName: 'iconName' },
                    Class: { fieldName: 'iconClass' },
                    iconPosition: 'left',       
                    variant: { fieldName :'iconVariant'},
                alternativeText: 'Status',
                title: 'Status'
                
                }
        }//,
        //{ label: 'Status', fieldName: 'message', type: 'text' }
    ];*/

    @wire(MessageContext)
    messageContext;
    
    // Fetch Job Name using wire
    @wire(getRecords, { records: '$formattedJobRecord' })
    wiredJob({ error, data }) {
        if (data) {
            try {
                this.jobData = data.results.map(record => ({
                    Id: record?.result?.id,
                    JobName: record?.result?.fields?.Name?.value || 'Unknown',
                    Status: 'Pending',
                    iconName: 'utility:clock',
                    iconClass: 'slds-icon-text-warning',
                    iconVariant: 'warning'
                }));

                this.showSpinner = false;
                if (this.jobData.length > 0 && this.actionType === 'job') {
                    this.openModal();
                }
            } catch (error) {
                console.error('Error processing job data:', error);
                this.showToast('Error', 'Failed to process job data.', 'error');
            }
        } else if (error) {
            console.error('Error fetching job data:', error);
            this.showToast('Error', 'Failed to fetch job data.', 'error');
            this.showSpinner = false;
        }
    }

    get formattedJobRecord() {
        console.log('formattedJobRecord'+this.jobIds);    
        return this.jobIds.length > 0? [{ recordIds: this.jobIds, fields: [TR1_JOB_NAME] }] : [];
    }

    @wire(getRecords, { records: '$formattedContactRecords' })
    wiredContacts({ error, data }) {
        if (data) {
            try{
                this.contactData = data.results.map(record => ({
                    Id: record?.result?.id,
                    Name: record?.result?.fields?.Name?.value || 'Unknown',
                    Email: record?.result?.fields?.Email?.value || 'No Email',
                    Status: 'Pending',
                    iconName: 'utility:clock',
                    Class: 'slds-icon-text-warning',
                    iconVariant: 'warning'          

                }));
            this.showSpinner = false;
            if (this.contactData.length > 0 && this.actionType==='candidate') {
                this.openModal();
            }
        }catch (error) {
            console.error('Error processing contact data:', error);
            this.showToast('Error', 'Failed to process contact data.', 'error');
        }
        
    }
    else if (error) {
        console.error('Error fetching contact data:', error);
        this.showToast('Error', 'Failed to fetch contact data.', 'error');
        this.showSpinner = false;
    }
}

    get formattedContactRecords() {
    return this.contactIds.length > 0
        ? [{ recordIds: this.contactIds, fields: [CONTACT_NAME_FIELD, CONTACT_EMAIL_FIELD] }]
        : [];
}
subscribeToContactRunActionResult() {
    if (!this.contactRunActionResultSubscription) {
        this.contactRunActionResultSubscription = lmsSubscribe(
            this.messageContext,
            contactRunActionResultMC,
            (message) => {
                this.handleContactRunActionResultMessage(message);
            }
        );
    }
}

unsubscribeToContactRunActionResult() {
    if (this.contactRunActionResultSubscription) {
        lmsUnsubscribe(this.contactRunActionResultSubscription);
        this.contactRunActionResultSubscription = null;
    }
}

handleContactRunActionResultMessage(message) {
    console.log('Received message from contactRunActionResultMC:', JSON.stringify(message));
    // Process the message from contactRunActionResultMC here
    // Update your component state or perform actions based on the message
}


handleSubscribe() {
    if (this.subscription) {
        console.log('Already subscribed. Skipping duplicate subscription.');
        return;
    }

    const messageCallback = (response) => {
        console.log('Received Platform Event:', JSON.stringify(response));
        const payload = response.data.payload;

        if (payload.Textkernel1__Action__c === 'saveCandidateToListAction' &&
            payload.Textkernel1__UserId__c === this.currentUserId) {
            this.showSpinner = true;
            this.receivedEvents = [...this.receivedEvents, payload];
            this.contactIds = payload.Textkernel1__SearchResultIds__c
                ? payload.Textkernel1__SearchResultIds__c.split(',').map(id => id.trim())
                : [];
            this.jobId = payload.Textkernel1__SearchFromId__c;
            this.actionType = 'candidate';
            this.setColumns();

        }
        if (payload.Textkernel1__Action__c === 'saveJobToListAction' &&
                        payload.Textkernel1__UserId__c === this.currentUserId) {
                            console.log('Textkernel1__SearchResultIds__c'+payload.Textkernel1__SearchResultIds__c);
            this.showSpinner = true;
            this.receivedEvents = [...this.receivedEvents, payload];
            // Ensure jobIds is correctly formatted
    this.jobIds = payload.Textkernel1__SearchResultIds__c
    ? payload.Textkernel1__SearchResultIds__c.split(',').map(id => id.trim())
    : [];
    this.contactIds = payload.Textkernel1__SearchFromId__c;
            this.actionType = 'job';
            this.setColumns();

        }
        
    };

    
    subscribe(this.channelName, -1, messageCallback).then((response) => {
        console.log('Subscription Successful:', response);
        this.subscription = response;
    });
}

setColumns() {
    if (this.actionType === 'job') {
        this.columns = [
            { label: 'Job Name', fieldName: 'JobName', type: 'text' },
            {
                label: 'Status',
                fieldName: 'Status',
                type: 'text',
                cellAttributes: {
                    iconName: { fieldName: 'iconName' },
                    class: { fieldName: 'iconClass' },
                    iconPosition: 'left',
                    variant: { fieldName: 'iconVariant' },
                    alternativeText: 'Status',
                    title: 'Status'
                }
            }
        ];
    } else {
        this.columns = [
            { label: 'Name', fieldName: 'Name', type: 'text' },
            { label: 'Email', fieldName: 'Email', type: 'email' },
            {
                label: 'Status',
                fieldName: 'Status',
                type: 'text',
                cellAttributes: {
                    iconName: { fieldName: 'iconName' },
                    class: { fieldName: 'iconClass' },
                    iconPosition: 'left',
                    variant: { fieldName: 'iconVariant' },
                    alternativeText: 'Status',
                    title: 'Status'
                }
            }
        ];
    }
}

handleUnsubscribe() {
    if (this.subscription && this.subscription.id) {
        unsubscribe(this.subscription, (response) => {
            console.log('Unsubscribed successfully:', response);
        });
    }
}

registerErrorListener() {
    onError((error) => {
        console.error('Received error from server:', error);
    });
}

    

async openModal() {
    if (!this.isConnected) {
        console.warn('Component is disconnected. Skipping modal open.');
        return;
    }
    try {
        console.log('Opening modal...'); // Debugging step
        console.log('Attempting to open modal...', PortalActionModal);
        this.modalInstance = null; 
        const result = await PortalActionModal.open({
            size: 'small',
            contactData: this.actionType === 'job' ? [...this.jobData] : [...this.contactData],
            columns: this.columns,
            showSpinner: this.showSpinner,
            addToJob: () => this.handleAddToJob(),
            addToLongList: () => this.handleAddToLongList(),
            addToCallList: () => this.handleAddToCallList()
            
       });

        console.log('Modal opened successfully:', result);
        if( result==='Reopen')
        {this.handleReopen();}

    } catch (error) {
        console.error('Error opening modal:', JSON.stringify(error, Object.getOwnPropertyNames(error)));
    }
}

async handleAddToLongList(){
    await saveLonglistRecords({ contactIds: this.contactIds, jobIds:this.actionType==='job'?this.jobIds: this.jobId })
    .then((result) => {
        this.updateContactStatus(result);
                })
    .catch((error) => {
        //this.updateContactStatus(error); 
        console.log('Save Error longlist:', JSON.stringify(error, Object.getOwnPropertyNames(error))); // Log more details of the error
        this.showToast('Error', `Failed to save longlist: ${error?.body?.message || 'Unknown error'}`, 'error');})
    .finally(() => this.showSpinner = false); 
}

async handleAddToJob() {
    this.showSpinner = true;

   await saveApplications({ contactIds: this.contactIds, jobIds:this.actionType==='job'?this.jobIds: this.jobId })
        .then((result) => {
            this.updateContactStatus(result);
                    })
        .catch((error) => {
            //this.updateContactStatus(error); 
            console.log('Save Error:', JSON.stringify(error, Object.getOwnPropertyNames(error))); // Log more details of the error
            this.showToast('Error', `Failed to save applications: ${error?.body?.message || 'Unknown error'}`, 'error');})
        .finally(() => this.showSpinner = false);
}

publishAction(actionType) {
    const message = {
        action: actionType,
        params: { recordIds: this.contactData.map(contact => contact.Id) }
    };
    publish(this.messageContext, contactActionMC, message);
}

handleAddToCallList() {
    this.publishAction('Add to Call List');
}



/* updateContactStatus(result) {   
    // Ensure result is defined and has elements
    if (Array.isArray(result) && result.length > 0) {
        this.contactData = this.contactData.map(contact => {
            // Find the result corresponding to this contact
            const match = result.find(r => r.contactId === contact.Id);  // Update here

            // Check if match is found, then update contact status
            return match ? {
                ...contact,
                Status: match.message,
                iconName: match.status === 'Success' ? 'utility:success' : 'utility:error',
                iconClass: match.status === 'Success' ? 'slds-icon-text-success' : 'slds-button_icon-error',
                iconVariant: match.status === 'Success' ? 'success' : 'error',
                message:match.message
            } : contact;  // Return the contact as is if no match is found
        });
    } else {
        console.error("Result is empty or not an array:", result);
    }

    // Ensure the contactData is updated correctly
    this.contactData = [...this.contactData];
    
}*/

updateContactStatus(result) {
    if (Array.isArray(result) && result.length > 0) {
        // Call helper method based on action type
        if (this.actionType === 'job') {
            this.jobData = this.updateStatusForActionType(result, 'job');
        } else if (this.actionType === 'candidate') {
            this.contactData = this.updateStatusForActionType(result, 'candidate');
        }
    } else {
        console.error("Result is empty or not an array:", result);
        this.showToast('Error', 'Failed to update statuses. Invalid result format.', 'error');
    }

    // Ensure the appropriate data is updated correctly (trigger reactivity in LWC)
    if (this.actionType === 'job') {
        this.jobData = [...this.jobData];
    } else if (this.actionType === 'candidate') {
        this.contactData = [...this.contactData];
    }
}

// Helper method to update status for job or candidate action
updateStatusForActionType(result, type) {
    if (type === 'job') {
        return this.jobData.map(job => {
            const match = result.find(r => r.jobId === job.Id);
            if (match) {
                return {
                    ...job,
                    Status: match.message || 'Unknown',
                    iconName: match.status === 'Success' ? 'utility:success' : 'utility:error',
                    iconClass: match.status === 'Success' ? 'slds-icon-text-success' : 'slds-icon-text-error',
                    iconVariant: match.status === 'Success' ? 'success' : 'error',
                    message: match.message || 'No message available'
                };
            }
            return job;
        });
    } else if (type === 'candidate') {
        return this.contactData.map(contact => {
            const match = result.find(r => r.contactId === contact.Id);
            if (match) {
                return {
                    ...contact,
                    Status: match.message || 'Unknown',
                    iconName: match.status === 'Success' ? 'utility:success' : 'utility:error',
                    iconClass: match.status === 'Success' ? 'slds-icon-text-success' : 'slds-icon-text-error',
                    iconVariant: match.status === 'Success' ? 'success' : 'error',
                    message: match.message || 'No message available'
                };
            }
            return contact;
        });
    }
    return [];
}


handleReopen() {
    console.log('Reopen Action called');    
   this.openModal(); // Reopen modal with updated data
    
}



showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({
        title,
        message,
        variant
    }));
}
}