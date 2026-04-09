import { LightningElement, wire, track, api } from 'lwc';
import getAvailableUsers from '@salesforce/apex/ManagerTeamController.getAvailableUsers';
import getTeamMembers from '@salesforce/apex/ManagerTeamController.getTeamMembers';
import addToTeam from '@salesforce/apex/ManagerTeamController.addToTeam';
import removeFromTeam from '@salesforce/apex/ManagerTeamController.removeFromTeam';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import userId from '@salesforce/user/Id';

export default class ManagerTeam extends LightningElement {
    @track users = [];
    @track teamMembers = [];
    searchKey = '';
    pageNumber = 1;
    pageSize = 20;

    wiredUsers;
    wiredTeam;
    draggedUserId;
    subscription = {};
    // The channel name for a custom object is /data/ObjectName__ChangeEvent
    channelName = '/data/Manager_Team_Member__ChangeEvent';

    // Customizable labels
    @api parentlabel;
    @api label;
    @api type;
    @api sublabel;
    
    @api selectedUserId; // SUPER USER selected user from parent

    // computed userId → if parent didn’t set, fallback to logged-in user
    get effectiveUserId() {
        return this.selectedUserId || userId;
    }

    connectedCallback() {
        //this.registerErrorListener();
        this.handleSubscribe();
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    handleSubscribe() {
        const messageCallback = (response) => {
            console.log('New message received: ', JSON.stringify(response));
            // A change has occurred, refresh both lists
            refreshApex(this.wiredUsers);
            refreshApex(this.wiredTeam);
        };

        subscribe(this.channelName, -1, messageCallback).then(response => {
            console.log('Subscription request sent to: ', JSON.stringify(response.channel));
            this.subscription = response;
        });
    }
    
    // Fetch available users
    @wire((getAvailableUsers), { type: '$type' , currentUserId: '$effectiveUserId'})
    wiredAvailable(result) {
        this.wiredUsers = result;
        if (result.data) {
            this.users = result.data;
        }
    }

        // Fetch team members
        @wire(getTeamMembers, { type: '$type' , currentUserId: '$effectiveUserId'})
        wiredTeamMembers(result) {
            this.wiredTeam = result;
            if (result.data) {
                this.teamMembers = result.data;
            } else if (result.error) {
                console.error('Error loading team members', result.error);
            }
        }


    // Filtering + pagination
    get filteredUsers() {
        if (!this.searchKey) return this.users;
        return this.users.filter(u =>
            u.Name.toLowerCase().includes(this.searchKey.toLowerCase())
        );
    }

    get totalPages() {
        return Math.ceil(this.filteredUsers.length / this.pageSize) || 1;
    }

    get pagedUsers() {
        const start = (this.pageNumber - 1) * this.pageSize;
        return this.filteredUsers.slice(start, start + this.pageSize);
    }

    get isFirstPage() {
        return this.pageNumber === 1;
    }

    get isLastPage() {
        return this.pageNumber >= this.totalPages;
    }

    handleSearchChange(event) {
        this.searchKey = event.target.value;
        this.pageNumber = 1;
    }

    handleNext() {
        if (!this.isLastPage) this.pageNumber++;
    }

    handlePrev() {
        if (!this.isFirstPage) this.pageNumber--;
    }

    // Drag & Drop
    handleDragStart(event) {
        this.draggedUserId = event.currentTarget.dataset.id;
    }

    allowDrop(event) {
        event.preventDefault();
    }

    // Add to team
    async handleDrop(event) {
        event.preventDefault();
        try {
            await addToTeam({ userId: this.draggedUserId , type:this.type , currentUserId: this.effectiveUserId });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'User added to your team',
                variant: 'success'
            }));
            // We no longer need to manually refresh, CDC will trigger it.
    
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Warning',
                message: error.body?.message || 'User already in your team',
                variant: 'warning'
            }));
        }
    }

    // Remove from team
    async handleRemoveDrop(event) {
        event.preventDefault();
        try {
            await removeFromTeam({ userId: this.draggedUserId , type:this.type , currentUserId: this.effectiveUserId });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'User removed from your team',
                variant: 'success'
            }));
            // We no longer need to manually refresh, CDC will trigger it.
            // refreshApex(this.wiredTeam);
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: error.body?.message || 'Unable to remove user',
                variant: 'error'
            }));
        }
    }

    handleUnsubscribe() {
        unsubscribe(this.subscription, response => {
            console.log('unsubscribe() response: ', JSON.stringify(response));
        });
    }

    registerErrorListener() {
        onError(error => {
            console.log('Received error from server: ', JSON.stringify(error));
            this.dispatchEvent(new ShowToastEvent({
                title: 'Streaming Error',
                message: 'An error occurred with real-time updates. Please refresh the page.',
                variant: 'error'
            }));
        });
    }
}