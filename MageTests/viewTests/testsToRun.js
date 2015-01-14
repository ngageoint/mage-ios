
UIALogger.logDebug("Loading testsToRun");

// This file should only be used for importing other tests and navigating between views
#import "loginInformation.js"
#import "navigation.js"

var app = UIATarget.localTarget().frontMostApp();
isDisclaimerScreen(app.mainWindow());

navigateToLogin(app);

#import "disclaimerTest.js"
#import "loginTest.js"
#import "mapTest.js"

navigateToLogin(app);
