/*
 * A custom controller for our Visualforce page. The sole purpose of this controller is
 * allow our Visualforce page to have access the IsSandbox property of the current org 
 * so that it can provide this information to our backend. 
 *
 * This property can only be accessed by executing a SOQOL query (it's not available in 
 * the global $Organization class as of Saleforce v37). But a Visualforce page cannot 
 * contain Apex code - it can only access properties of its controller. Hence this class.
 * 
 * Doc on custom controllers: https://developer.salesforce.com/docs/atlas.en-us.pages.meta/pages/pages_controller_custom.htm
 *
 * *** How to create / edit this class in Salesforce ***
 *
 * 1. Login to the appropriate Developer Edition Salesforce org for the environment you're working on
 * (see the Lead Capture doc site for the list of Dev Ed orgs we use: https://github.exacttarget.com/pages/ad-studio/lead-ingestion/salescloud-accounts.html)
 *
 * 2. In Classic Experience: navigate to Setup -> Build -> Develop -> Apex classes.
 * 
 * 3. Create or edit.
 *
 *  *** How to test this code in Salesforce ***
 * In Classic experience: click your username -> Developer Console -> Debug -> Open Execute Anonymous Window -> copy / paste the code you
 * want to run and click Execute. 
 * 
 * You can also test the SOQOL query alone in the "Query Editor" tab of the Developer Console.
 */

public with sharing class SalesforceLeadCaptureController {

    private final boolean isSandbox;

    public SalesforceLeadCaptureController() {
        isSandbox = [select isSandbox from Organization limit 1].isSandbox;
    }

    public boolean getIsSandbox() {
        return isSandbox;
    }
}