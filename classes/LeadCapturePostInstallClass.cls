/*
 * Salesforce Apex post-install script for the Lead Capture Salesforce package.
 *
 * --- What does this do? ---
 * This scripts runs automatically after that Lead Capture for SalesCloud package has been 
 * installed or updated in a Salesforce org. It automatically creates a Permission Set 
 * that is configured with all the components that Lead Capture requires to run. 
 * 
 * The purpose of this Permission Set is to make it easier for a Salesforce Org Admin to grant
 * a user access to the Lead Capture app. Instead of having to grant the user access to all the 
 * individual Lead Capture components, the Org Admin can simply grant the user access to our 
 * Permission Set. 
 *
 * --- Post-install script docs ---
 * See https://help.salesforce.com/apex/HTViewHelpDoc?id=apex_post_install_script_intro.htm 
 * 
 * --- How to configure our SalesCloud package with this script ---
 * 
 * 1. Login to the Salesforce Developer Edition org where the Lead Capture components and package
 * for the environment you're configuring have been created (the "packaging org"). You'll find the 
 * details of all of our Salesforce Dev Edition orgs on our GitHub site 
 * (https://github.exacttarget.com/pages/ad-studio/lead-ingestion/salescloud-accounts.html at the 
 * time of writing).
 * 
 * 2. Update the constants in the script below with the correct values for your packaging org.
 * 
 * 3. In Classic Experience, navigate to Setup -> Build -> Develop -> Apex Classes and add this class 
 * (or edit it if it's already there).
 * 
 * 4. Also add the Test class (see the LeadCapturePostInstallScriptTest.apex file) as a separate class
 * in that same section. 
 * 
 * 5. Navigate to Build -> Create -> Packages, edit the Lead Capture package and pick this class as the
 * "Post Install Script" value.
 *
 * 6. If the package doesn't yet contain the Test class as part of its components, add the test class 
 * in the package's component (having a test class in the package itself is a requirement of the package
 * upload process. Salesforce will refuse to upload your package if you don't have a test class for your code).
 *
 * 7. Upload a new version of the package that will now contain your changes to the post-install script. 
 *
 * --- How to test that the script works ---
 *
 * Haven't found a good automated way to to this. To test manually:
 * 
 * 1. Implement your modifications to the script
 * 2. Upload a new Beta version of the Lead Capture package. 
 * 3. Login to another Salesforce org and install the package. Verify manually that the script did what it was
 * supposed to do.
 *
 * --- Is there a REPL to try out the Apex code without having to upload and install the package? ---
 * 
 * Yes. In Classic Experience, click your username on the top right-hand side and then Developer Console -> 
 * Debug -> Open Execute Anonymous Window -> copy/paste the code you want to execute in there -> Execute. 
 *
 * To view the Debug output after having run your script: in the Developer Console, click the "Logs"
 * tab at the bottom -> double-click the latest row in the list -> tick "Debug Only" to only display
 * the System.debug() output.
 *
 * You can also try out SOQOL queries in the "Query Editor" tab. 
 */

