import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTasksByCriteria from '@salesforce/apex/TaskController.getTasksByCriteria';
import upsertTaskDescription from '@salesforce/apex/TaskController.upsertTaskDescription';

export default class TaskManager extends LightningElement {
    @api recordId; // Parent ID
    @track taskId;
    @track taskDescription = '';
    @track isEditingDescription = false;
    @api subject; // Subject, passed from Flow
    @api recordTypeName = 'Power_Notes'; // Record type developer name
    @track error;
    @api isReadOnly;
    activeSection = 'TaskDetails'; // Default active section

    connectedCallback() {
        console.log('Component initialized');
        console.log('Record ID:', this.recordId);
        console.log('Subject:', this.subject);
        this.loadTask();
    }

    loadTask() {
        getTasksByCriteria({ applicationId: this.recordId, subject: this.subject, recordTypeName: this.recordTypeName })
            .then(task => {
                if (task) {
                    this.taskId = task.Id;
                    this.taskDescription = task.Description;
                        console.log('Task ID:', this.taskId);
                        console.log('Task Description:', this.taskDescription);
                } else {
                    this.taskId = null;
                    this.taskDescription = '';
                        console.log('No task found.');
                }
            })
            .catch(error => {
                this.error = error;
                console.error('Error retrieving Task:', error);
            });
    }


@api
   handleSaveDescription() {
    upsertTaskDescription({
        taskId: this.taskId,
        description: this.taskDescription,
        applicationId: this.recordId,
        subject: this.subject,
        recordTypeName: this.recordTypeName
    })
    .then(() => {
        this.isEditingDescription = false;
        this.loadTask(); // Reload task to reflect changes
        console.log('Task updated successfully!');
        const event = new CustomEvent('tasksuccess', { detail: { message: 'Task updated successfully!' } });
        this.dispatchEvent(event); // Dispatch 'tasksuccess' event
    })
    .catch(error => {
        const event = new CustomEvent('taskerror', { detail: { message: error.body.message } });
        this.dispatchEvent(event); // Dispatch 'taskerror' event
        console.error('Error updating task:', error);
    });
}

    handleDescriptionChange(event) {
        this.taskDescription = event.target.value;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }
}