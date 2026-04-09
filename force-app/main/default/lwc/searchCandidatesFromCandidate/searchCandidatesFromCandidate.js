import {api, LightningElement} from 'lwc';
import getExternalId           from '@salesforce/apex/DSUtils.getExternalId';
import { NavigationMixin }     from 'lightning/navigation';

const tabPath = 'selectedTab=candidateSearch';
const candidateIdPatch = 'candidateId=';

export default class SearchCandidatesFromCandidate extends NavigationMixin(LightningElement) {

    _recordId;

    @api set recordId(value) {
        this._recordId = value;
        this.searchInPortal();
    }

    get recordId() { return this._recordId; }

    get matchQuery() {
        return this.recordId ? `${candidateIdPatch}${this.recordId}&${tabPath}` : '';
    }

    parseQuery() {
        const params = this.matchQuery.split('&');
        const match = params.find(param => param.startsWith(candidateIdPatch));

        if (match) {
            const [key, value] = match.split('=');
            return { key, value };
        }
        return { key: undefined, value: undefined };
    }

    async handleRedirect(name, value) {
        try {
            const externalId = await getExternalId({'recordId': this.recordId});
            const fixedMatchQuery = this.matchQuery.replace(value, encodeURIComponent(externalId));
            this.navigateToPortal(fixedMatchQuery);
        } catch (error) {
            this.showErrorToast('Can\'t find external Id for ' + value);
            this.close();
        }
    }

    async searchInPortal() {
        try {
            if (this.matchQuery) {
                const {key, value} = this.parseQuery();

                if (key && value) {
                    await this.handleRedirect(key, value);
                } else {
                    this.displayError();
                }
            }
        } catch (e) {
            this.handleFailedSearch(e);
        }
    }

    displayError() {
        const errorMessage = 'Cant find candidateId param in match query: ' + this.matchQuery;
        this.createErrorLog(errorMessage);
        this.showErrorToast(errorMessage);
        this.close();
    }

    handleFailedSearch(error) {
        console.error(error);
        this.createErrorLog(error);
        this.showErrorToast('Search Error', error, this);
    }

    navigateToPortal(queryParams) {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Textkernel1__TextkernelPortal'
            },
            state: {
                'Textkernel1__match_query': queryParams
            }
        });
    }
}