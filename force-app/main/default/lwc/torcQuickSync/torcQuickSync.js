import { LightningElement, api } from 'lwc';
import setSyncTime from '@salesforce/apex/JobMatchController.setSyncTime';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TorcQuickSync extends LightningElement {
  @api recordId;

  async handleClick() {
    await this.run();
  }

  // Supports headless Quick Action too
  @api async invoke() {
    await this.run();
  }

  async run() {
    try {
      await setSyncTime({ recordId: this.recordId });
      // SUCCESS: reload whole page
      window.location.reload();
    } catch (e) {
      // ERROR: show toast, no reload
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Sync failed',
          message: this.reduceError(e),
          variant: 'error'
        })
      );
    }
  }

  reduceError(err) {
    // Normalizes Apex/LDS errors to a readable string
    if (Array.isArray(err?.body)) {
      return err.body.map(e => e.message).join(', ');
    }
    return err?.body?.message || err?.message || 'Unknown error';
  }
}