import {api, LightningElement} from 'lwc';
import getExternalId           from '@salesforce/apex/DSUtils.getExternalId';
import { NavigationMixin }     from 'lightning/navigation';

const tabPath = 'selectedTab=candidateSearch';
const jobIdPath = 'jobId=';

export default class RankApplicants extends NavigationMixin(LightningElement) {

    _recordId;

    @api set recordId(value) {
        this._recordId = value;
        this._matchQuery = this.buildMatchQuery();
        this.searchInPortal();
    }

    get recordId() { return this._recordId; }

    get matchQuery() {
        return this._matchQuery;
    }

    buildMatchQuery() {
        if (!this._recordId) { return ''; }

        let encodedParams =`job_submissions.job_id:${this._recordId}`;
        let baseUrl = `${jobIdPath}${this._recordId}&${tabPath}`;
        return `${baseUrl}&query=${encodedParams}`;
    }



    searchInPortal() {
        try {
            if (this.matchQuery) {
                const {key, value} = this.parseQuery();

                if (key && value) {
                    this.handleRedirect(key, value);
                } else {
                    this.displayError();
                }
            }
        } catch (e) {
            this.handleFailedSearch(e);
        }
    }

    handleFailedSearch(error) {
        console.error(error);
        this.createErrorLog(error);
        this.showErrorToast('Search Error', error, this);
    }

    parseQuery() {
        const params = this.matchQuery.split('&');
        const match = params.find(param => param.startsWith(jobIdPath));

        if (match) {
            const [key, value] = match.split('=');
            return { key, value };
        }
        return { key: undefined, value: undefined };
    }

    async handleRedirect(name, value) {
        try {
            const externalId = await getExternalId({'recordId': this.recordId});
            console.log('matchQuery', this.matchQuery);

            const fixedMatchQuery = this.matchQuery.replace(value, encodeURIComponent(externalId));
            console.log('fixedMatchQuery', fixedMatchQuery);
            this.navigateToPortal(fixedMatchQuery);
        } catch (error) {
            this.showErrorToast('Can\'t find external Id for ' + value);
            this.close();
        }
    }

    displayError() {
        const errorMessage = 'Cant find jobId param in match query: ' + this.matchQuery;
        this.createErrorLog(errorMessage);
        this.showErrorToast(errorMessage);
        this.close();
    }

    navigateToPortal(queryParams) {
        console.log('queryParams',queryParams);
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