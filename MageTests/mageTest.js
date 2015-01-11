var target = UIATarget.localTarget();
var app = target.frontMostApp();
var mainWindow = app.mainWindow();

UIATarget.onAlert = function onAlert(alert) {
    UIALogger.logMessage("alert shown");
};

function captureScreenshot(name) {
    target.captureScreenWithName(name);
    target.delay(2);
}

function isInteger(str) {
    return /^\+?(0|[1-9]\d*)$/.test(str);
}

function test(title, f, options) {
    if (options == null) {
        options = {
        logTree: true
        };
    }
    target = UIATarget.localTarget();
    application = target.frontMostApp();
    UIALogger.logStart(title);
    try {
        f(target, application);
        UIALogger.logPass(title);
    }
    catch (e) {
        UIALogger.logError(e);
        if (options.logTree) target.logElementTree();
        UIALogger.logFail(title);
    }
};

function assertEquals(expected, received, message) {
    if (received != expected) {
        if (! message) message = "Expected " + expected + " but received " + received;
        throw message;
    }
}

function assertTrue(expression, message) {
    if (! expression) {
        if (! message) message = "Assertion failed";
        throw message;
    }
}

function assertFalse(expression, message) {
    assertTrue(! expression, message);
}

function assertNotNull(thingie, message) {
    if (thingie == null || thingie.toString() == "[object UIAElementNil]") {
        if (message == null) message = "Expected not null object";
        throw message;
    }
}

test("Disclaimer Screen", function(target, app) {
    
});


test("Log In Screen", function(target, app) {
     // check navigation bar
     navBar = mainWindow.navigationBar();
     assertEquals("Add Account", navBar.name());
     button = navBar.leftButton();
     assertEquals("Back", button.name());
     
     // check tables
     table = mainWindow.tableViews()[0];
     tableGroup = table.groups()[0];
     assertEquals("What type of account?", tableGroup.name());
     
     assertEquals(4, table.cells().length);
     ["facebook", "flickr", "github", "twitter"].each(function(i,e) {
                                                      assertNotNull(table.cells().firstWithName(e));
                                                      });
     
     // more to come...
});



function isIphone() {
    var testname = "Is iPhone";
    UIALogger.logStart(testname);
    var isIphone = false;
    var toolbar = mainWindow.toolbars()["iphone_disclaimer_toolbar"];
    if (toolbar != null && toolbar.toString() != "[object UIAElementNil]") {
        isIphone = true;
    }
    UIALogger.logPass(testname);
    return isIphone;
}

function closeIphoneDisclaimer() {
    var testname = "Close iPhone Disclaimer";
    var screenshotName = "disclaimer";
    UIALogger.logStart(screenshotName);
    captureScreenshot("Close_iPhone_Disclaimer");
    var toolbar = mainWindow.toolbars()["iphone_disclaimer_toolbar"];
    var buttons = toolbar.buttons();
    buttons["I Agree"].tap();
    target.delay(1);
    UIALogger.logPass(testname);
}

