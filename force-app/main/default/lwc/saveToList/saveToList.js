import { api, track, LightningElement } from 'lwc';
import { ShowToastEvent }               from 'lightning/platformShowToastEvent';
import { NavigationMixin }              from 'lightning/navigation';
import saveRecordsToList                from '@salesforce/apex/SaveToListController.saveRecordsToList';
import getSearchFromLookups             from '@salesforce/apex/SaveToListController.getSearchFromLookups';
import getFieldSetFields                from '@salesforce/apex/SaveToListController.getFieldSetFields';

export default class SaveToList extends NavigationMixin(LightningElement) {
	// init platform event payload
	@api platformEvent;

	// variable that indicate that all connectedCollback actions done
	@track isConnected = false;

	// variable that indicate some processing actions
	@track processing = true;

	openAfterSave = false;

	// default Save to List mode
	mode = 'exist';

	get options() {
		return [
			{ label: 'Add to existing List', value: 'exist' },
			{ label: 'Create new List',      value: 'new'   }
		];
	}

	// list of fields specified in fieldset
	fields = [{'path': 'Name'}];

	connectedCallback() {
		try {
			let promiseAll = [
				this.getLookups(),
				this.getFields()
			];

			Promise.all(promiseAll).then((results) => {
				// add lookup fields (used as 'search from') to form field list
				if (results[0]) {
					const lookupForObject = [];
					if (this.getSearchFromRecordId()) {
						for (const objectApiName in results[0]) {
							if (objectApiName === this.getSearchFromRecordApiName()) {
								lookupForObject.push({ object: objectApiName, path: results[0][objectApiName], dataId: 'searchForReference'});
							}
						}

						if (lookupForObject.length === 0) {
							for (const objectApiName in results[0]) {
								lookupForObject.push({ object: objectApiName, path: results[0][objectApiName]});
							}
						}
					} else {
						for (const objectApiName in results[0]) {
							lookupForObject.push({ object: objectApiName, path: results[0][objectApiName]});
						}
					}

					if (lookupForObject.length > 0) {
						this.fields = this.fields.concat(lookupForObject);
					}
				}

				// add fields from fieldset
				// noinspection JSUnresolvedVariable
				if (results[1] && results[1].length > 0) {

					const filteredFieldSetFields = [];

					// check if field not in list
					// noinspection JSUnresolvedFunction
					results[1].forEach(fieldsetField => {

						let alreadyExists = false;

						if (this.fields && this.fields.length > 0) {
							this.fields.forEach(lookupField => {
								if (lookupField.path === fieldsetField.path) {
									lookupField.required = fieldsetField.required;
									alreadyExists = true;
								}
							});
						}

						if (!alreadyExists) {
							filteredFieldSetFields.push(fieldsetField);
						}
					});

					if (filteredFieldSetFields.length > 0) {
						this.fields = this.fields.concat(filteredFieldSetFields);
					}
				}

				this.isConnected = true;
				this.processing = false;
			}).catch(error => {
				console.error(error);
				this.showErrorToast('Error while getting  fileds');
			});
		} catch (e) {
			console.error(e);
		}
	}

	getSearchFromRecordId() {
		try {
			if (this.platformEvent?.Textkernel1__SearchFromApiName__c && this.platformEvent?.Textkernel1__SearchFromId__c) {
				return this.toValidId(this.platformEvent.Textkernel1__SearchFromId__c);
			}
		} catch(e) {
			console.error(e);
		}
	}

	toValidId = id => id.split('_').pop();

	getSearchFromRecordApiName() {
		try {
			if (this.platformEvent?.Textkernel1__SearchFromId__c) {
				return this.platformEvent.Textkernel1__SearchFromApiName__c;
			}
		}
		catch(e) {
			console.error(e);
		}
	}

	getLookups() {
		try {
			return new Promise(function (resolve, reject) {
				getSearchFromLookups()
					.then(result => {
						resolve(JSON.parse(result));
					})
					.catch(error => {
						reject(error);
					});
			});
		}
		catch(e) {
			console.error(e);
		}
	}

	getFields() {
		try {
			return new Promise(function (resolve, reject) {
				getFieldSetFields()
					.then(result => {
						// console.log('getFieldSetFields', JSON.parse(result));
						resolve(JSON.parse(result));
					})
					.catch(error => {
						reject(error);
					});
			});
		}
		catch(e) {
			console.error(e);
		}
	}

	saveAndOpen() {
		this.openAfterSave = true;
		this.save();
	}

