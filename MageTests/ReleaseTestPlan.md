# ReleaseTestPlan

This is a test plan that should be run through when we release the MAGE app

## Overview

When releasing the MAGE app we have multiple types of users that we need to test with: Admin users, event manager users, and users with no edit

## General Online Operation

### Server URL Screen

- Enter some text that isn't a url (asdf) verify OK results in an error
- Enter a valid http url (http://www.google.com) verify app transport security error
- Enter a valid https url (https://www.google.com) verify failed to connect to server 404 since the app coudln't connect to \<url>/api
- Enter a valid mage url verify it works

### Signin Screen

- Enter an invalid username and password, verify Login Failed
- Verify clicking the email and phone links in the error open the appropriate actions
- Verify show password, shows the password
- Tap Sign Up Here, verify the sign up screen is shown
- Tap the server url, verify it takes you to the server url screen
- Verify the version reflects what we are going to be releasing

### Signup Screen

## Admin Users

## Offline Mode

## Login Methods