function iPhoneSettingsTest() {
    var testname = "iPhone Settings Test";
    var screenshotName = "settings_";
    var screenshotIndex = 1;
    UIALogger.logStart(testname);
    var buttons = mainWindow.buttons();
    
    buttons["Settings"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    var navigationBar = mainWindow.navigationBar();
    
    mainWindow.tableViews()[0].cells()["Sync Now"].buttons()["Sync Now"].tap();
    target.delay(15);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Go back to main page.
    navigationBar.leftButton().tap();
    target.delay(1);
    
    UIALogger.logPass(testname);
}

function iPhoneMapViewTest() {
    var testname = "iPhone Map View Test";
    var screenshotName = "map_view_";
    var screenshotIndex = 1;
    UIALogger.logStart(testname);
    captureScreenshot(screenshotName + (screenshotIndex++));
    var buttons = mainWindow.buttons();
    buttons["Map View"].tap();
    target.delay(10);
    captureScreenshot(screenshotName + (screenshotIndex++));
    var navigationBar = mainWindow.navigationBar();
    
    // Go to list view.
    navigationBar.segmentedControls()[0].buttons()["List View"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    var asamTable = mainWindow.tableViews()[0];
    
    // Go to details view.
    if (asamTable.cells().length > 0) {
        asamTable.cells()[0].tap();
        target.delay(1);
        captureScreenshot(screenshotName + (screenshotIndex++));
        navigationBar.leftButton().tap();
        target.delay(1);
        captureScreenshot(screenshotName + (screenshotIndex++));
    }
    
    // Do Victim, Aggressor, Date Ascending, Date Descending sorts in the list view.
    navigationBar.segmentedControls()[0].buttons()["Sort"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    app.actionSheet().buttons()["Victim"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    navigationBar.segmentedControls()[0].buttons()["Sort"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    app.actionSheet().buttons()["Aggressor"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    navigationBar.segmentedControls()[0].buttons()["Sort"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    app.actionSheet().buttons()["Date Ascending"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    navigationBar.segmentedControls()[0].buttons()["Sort"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    app.actionSheet().buttons()["Date Descending"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Go back to map.
    navigationBar.leftButton().tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Now run a 180 day query.
    navigationBar.segmentedControls()[0].buttons()["Query"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    app.actionSheet().buttons()["Last 180 days"].tap();
    target.delay(10);
    captureScreenshot(screenshotName + (screenshotIndex++));
    navigationBar.segmentedControls()[0].buttons()["Reset"].tap();
    target.delay(10);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Go back to main page.
    navigationBar.leftButton().tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    UIALogger.logPass(testname);
}

function iPhoneSubregionsTest() {
    var testname = "iPhone Subregions View Test";
    var screenshotName = "subregions_";
    var screenshotIndex = 1;
    UIALogger.logStart(testname);
    captureScreenshot(screenshotName + (screenshotIndex++));
    var buttons = mainWindow.buttons();
    buttons["Subregions"].tap();
    target.delay(10);
    captureScreenshot(screenshotName + (screenshotIndex++));
    var navigationBar = mainWindow.navigationBar();
    
    target.tapWithOptions({x: 225, y: 250}, {tapCount: 1, touchCount: 1, duration: 1.0});
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    navigationBar.segmentedControls()[0].buttons()["Selected Regions"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    var alert = app.alert();
    captureScreenshot(screenshotName + (screenshotIndex++));
    target.delay(5); // Wait for the cancel button to do it's thing.
    
    navigationBar.segmentedControls()[0].buttons()["Reset"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    target.tapWithOptions({x: 225, y: 250}, {tapCount: 1, touchCount: 1, duration: 1.0});
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    navigationBar.segmentedControls()[0].buttons()["Query"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    app.actionSheet().buttons()["Last 1 Year"].tap();
    target.delay(10);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Go back to subregions page.
    navigationBar.leftButton().tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Go back to main page.
    mainWindow.navigationBar().leftButton().tap();
    target.delay(1);
    
    UIALogger.logPass(testname);
}

function iPhoneQueryTest() {
    var testname = "iPhone Query Test";
    var screenshotName = "query_";
    var screenshotIndex = 1;
    UIALogger.logStart(testname);
    var buttons = mainWindow.buttons();
    
    buttons["Query"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    var navigationBar = mainWindow.navigationBar();
    
    // Subregion query.
    mainWindow.textFields()["Subregion"].tap();
    var picker = app.actionSheet().pickers()[0];
    if (picker.isValid()) {
        var wheel = picker.wheels()[0];
        if (wheel.isValid()) {
            wheel.selectValue("62");
        }
    }
    app.actionSheet().toolbars()[0].buttons()["Done"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    mainWindow.buttons()["Search"].tap();
    target.delay(10);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Go back to query page.
    navigationBar.leftButton().tap();
    
    // Reference query. (IGNORE THIS ONE...)
    //    mainWindow.logElementTree();
    //    mainWindow.buttons()["Reset"].tap();
    //    mainWindow.textFields()["Reference Year"].tap();
    //    mainWindow.textFields()["Reference Number"].tap();
    //    app.keyboard().typeString("001");
    //    mainWindow.buttons()["Search"].tap();
    //    target.delay(4);
    //    /* [SCREEN SHOT] */
    //    // Go back to query page.
    //    navigationBar.leftButton().tap();
    
    // Time frame query. (IGNORE THIS ONE...)
    //    mainWindow.buttons()["Reset"].tap();
    //    mainWindow.textFields()["Date From"].setValue("01/01/2013");
    //    mainWindow.textFields()["Date To"].setValue("01/01/2014");
    //    target.delay(1);
    //    app.actionSheet().toolbars()[0].buttons()["Cancel"].tap();
    //    target.delay(1);
    //    /* [SCREEN SHOT] */
    //    mainWindow.buttons()["Search"].tap();
    //    app.keyboard().buttons()["Return"].tap();
    //    target.delay(4);
    //    mainWindow.buttons()["Search"].tap();
    //    /* [SCREEN SHOT] */
    //    // Go back to query page.
    //    navigationBar.leftButton().tap();
    
    // Victim query.
    mainWindow.buttons()["Reset"].tap();
    mainWindow.textFields()["Victim Name"].tap();
    app.keyboard().typeString("Tug");
    app.keyboard().buttons()["Done"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    mainWindow.buttons()["Search"].tap();
    target.delay(10);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Go back to query page.
    navigationBar.leftButton().tap();
    
    // Aggressor query.
    mainWindow.buttons()["Reset"].tap();
    mainWindow.textFields()["Aggressor Name"].tap();
    app.keyboard().typeString("Pirate");
    app.keyboard().buttons()["Done"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    mainWindow.buttons()["Search"].tap();
    target.delay(10);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Go back to query page.
    navigationBar.leftButton().tap();
    
    // Go back to main page.
    navigationBar.leftButton().tap();
    target.delay(1);
    
    UIALogger.logPass(testname);
}

function iPhoneAboutTest() {
    var testname = "iPhone About Test";
    var screenshotName = "about_";
    var screenshotIndex = 1;
    UIALogger.logStart(testname);
    var buttons = mainWindow.buttons();
    var navigationBar = mainWindow.navigationBar();
    navigationBar.buttons()["About"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Click on the legal information.
    mainWindow.tableViews()[0].cells()["Legal Information"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Click on NGA Disclaimer.
    mainWindow.tableViews()[0].cells()["Disclaimer"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Go back to legal page.
    navigationBar.leftButton().tap();
    target.delay(1);
    
    // Click on privacy policy.
    mainWindow.tableViews()[0].cells()["ASAM app"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Go back to legal page.
    navigationBar.leftButton().tap();
    target.delay(1);
    
    // Click on rev cluster.
    mainWindow.tableViews()[0].cells()["REVClusterMap"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Go back to legal page.
    navigationBar.leftButton().tap();
    target.delay(1);
    
    // Click on reachability.
    mainWindow.tableViews()[0].cells()["Reachability"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Go back to legal page.
    navigationBar.leftButton().tap();
    target.delay(1);
    
    // Click on DSActivityView.
    mainWindow.tableViews()[0].cells()["DSActivityView"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Go back to legal page.
    navigationBar.leftButton().tap();
    target.delay(1);
    
    // Click on DDActionHeaderView.
    mainWindow.tableViews()[0].cells()["DDActionHeaderView"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Go back to legal page.
    navigationBar.leftButton().tap();
    target.delay(1);
    
    // Go back to about page.
    navigationBar.leftButton().tap();
    target.delay(1);
    
    // Go back to main screen.
    navigationBar.buttons()["Dismiss"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    UIALogger.logPass(testname);
}

function closeIpadDisclaimer() {
    var testname = "Close iPad Disclaimer";
    var screenshotName = "disclaimer_";
    var screenshotIndex = 1;
    UIALogger.logStart(testname);
    target.delay(10); // Time to display map underneath.
    captureScreenshot(screenshotName + (screenshotIndex++));
    mainWindow.toolbars()["ipad_disclaimer_toolbar"].buttons()["I agree"].tap();
    target.delay(3);
    UIALogger.logPass(testname);
}

function iPadSettingsTest() {
    var testname = "iPad Settings";
    var screenshotName = "settings_";
    var screenshotIndex = 1;
    UIALogger.logStart(testname);
    
    mainWindow.toolbars()["main_toolbar"].buttons()["Settings"].tap();
    target.delay(1);
    
    var popover = mainWindow.popover();
    captureScreenshot(screenshotName + (screenshotIndex++));
    popover.tableViews()[0].cells()["Sync Now"].buttons()["Sync Now"].tap();
    target.delay(15);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    if (popover != null && popover.toString() != "[object UIAElementNil]" && popover.isVisible()) {
        popover.dismiss();
        target.delay(1);
    }
    
    UIALogger.logPass(testname);
}

function iPadListViewTest() {
    var testname = "iPad List View";
    var screenshotName = "list_view_";
    var screenshotIndex = 1;
    UIALogger.logStart(testname);
    
    mainWindow.toolbars()["main_toolbar"].buttons()["List View"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    var popover = mainWindow.popover();
    var asamTable = popover.tableViews()[0];
    
    // Go to details view.
    if (asamTable.cells().length > 0) {
        asamTable.cells()[0].tap();
        target.delay(1);
        captureScreenshot(screenshotName + (screenshotIndex++));
        popover.navigationBar().leftButton().tap();
        target.delay(1);
        captureScreenshot(screenshotName + (screenshotIndex++));
    }
    
    popover.navigationBar().segmentedControls()[0].buttons()["Sort"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    popover.actionSheet().buttons()["Victim"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    popover.navigationBar().segmentedControls()[0].buttons()["Sort"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    popover.actionSheet().buttons()["Aggressor"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    popover.navigationBar().segmentedControls()[0].buttons()["Sort"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    popover.actionSheet().buttons()["Date Ascending"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    popover.navigationBar().segmentedControls()[0].buttons()["Sort"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    popover.actionSheet().buttons()["Date Descending"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    UIALogger.logPass(testname);
}

function iPadSubregionsTest() {
    var testname = "iPad Subregions Test";
    var screenshotName = "subregions_";
    var screenshotIndex = 1;
    UIALogger.logStart(testname);
    
    mainWindow.toolbars()["main_toolbar"].buttons()["Subregions"].tap();
    target.delay(10);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    target.tapWithOptions({x: 500, y: 450}, {tapCount: 1, touchCount: 1, duration: 1.0});
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    mainWindow.toolbar().buttons()["Selected Regions"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    var alert = app.alert();
    captureScreenshot(screenshotName + (screenshotIndex++));
    target.delay(5); // Wait for the cancel button to do it's thing.
    
    mainWindow.toolbar().buttons()["Reset"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    target.tapWithOptions({x: 500, y: 450}, {tapCount: 1, touchCount: 1, duration: 1.0});
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    mainWindow.toolbar().buttons()["Query"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    var popover = mainWindow.popover();
    popover.actionSheet().buttons()["Last 1 Year"].tap();
    target.delay(10);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    mainWindow.logElementTree();
    
    // Reset main page.
    mainWindow.buttons()["reset"].tap();
    target.delay(10);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    UIALogger.logPass(testname);
}

function iPadQueryTest() {
    var testname = "iPad Query Test";
    var screenshotName = "query_";
    var screenshotIndex = 1;
    UIALogger.logStart(testname);
    
    mainWindow.toolbars()["main_toolbar"].buttons()["Search"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    var popover = mainWindow.popover();
    
    // Subregion query.
    popover.textFields()["Subregion"].tap();
    var picker = popover.actionSheet().pickers()[0];
    if (picker.isValid()) {
        var wheel = picker.wheels()[0];
        if (wheel.isValid()) {
            wheel.selectValue("62");
        }
    }
    popover.actionSheet().toolbars()[0].buttons()["Done"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    popover.buttons()["Search"].tap();
    target.delay(10);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Reference query.
    mainWindow.toolbars()["main_toolbar"].buttons()["Search"].tap();
    target.delay(1);
    popover.textFields()["Reference Year"].tap();
    app.keyboard().typeString("2013");
    popover.textFields()["Reference Number"].tap();
    app.keyboard().typeString("12");
    captureScreenshot(screenshotName + (screenshotIndex++));
    popover.buttons()["Search"].tap();
    target.delay(10);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Time frame query.
    mainWindow.toolbars()["main_toolbar"].buttons()["Search"].tap();
    target.delay(1);
    popover.textFields()["Date From"].setValue("01/01/2013");
    popover.actionSheet().toolbar().buttons()["Cancel"].tap();
    popover.textFields()["Date To"].setValue("01/01/2014");
    popover.actionSheet().toolbar().buttons()["Cancel"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    popover.buttons()["Search"].tap();
    target.delay(10);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Victim query.
    mainWindow.toolbars()["main_toolbar"].buttons()["Search"].tap();
    target.delay(1);
    popover.textFields()["Victim Name"].tap();
    app.keyboard().typeString("Tug");
    app.keyboard().buttons()["Done"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    popover.buttons()["Search"].tap();
    target.delay(10);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Aggressor query.
    mainWindow.toolbars()["main_toolbar"].buttons()["Search"].tap();
    popover.textFields()["Aggressor Name"].tap();
    app.keyboard().typeString("Pirate");
    app.keyboard().buttons()["Done"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    popover.buttons()["Search"].tap();
    target.delay(10);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Reset main page.
    mainWindow.buttons()["reset"].tap();
    target.delay(10);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    UIALogger.logPass(testname);
}

function iPadAboutTest() {
    var testname = "iPad About Test";
    var screenshotName = "about_";
    var screenshotIndex = 1;
    UIALogger.logStart(testname);
    
    mainWindow.toolbars()["main_toolbar"].buttons()["About"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Click on the legal information.
    mainWindow.tableViews()[0].cells()["Legal Information"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Click on NGA Disclaimer.
    mainWindow.tableViews()[0].cells()["Disclaimer"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Go back to legal page.
    mainWindow.navigationBar().leftButton().tap();
    target.delay(1);
    
    // Click on privacy policy.
    mainWindow.tableViews()[0].cells()["ASAM app"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Go back to legal page.
    mainWindow.navigationBar().leftButton().tap();
    target.delay(1);
    
    // Click on rev cluster.
    mainWindow.tableViews()[0].cells()["REVClusterMap"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Go back to legal page.
    mainWindow.navigationBar().leftButton().tap();
    target.delay(1);
    
    // Click on reachability.
    mainWindow.tableViews()[0].cells()["Reachability"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Go back to legal page.
    mainWindow.navigationBar().leftButton().tap();
    target.delay(1);
    
    // Click on DSActivityView.
    mainWindow.tableViews()[0].cells()["DSActivityView"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Go back to legal page.
    mainWindow.navigationBar().leftButton().tap();
    target.delay(1);
    
    // Click on DDActionHeaderView.
    mainWindow.tableViews()[0].cells()["DDActionHeaderView"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    // Go back to legal page.
    mainWindow.navigationBar().leftButton().tap();
    target.delay(1);
    
    // Go back to about page.
    mainWindow.navigationBar().leftButton().tap();
    target.delay(1);
    
    // Dismiss window.
    mainWindow.navigationBar().buttons()["Dismiss"].tap();
    target.delay(1);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    UIALogger.logPass(testname);
}

function iPadClickOnClusterTest() {
    var testname = "iPad Click On Cluster Test";
    var screenshotName = "click_on_cluster_";
    var screenshotIndex = 1;
    UIALogger.logStart(testname);
    
    var map = mainWindow.elements()["main_map"];
    var clusters = map.elements();
    var selectedClusterIndex = -1;
    for (var i = 0; i < clusters.length; i++) {
        if (clusters[i].name() != null) {
            var nameParts = clusters[i].name().split(" ");
            if (nameParts.length > 0 && isInteger(nameParts[0])) {
                selectedClusterIndex = i;
                break;
            }
        }
    }
    
    if (selectedClusterIndex != -1) {
        clusters[selectedClusterIndex].tap();
        target.delay(1);
        captureScreenshot(screenshotName + (screenshotIndex++));
        map.popover().buttons()[0].tap(); // Click on the popover info button.
        target.delay(1);
        captureScreenshot(screenshotName + (screenshotIndex++));
        
        // Now exercise the popover.
        var popover = mainWindow.popover();
        var asamTable = popover.tableViews()[0];
        
        // Go to details view.
        if (asamTable.cells().length > 0) {
            asamTable.cells()[0].tap();
            target.delay(1);
            captureScreenshot(screenshotName + (screenshotIndex++));
            popover.navigationBar().leftButton().tap();
            target.delay(1);
            captureScreenshot(screenshotName + (screenshotIndex++));
        }
        
        popover.navigationBar().segmentedControls()[0].buttons()["Sort"].tap();
        target.delay(1);
        captureScreenshot(screenshotName + (screenshotIndex++));
        popover.actionSheet().buttons()["Victim"].tap();
        target.delay(1);
        captureScreenshot(screenshotName + (screenshotIndex++));
        
        popover.navigationBar().segmentedControls()[0].buttons()["Sort"].tap();
        target.delay(1);
        captureScreenshot(screenshotName + (screenshotIndex++));
        popover.actionSheet().buttons()["Aggressor"].tap();
        target.delay(1);
        captureScreenshot(screenshotName + (screenshotIndex++));
        
        popover.navigationBar().segmentedControls()[0].buttons()["Sort"].tap();
        target.delay(1);
        captureScreenshot(screenshotName + (screenshotIndex++));
        popover.actionSheet().buttons()["Date Ascending"].tap();
        target.delay(1);
        captureScreenshot(screenshotName + (screenshotIndex++));
        
        popover.navigationBar().segmentedControls()[0].buttons()["Sort"].tap();
        target.delay(1);
        captureScreenshot(screenshotName + (screenshotIndex++));
        popover.actionSheet().buttons()["Date Descending"].tap();
        target.delay(1);
        captureScreenshot(screenshotName + (screenshotIndex++));
    }
    
    // Dismiss popup.
    target.tapWithOptions({x: 100, y: 100}, {tapCount: 1, touchCount: 1, duration: 1.0});
    target.delay(4);
    captureScreenshot(screenshotName + (screenshotIndex++));
    
    UIALogger.logPass(testname);
}

if (isIphone()) {
    closeIphoneDisclaimer();
    iPhoneSettingsTest();
    iPhoneMapViewTest();
    iPhoneSubregionsTest();
    iPhoneQueryTest();
    iPhoneAboutTest();
}
else {
    closeIpadDisclaimer();
    iPadSettingsTest();
    iPadListViewTest();
    iPadSubregionsTest();
    iPadQueryTest();
    iPadAboutTest();
    iPadClickOnClusterTest();
}