	save() {
		try {
			if (this.getListMode() === 'new') {
				const newListForm = this.template.querySelector('[data-id="newListForm"]')
				if (newListForm) {

					let isValid = true;

					this.template.querySelectorAll('lightning-input-field').forEach(field => {
						field.reportValidity();
						if (field.required && !field.value) {
							isValid = false;
						}
					});

					if (isValid) {
						this.processing = true;
						newListForm.submit();
						//this.showSuccessToast('Successfully added to a new list');
					} else {
						this.showErrorToast('Please populate all required fields');
					}
				}
			} else if (this.getListMode() === 'exist') {
				const existingListIdInput = this.template.querySelector('[data-id="existingListId"]')
				if (existingListIdInput && existingListIdInput.value) {
					this.saveListItems(existingListIdInput.value, this.platformEvent['Textkernel1__SearchResultIds__c'].split(','));
				} else {
					this.showErrorToast('Please select an existing list.')
				}
			}
		} catch (e) {
			console.error(e);
		}
	}

	handleCancel() {
		try {
			this.dispatchEvent(new CustomEvent('close'));
		} catch (e) {
			console.error(e);
		}
	}

	saveListItems(listId, recordIds) {
		try {
			this.processing = true;
			saveRecordsToList({ listId, recordIds })
				.then(() => {
					if (this.openAfterSave) {
						this.openList(listId);
					}
					this.showSuccessToast('Successfully added to list Id: ' + listId)
					// fire event to close modal
					this.dispatchEvent(new CustomEvent('close'));
				})
				.catch(error => {
					this.showErrorToast(error);
				})
				.finally(() => this.processing = false);
		}
		catch(e) {
			console.error(e);
		}
	}

	openList(recordId) {
		try {
			this[NavigationMixin.GenerateUrl]({
				'type': 'standard__recordPage',
				'attributes': {
					'recordId': recordId,
					'actionName': 'view',
				},
			}).then(url => {
				// open in current tab
				// window.location.href = url;
				// open in new tab
				window.open(url, '_blank');
			});
		}
		catch(e) {
			console.error(e);
		}
	}

	showErrorToast(error) {
		try {
			console.error(error);

			let message = '';

			if (typeof error === 'string') {
				message = error;
			} else {
				try {
					if (error.body) {
						// noinspection JSUnresolvedVariable
						if (
							error.body &&
							error.body.pageErrors &&
							error.body.pageErrors instanceof Array
						) {
							error.body.pageErrors.forEach((pageError) => {
								message += pageError.message;
							});
						}

						// noinspection JSUnresolvedVariable
						if (
							error.body &&
							error.body.fieldErrors &&
							error.body.fieldErrors instanceof Array
						) {
							error.body.fieldErrors.forEach((fieldError) => {
								message += fieldError.message;
							});
						}

						if (error.body.message) {
							message += error.body.message;
						}
					}
					else if (error.message) {
						message += error.message;
					}
					else {
						message += "Unknown error";
					}
				} catch (e) {
					console.warn(e);
					message += JSON.stringify(error);
				}
			}

			const evt = new ShowToastEvent({
				title: 'Error',
				message: message,
				variant: 'error',
				mode: 'dismissable'
			});
			this.dispatchEvent(evt);
		}
		catch(e) {
			console.error(e);
		}
	}

	showSuccessToast(msg) {
		const evt = new ShowToastEvent({
			title: 'Success',
			message: msg,
			variant: 'success',
			mode: 'dismissable'
		});
		this.dispatchEvent(evt);
	}

	modeChanged(event) {
		this.mode = event.detail.value;
		this.processing = true;
	}

	getListMode() {
		return this.mode;
	}

	get newListMode() {
		return this.getListMode() === 'new';
	}

	newListFormLoaded() {
		this.processing = false;

		if (this.getSearchFromRecordId()) {
			const referenceFieldInput = this.template.querySelector('[data-id="searchForReference"]');
			if (referenceFieldInput) {
				referenceFieldInput.value = this.getSearchFromRecordId();
			}
		}
	}

	newListFormOnSuccess(event) {
		if (event && event.detail && event.detail.id) {
			this.saveListItems(event.detail.id, this.platformEvent['Textkernel1__SearchResultIds__c'].split(','));
		}
	}

	existingListsFormLoaded() {
		this.processing = false;
	}

	onError(event) {
		console.error(event.detail.message);
		this.showErrorToast(event.detail.message);
	}
}