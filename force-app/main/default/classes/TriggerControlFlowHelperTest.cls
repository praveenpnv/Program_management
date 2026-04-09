@isTest
public class TriggerControlFlowHelperTest {

    @isTest
    static void testSetBypass() {
        // Arrange
        List<String> flowLabels = new List<String>{'Flow A', 'Flow B'};

        // Act
        TriggerControlFlowHelper.setBypass(flowLabels);

        // Assert
        for (String label : flowLabels) {
            System.assertEquals(true, TriggerBypassUtil.bypassedFlows.contains(label), 
                'Expected flow label to be in bypass set: ' + label);
        }
    }

    @isTest
    static void testSetBypassWithEmptyList() {
        // Arrange
        TriggerBypassUtil.bypassedFlows.clear(); // Ensure clean state

        // Act
        TriggerControlFlowHelper.setBypass(new List<String>());

        // Assert
        System.assertEquals(0, TriggerBypassUtil.bypassedFlows.size(), 
            'Bypassed flows set should remain empty');
    }
}