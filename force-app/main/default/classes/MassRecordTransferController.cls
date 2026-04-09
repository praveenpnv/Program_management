/**
 * @File Name: MassRecordTransferController.cls
 * @Description: Controller for mass transferring records from one user to another.
 *              Contains a single Invocable Method to be used by a Flow.
 * @Author: Priyanka Singh
 * @Created On: Aug 27, 2025
 * @Modified On: 
 * @Modified By:
 */
public with sharing class MassRecordTransferController {

    // ────────────────────────────────────────────────────────────
    // INVOCABLE METHOD
    // ────────────────────────────────────────────────────────────

    @InvocableMethod(
        label='Perform Mass Transfer Action'
        description='Validates or initiates mass record transfer between users.'
        category='Record Transfer'
    )
    public static List<FlowResponse> performAction(List<FlowRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new FlowException('No request provided');
        }

        FlowRequest request = requests[0];
        FlowResponse response = new FlowResponse();

        try {
            if (request.action == 'VALIDATE') {
                ValidationResult result = validateTransfer(request.fromUserId, request.toUserId);
                response.isValid = result.isValid;
                response.message = result.message;
                
            } else if (request.action == 'INITIATE') {
                String jobId = initiateTransfer(request.fromUserId, request.toUserId);
                response.isValid = true;
                response.jobId = jobId;
                response.message = buildInitiationMessage(request.fromUserId, request.toUserId);
                
            } else {
                throw new FlowException('Invalid action: ' + request.action + '. Expected VALIDATE or INITIATE.');
            }
        } catch (FlowException e) {
            throw e;
        } catch (Exception e) {
            throw new FlowException('Unexpected error: ' + e.getMessage());
        }

        return new List<FlowResponse>{ response };
    }

    // ────────────────────────────────────────────────────────────
    // VALIDATION LOGIC
    // ────────────────────────────────────────────────────────────

    private static ValidationResult validateTransfer(Id fromUserId, Id toUserId) {
        ValidationResult result = new ValidationResult();

        // Check for null IDs
        if (fromUserId == null || toUserId == null) {
            result.isValid = false;
            result.message = '⚠ Error: Both source and target users must be selected.';
            return result;
        }

        // Check if users are the same
        if (fromUserId == toUserId) {
            result.isValid = false;
            result.message = '⚠ Error: Source and target users cannot be the same. Please select different users.';
            return result;
        }

        // Verify both users exist and are active
        Map<Id, User> usersById = new Map<Id, User>([
            SELECT Id, IsActive, Name, Profile.Name
            FROM User
            WHERE Id IN :new Set<Id>{fromUserId, toUserId}
        ]);

        if (!usersById.containsKey(fromUserId)) {
            result.isValid = false;
            result.message = '⚠ Error: Source user not found. Please select a valid user.';
            return result;
        }

        if (!usersById.containsKey(toUserId)) {
            result.isValid = false;
            result.message = '⚠ Error: Target user not found. Please select a valid user.';
            return result;
        }

        User fromUser = usersById.get(fromUserId);
        User toUser = usersById.get(toUserId);

        if (!fromUser.IsActive) {
            result.isValid = false;
            result.message = '⚠ Error: Source user "' + fromUser.Name + '" is inactive. Please select an active user.';
            return result;
        }

        if (!toUser.IsActive) {
            result.isValid = false;
            result.message = '⚠ Error: Target user "' + toUser.Name + '" is inactive. Please select an active user.';
            return result;
        }

        // Success message with user details
        result.isValid = true;
        result.message = '✓ Validation successful!\n\n' +
                        'Ready to transfer records:\n' +
                        '  From: ' + fromUser.Name + ' (' + fromUser.Profile.Name + ')\n' +
                        '  To: ' + toUser.Name + ' (' + toUser.Profile.Name + ')\n\n' +
                        'Click "Transfer Records" to begin the process.';

        return result;
    }

    // ────────────────────────────────────────────────────────────
    // INITIATION LOGIC
    // ────────────────────────────────────────────────────────────

    private static String initiateTransfer(Id fromUserId, Id toUserId) {
        // Validate before initiating
        ValidationResult validation = validateTransfer(fromUserId, toUserId);
        if (!validation.isValid) {
            throw new FlowException(validation.message);
        }

        try {
            // Execute batch job
            MassRecordTransferBatch batchJob = new MassRecordTransferBatch(fromUserId, toUserId);
            return Database.executeBatch(batchJob, 200);
            
        } catch (IllegalArgumentException e) {
            // Handle specific batch initialization errors
            throw new FlowException('⚠ Transfer cannot be started: ' + e.getMessage());
        } catch (Exception e) {
            throw new FlowException('⚠ Failed to start transfer: ' + e.getMessage());
        }
    }

    /**
     * @description Builds user-friendly initiation message
     */
    private static String buildInitiationMessage(Id fromUserId, Id toUserId) {
        Map<Id, User> usersById = new Map<Id, User>([
            SELECT Id, Name, Email
            FROM User
            WHERE Id IN :new Set<Id>{fromUserId, toUserId}
        ]);

        User fromUser = usersById.get(fromUserId);
        User toUser = usersById.get(toUserId);

        String message = '✓ Transfer Initiated Successfully!\n\n';
        message += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';
        message += 'Transfer Details:\n';
        message += '  From: ' + fromUser.Name + '\n';
        message += '  To: ' + toUser.Name + '\n\n';
        message += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n';
        message += 'What happens next:\n\n';
        message += '1. The system will identify all transferable objects\n';
        message += '   (objects with Private or Controlled-by-Parent sharing)\n\n';
        message += '2. Records will be processed in batches to ensure\n';
        message += '   reliability and avoid governor limits\n\n';
        message += '3. You will receive a detailed email report when\n';
        message += '   the transfer completes\n\n';
        message += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n';
        message += '📧 Email Report Will Include:\n';
        message += '  • Total records transferred\n';
        message += '  • Breakdown by object\n';
        message += '  • Detailed error information for any failures\n';
        message += '  • Specific record IDs that failed and why\n\n';
        message += '⏱ Estimated Time:\n';
        message += '  Processing time depends on the number of records.\n';
        message += '  You can close this screen - the process runs in the background.\n\n';
        message += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n';
        message += '⚠ Important Notes:\n';
        message += '  • Records locked in approval processes will be skipped\n';
        message += '  • Validation rules on the new owner will be enforced\n';
        message += '  • Triggers and flows will execute normally\n\n';
        message += 'Monitor the transfer via Setup → Apex Jobs\n';

        return message;
    }

    // ────────────────────────────────────────────────────────────
    // INNER CLASSES
    // ────────────────────────────────────────────────────────────

    public class FlowRequest {
        @InvocableVariable(required=true label='Action' description='VALIDATE or INITIATE')
        public String action;

        @InvocableVariable(label='From User ID' description='Source user ID')
        public Id fromUserId;

        @InvocableVariable(label='To User ID' description='Target user ID')
        public Id toUserId;
    }

    public class FlowResponse {
        @InvocableVariable(label='Is Valid' description='Whether validation passed')
        public Boolean isValid;

        @InvocableVariable(label='Message' description='User-friendly status message')
        public String message;

        @InvocableVariable(label='Job ID' description='Batch job ID (when initiated)')
        public String jobId;
    }

    private class ValidationResult {
        public Boolean isValid;
        public String message;
    }

    public class FlowException extends Exception {}
}