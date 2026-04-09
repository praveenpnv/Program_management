@isTest
public class TriggerBypassUtilTest {

    @isTest
    static void testShouldBypassTrue() {
        // Arrange
        String flowLabel = 'Test Flow';
        TriggerBypassUtil.bypassedFlows.add(flowLabel);

        // Act
        Boolean result = TriggerBypassUtil.shouldBypass(flowLabel);

        // Assert
        System.assertEquals(true, result, 'The flow should be bypassed');
    }

    @isTest
    static void testShouldBypassFalse() {
        // Arrange
        String flowLabel = 'Nonexistent Flow';

        // Ensure the flow is not added to the bypass list
        TriggerBypassUtil.bypassedFlows.clear();

        // Act
        Boolean result = TriggerBypassUtil.shouldBypass(flowLabel);

        // Assert
        System.assertEquals(false, result, 'The flow should not be bypassed');
    }
}