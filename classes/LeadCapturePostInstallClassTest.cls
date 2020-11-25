// Test for the post install class
@isTest
private class LeadCapturePostInstallClassTest {
    @isTest           
    public static void test() {
      LeadCapturePostInstallClass myClass = new LeadCapturePostInstallClass();
      Test.testInstall(myClass, null);
    }
}