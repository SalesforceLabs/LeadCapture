@isTest
private class SalesforceLeadCaptureControllerTest {
    @isTest           
    public static void test() {
      SalesforceLeadCaptureController myClass = new SalesforceLeadCaptureController();
      System.debug('Is sandbox: ' + myClass.getIsSandbox());
    }
}