import { LightningElement, api, track } from 'lwc';
import searchUsers from '@salesforce/apex/ProjectPlatformController.searchUsers';

export default class UserLookup extends LightningElement {
    @api label      = 'User';
    @api placeholder = 'Search by name or email…';
    @api required   = false;
    @api readonly   = false;

    
    @api
    set value(val) {
        this._selected = val || null;
        this._searchTerm = '';
    }
    get value() { return this._selected; }

    @track _selected   = null;
    @track _searchTerm = '';
    @track _results    = [];
    @track _open       = false;
    @track _searching  = false;
    _debounce          = null;

    get hasSelection()   { return !!this._selected; }
    get hideInput()      { return this.readonly && this.hasSelection; }
    get showDropdown()   { return this._open && !this.hasSelection; }
    get hasResults()     { return this._results.length > 0; }
    get isSearching()    { return this._searching; }
    get searchTerm()     { return this._searchTerm; }
    get results()        { return this._results; }
    get selectedName()   { return this._selected?.name  || ''; }
    get selectedPhoto()  { return this._selected?.photo || null; }
    get selectedTitle()  { return this._selected?.title || null; }
    get selectedInitials() {
        const n = this._selected?.name || '';
        return n.split(' ').map(w => w[0]).slice(0,2).join('').toUpperCase();
    }

    handleInput(e) {
        this._searchTerm = e.target.value;
        clearTimeout(this._debounce);
        if (!this._searchTerm || this._searchTerm.length < 2) {
            this._results = [];
            this._open = false;
            return;
        }
        this._searching = true;
        this._open = true;
        this._debounce = setTimeout(() => this._doSearch(this._searchTerm), 300);
    }

    handleFocus() {
        if (this._searchTerm && this._results.length) this._open = true;
    }

    handleBlur() {
        
        setTimeout(() => { this._open = false; }, 200);
    }

    handleSelect(e) {
        const id = e.currentTarget.dataset.id;
        const u  = this._results.find(r => r.id === id);
        if (!u) return;
        this._selected   = u;
        this._searchTerm = '';
        this._results    = [];
        this._open       = false;
        this.dispatchEvent(new CustomEvent('select', {
            detail: { id: u.id, name: u.name, photo: u.photo, title: u.title }
        }));
    }

    handleClear() {
        this._selected = null;
        this.dispatchEvent(new CustomEvent('clear'));
    }

    async _doSearch(term) {
        try {
            const raw = await searchUsers({ searchTerm: term });
            this._results = (raw || []).map(u => ({
                id:       u.id,
                name:     u.name,
                email:    u.email,
                title:    u.title || '',
                photo:    u.photo || null,
                initials: (u.name || '').split(' ').map(w => w[0]).slice(0,2).join('').toUpperCase(),
            }));
        } catch(err) {
            this._results = [];
        } finally {
            this._searching = false;
        }
    }
}