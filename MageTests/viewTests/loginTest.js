// var app = UIATarget.localTarget().frontMostApp();
//
// if (isLoginScreen(app.mainWindow())) {
//
//
//   // If you log in then log out and type your password
//   // wrong and then try to log in again it fails to log in
//   test("Log in then log out then fail to log in then log in", function(target, app) {
//     var mainWindow = app.mainWindow();
//     login(mainWindow);
//     logout(app);
//     navigateToLogin(app);
//     badLogin(mainWindow);
//     login(mainWindow);
//     assertTrue(isRootMageView(app), "Not at the root MAGE view and should be, or took longer than 5 seconds to log in.");
//     // reset for the next test
//     navigateToLogin(app);
//   });
//
//   test("Server URL Unlocking", function(target, app) {
//     var mainWindow = app.mainWindow();
//
//     var serverUrlField = mainWindow.textFields()["Server URL"];
//     assertFalse(serverUrlField.isEnabled(), "Server URL field is enabled when it should be disabled");
//
//     mainWindow.buttons()["Unlock Server URL"].tap();
//     serverUrlField = mainWindow.textFields()["Server URL"];
//     assertTrue(serverUrlField.isEnabled(), "Server URL field is disabled when it should be enabled");
//
//     mainWindow.buttons()["Unlock Server URL"].tap();
//     serverUrlField = mainWindow.textFields()["Server URL"];
//     // wait 5 seconds here for the server validation to come back
//     serverUrlField.waitUntil(function (e) { return e; }, function (e) {
//       return !e.isEnabled();
//     }, 5, "to become disabled");
//     assertFalse(serverUrlField.isEnabled(), "Server URL field is enabled when it should be disabled or 5 second timeout happened");
//   });
//
//   test("Show Password", function(target, app) {
//     var mainWindow = app.mainWindow();
//
//     var passwordField = mainWindow.secureTextFields()["Password"];
//     assertTrue(passwordField != null, "Password field should be secure");
//
//     mainWindow.switches()["Show Password"].tap();
//     passwordField = mainWindow.textFields()["Password"];
//     assertTrue(passwordField != null, "Password field should be insecure");
//
//     mainWindow.switches()["Show Password"].tap();
//     passwordField = mainWindow.secureTextFields()["Password"];
//     assertTrue(passwordField != null, "Password field should be secure");
//   });
//
//   // for now don't run this test because there is no way to get back without actually signing up
//   // test("Sign Up", function(target, app) {
//   //   var mainWindow = app.mainWindow();
//   //
//   //   mainWindow.buttons()["Sign Up"].tap();
//   //   assertTrue(isSignUpScreen(mainWindow), "Should be on the sign up screen but am not");
//   // });
//
//   test("Fail to log in", function(target, app) {
//     var mainWindow = app.mainWindow();
//
//     assertFalse(mainWindow.textViews()["Login Status"].isVisible(), "Failed to log in status is visible and should not be");
//
//     mainWindow.textFields()["Username"].setValue("nope");
//     mainWindow.secureTextFields()["Password"].setValue("bad");
//
//     mainWindow.buttons()["Log In"].tap();
//
//     mainWindow.textViews()["Login Status"].waitUntilVisible(5);
//
//     assertTrue(mainWindow.textViews()["Login Status"].isVisible(), "Failed to log in status not visible and should be or took longer than 5 seconds to fail.");
//   });
//
//   test("Successfully log in", function(target, app) {
//     var mainWindow = app.mainWindow();
//
//     mainWindow.textFields()["Username"].setValue(username);
//     mainWindow.secureTextFields()["Password"].setValue(password);
//
//     mainWindow.buttons()["Log In"].tap();
//     mainWindow.waitUntilNotFoundByName("Log In", 5);
//     assertTrue(isRootMageView(app), "Not at the root MAGE view and should be, or took longer than 5 seconds to log in.");
//   });
//
// } else {
//    UIALogger.logDebug("Tests not run, this is not the log in screen");
// }