global class LeadCapturePostInstallClass implements InstallHandler  {
  global void onInstall(InstallContext context) {

    /***************************************************************
    /* Constants to update with the correct values for your packaging org
    /***************************************************************/

    // Name of your managed namespace (to find it in Classic Experience: Setup -> Build -> Create -> Packages->
    // Developer Settings -> Namespace Prefix)
    String NAMESPACE = 'leadcap';

    // Details of the Permission Set the post-install script will create. Leave as-it.
    String PERMISSIONSET_API_NAME = 'Salesforce_Lead_Capture';
    String PERMISSIONSET_DISPLAY_NAME = 'Salesforce Lead Capture';
    String PERMISSIONSET_DESCRIPTION = 'Grants access to the Salesforce Lead Capture application.';

    // Display name of the Lead Capture Connected App (to find it in Classic Experience: Setup -> Build -> 
    // Create -> Apps -> Connected Apps -> use the "Connected App Name" value of the Lead Capture app)
    String CONNECTED_APP_DISPLAY_NAME = 'Salesforce Lead Capture';

    // API name of the Lead Capture Visual Force Page (to find it in Classic Experience: Setup -> Build ->
    // Develop -> Visualforce Pages -> use the "Name" value of the Lead Capture page - don't forget the
    // underscore!) 
    String VISUALFORCEPAGE_API_NAME = 'Lead_Capture';

    // API name of the custom field used to store the Facebook Lead ID on the Lead object (to find it 
    // in Classic Experience: Setup -> Build -> Customize -> Leads -> Fields -> Lead Custom Fields & Relationships
    // -> use the "API Name" value of the Facebook Lead ID fiel)
    String FACEBOOKLEADID_CUSTOM_FIELD_API_NAME = 'leadcap__Facebook_Lead_ID__c';
  
    /***************************************************************
    /* End of packaging org-specific constants
    /***************************************************************/


    //-- Create our Permission Set if not already there. The Name property of the PermissionSet class is in fact its API Name. 
    // See https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_objects_permissionset.htm
    System.debug('Checking for existing Permission Set...');
    List<PermissionSet> existingPermSet = [SELECT Id FROM PermissionSet WHERE Name = :PERMISSIONSET_API_NAME LIMIT 1];
    
    PermissionSet permSet = null;

    if (existingPermSet.size() == 0) {
        System.debug('Creating Permission Set...');
        permSet = new PermissionSet();
        permSet.Label= PERMISSIONSET_DISPLAY_NAME;
        permSet.Name= PERMISSIONSET_API_NAME;
        permSet.Description = PERMISSIONSET_DESCRIPTION;
        insert permSet;
    }
    else {
        permSet = existingPermSet[0];
    }

    List<SetupEntityAccess> entityList = new List<SetupEntityAccess>();

    //-- Associate our Permission Set with our Connected App if that association doesn't already exist
    System.debug('Checking for existing Connected App association...');

    // The Name property of the ConnectedApplication class is the *display* name of the Connected App. 
    // See https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_objects_connectedapplication.htm 
    ConnectedApplication connectedApp = [SELECT Id FROM ConnectedApplication WHERE Name = :CONNECTED_APP_DISPLAY_NAME LIMIT 1];
    List<SetupEntityAccess> existingAssociation = [SELECT Id FROM SetupEntityAccess WHERE ParentId = :permSet.Id AND SetupEntityId =:connectedApp.Id LIMIT 1];

    if (existingAssociation.size() == 0) {
        System.debug('Creating Connected App association...');
        SetupEntityAccess app_se = new SetupEntityAccess();
        app_se.ParentId = permSet.Id;
        app_se.SetupEntityId = connectedApp.Id;
        entityList.add(app_se);
    }

    //-- Associate our Permission Set with our Visualforce Page if that association doesn't already exist
    System.debug('Checking for existing Visualforce Page association...');

    // The Name property if the ApexPage class is the API Name of the page.
    // See https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_objects_apexpage.htm
    ApexPage apexPage = [SELECT Id FROM ApexPage WHERE NamespacePrefix = :NAMESPACE AND Name = :VISUALFORCEPAGE_API_NAME LIMIT 1];
    existingAssociation = [SELECT Id FROM SetupEntityAccess WHERE ParentId = :permSet.Id AND SetupEntityId =:apexPage.Id LIMIT 1];

    if (existingAssociation.size() == 0) {
        System.debug('Creating Visualforce Page association...');
        SetupEntityAccess page_se = new SetupEntityAccess();
        page_se.ParentId = permSet.Id;
        page_se.SetupEntityId = apexPage.Id;
        entityList.add(page_se);
    }

    // Commit
    System.debug('Commiting Visualforce Page and Connected App associations...');
    insert entityList;

    //-- Give our Permission Set access to the Salesforce Lead object so that the Lead Capture user is allowed to upsert leads
    System.debug('Checking for existing Lead object permissions...');
    List<ObjectPermissions> existingObjectPermissions = [SELECT Id FROM ObjectPermissions WHERE ParentId = :permSet.Id AND SobjectType = 'Lead' LIMIT 1];
    
    if (existingObjectPermissions.size() == 0) {
        System.debug('Assigning Lead object permissions...');
        ObjectPermissions op = new ObjectPermissions();
        op.ParentId = permSet.Id;
        op.SobjectType = 'Lead';
        op.PermissionsRead = true;
        op.PermissionsCreate = true;
        op.PermissionsEdit = true;
        insert op;
    }
    
    //-- Give our Permission Set Read/Edit rights on our Facebook Lead ID custom field so that it can be populated on lead upsert
    System.debug('Checking for existing Facebook Lead ID custom field permissions...');
    string customFieldName = 'Lead.' + FACEBOOKLEADID_CUSTOM_FIELD_API_NAME;
    List<FieldPermissions> existingFieldPermissions = [SELECT Id FROM FieldPermissions WHERE ParentId = :permSet.Id AND Field = :customFieldName AND SobjectType = 'Lead' LIMIT 1];
    
    if (existingFieldPermissions.size() == 0) {
        System.debug('Assigning Facebook Lead ID custom field permissions...');
        FieldPermissions fld = new FieldPermissions();
        fld.Field = customFieldName;
        fld.ParentId = permSet.Id;
        fld.PermissionsEdit = true;
        fld.PermissionsRead = true;
        fld.SobjectType = 'Lead';
        insert fld;
    }

    System.debug('The End.');
  }
}