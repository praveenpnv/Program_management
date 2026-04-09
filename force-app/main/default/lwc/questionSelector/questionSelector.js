import { LightningElement, wire, api } from 'lwc';
import getQuestionsGroupedByGrouping from '@salesforce/apex/QuestionTemplateController.getQuestionsGroupedByGrouping';
import checkSetupCompleted from '@salesforce/apex/QuestionTemplateController.checkSetupCompleted';
import saveSelectedQuestions from '@salesforce/apex/QuestionTemplateController.saveSelectedQuestions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class JobSetup extends LightningElement {
    @api recordId;

    groupedQuestions = [];
    error;
    isLoading = true;
    isSetupCompleted = false;
    preselectedRows = [];
    draftValues = [];
    selectedQuestion=[];
    columns = [
        { label: 'Question', fieldName: 'displayText', type: 'text' },
        { label: 'Mandatory', fieldName: 'Mandatory__c', type: 'boolean' },
        { label: 'Knockout', fieldName: 'KnockOut__c', type: 'boolean', editable: true }
    ];

    @wire(checkSetupCompleted, { jobOrderId: '$recordId' })
    wiredCheckSetupCompleted({ error, data }) {
        if (data) {
            this.isSetupCompleted = data;
        } else if (error) {
            this.error = error;
        }
    }

    @wire(getQuestionsGroupedByGrouping, { jobOrderId: '$recordId' })
    wiredQuestions({ error, data }) {
        if (data) {
            console.log('Data from Apex:', JSON.stringify(data));
            const userLocale = this.getUserLocale();
            this.groupedQuestions = Object.keys(data).map(key => {
                let processedQuestions = data[key].map(question => {
                    let displayText = this.getQuestionText(question, userLocale);
                    return { ...question, displayText };
                });

                let preselected = processedQuestions
                    .filter(question => question.Mandatory__c || (this.isSetupCompleted && this.isSelected(question.Id)))
                    .map(question => question.Id);
                this.preselectedRows = [...this.preselectedRows, ...preselected];

                return {
                    key: key,
                    value: processedQuestions,
                    visible: false // Initialize visibility to false
                };
            });
            console.log('Processed Grouped Questions:', JSON.stringify(this.groupedQuestions));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.groupedQuestions = undefined;
        }
        this.isLoading = false;
    }

    getUserLocale() {
        return navigator.language || navigator.userLanguage || 'en-US';
    }

    getQuestionText(question, userLocale) {
        if (userLocale !== 'en-US' && question.QuestionTextAlt__c) {
            return question.QuestionTextAlt__c;
        }
        return question.QuestionTextEN__c || question.QuestionTextAlt__c;
    }

    isSelected(questionId) {
        return this.preselectedRows.includes(questionId);
    }

    toggleGroupVisibility(event) {
        const groupName = event.currentTarget.dataset.group;
        const group = this.groupedQuestions.find(g => g.key === groupName);
        group.visible = !group.visible;
        // Force reactivity
        this.groupedQuestions = [...this.groupedQuestions];
    }

    handleSave(event) {
       const selectedRows = event.detail.selectedRows;
    console.log('Selected Rows:', JSON.stringify(selectedRows));

    // Combine selected rows with the existing selections, avoiding duplicates
    this.selectedQuestion = [...this.selectedQuestion, ...selectedRows];

    // Filter out duplicates by Id
    this.selectedQuestion = this.selectedQuestion.filter((value, index, self) =>
        index === self.findIndex((t) => t.Id === value.Id)
    );
     //this.preselectedRows = this.selectedQuestion.map(question => question.Id);
    
    console.log('Merged Selected Questions:', JSON.stringify(this.selectedQuestion));
}
        
    

    handleCompleteSetup() {
          // Get the latest selected rows directly from the table
    const selectedQuestionsFromTable = this.template.querySelector('lightning-datatable').getSelectedRows();

    // Combine the selected rows from the table with the existing selections
    let finalSelectedQuestions = [...this.selectedQuestion, ...selectedQuestionsFromTable];

    // Filter out duplicates by Id
    finalSelectedQuestions = finalSelectedQuestions.filter((value, index, self) =>
        index === self.findIndex((t) => t.Id === value.Id)
    );

    console.log('Final Selected Questions:', JSON.stringify(finalSelectedQuestions));
        if (finalSelectedQuestions.length > 0) {
             console.log('Enter in save ');
            saveSelectedQuestions({selectedQuestions:finalSelectedQuestions, jobOrderId: this.recordId })
                .then(() => {
                    this.showToast('Success', 'Questions saved successfully.', 'success');
                    this.isSetupCompleted = true;

                    // Update `preselectedRows` to reflect the completed setup
                //this.preselectedRows = finalSelectedQuestions.map(question => question.Id);
                })
                .catch(error => {
                    this.showToast('Error', 'An error occurred while saving questions.', 'error');
                });
        } else {
            this.showToast('Warning', 'No questions selected.', 'warning');
        }
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