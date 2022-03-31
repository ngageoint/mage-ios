# ReleaseTestPlan

This is a test plan that should be run through when we release the MAGE app

## Overview

When releasing the MAGE app we have multiple types of users that we need to test with: Admin users, event manager users, and users with no edit
These tests should be run on both iPads and iPhones.

## General Online Operation

### Server URL Screen

- Enter some text that isn't a url (asdf) verify OK results in an error
- Enter a valid http url (http://www.google.com) verify app transport security error
- Enter a valid https url (https://www.google.com) verify failed to connect to server 404 since the app coudln't connect to \<url>/api
- Enter a valid mage url verify it works

### Signup Screen
- Do not fill in anything and tap Sign Up, verify Missing Required Fields shows and required fields are marked red
- Properly create an account except the captcha, verify it fails
- Properly create an account and verify an Account Created message is shown

### Signin Screen
- Enter an invalid username and password, verify Login Failed
- Verify clicking the email and phone links in the error open the appropriate actions
- Verify show password, shows the password
- Tap Sign Up Here, verify the sign up screen is shown
- Tap the server url, verify it takes you to the server url screen
- Verify the version reflects what we are going to be releasing
- Sign in with a new user, verify that it tells you an admin needs to approve the user
- Active the user from the web and sign in again, verify a Registration Sent message appears
- Activate the device from the web, and sign in again, and verify the disclaimer is shown

### Disclaimer Screen
- tap disagree and verify takes you back to the sign in screen
- tap agree and verify you are sent to the event chooser screen

## Regular User
- verify if the user is in no events, the event chooser screen shows that message and a return to login button
- add the user to one event via the web, login and verify that they are taken directly to the MAGE map after the event loads
- add the user to another event via the web, login and verify that they are taken to the even chooser screen (a refresh button should appear which can be tapped to reload the table)
- verify the first even is in My Recent Events, verify the new event is in Other Events

### Creating an Observation
- verify the create new button creates a new observation at your current location
- verify long pressing on the map creates a new observation at that point
- verify that the form list is presented when a new observation is created
- verify when clicking a form it is added to the observation
- verify that you can delete a form
- verify that you can add another form
- verify that you can fill out the form
- verify that you can modify the location of the observation
- verify that changing the primary field on the first form changes the map icon
- verify that you can reorder the forms and that this updates the map icon
- verify you can add all types of attachments
- save the observation and verify that it saves correctly to the server
- verify each type of form field, textfield, textarea, dropdown, multidropdown, radio, date, location, number, checkbox, email
- verify you can paste into the text type fields
- verify you can modify the location to be a point, line, rectangle or polygon
- add an attachment and then remove it before saving
- add another attachment and save
- remove an attachment
- ensure you choose a photo which is a live photo and one which is a static photo

### Map Interaction
- verify clicking on a map brings up the bottom sheet for any features on the map at that location
- verify you can navigate to an observation
- verify you can navigate to a user
- verify you can navigate to a feed item
- verify you can navigate to a static feature
- verify all actions on all types of features work from the bottom sheet
- verify you can turn on and off location reporting from the map button
- tap the heading button and verify it asks if you would like to display your heading
- click yes, verify your heading shows on the map
- tap again verify that the map rotates with you
- verify filter button properly filters observations and people based on time and favorite/important

### Map Settings
- verify changing the base map works
- verify when changing to the offline map, the dark/light mode works
- verify traffic button works
- verify turning on and off offline layers works
- verify turning on and off online layers works
- verify that you can turn on and off feeds

### Observations Table
- verify that all actions work from the table view
- verify that you can view attachments (video, file, image, audio) from the table view
- verify you can click the location and it is copied to the clipboard
- verify tapping a row shows the observation
- ensure the filtering works on this view and the nav bar is updated properly

### Observation View
- verify that all actions work from the observations view including navigation
- favorite text should show the users who favorited the observation
- View \<users> Observations should show that users page
- Verify you can edit the observation
- Verify you can save all types of attachments

### People Table View
- verify that all actions work from the table view including navigation
- verify tapping on a location copies to the clipboard
- ensure the filtering works on this view and the navbar is updated properly

### Person View
- verify clicking on the users location allows you to copy to the clipboard or navigate to the user
- verify the phone number and email links work
- verify tapping the avatar opens a larger view
- verify all actions work from each row
- verify clicking on a row brings up the observation view

### Feeds View
- verify that clicking more shows Settings and the feeds on servers with a feed
- click edit and move the feed onto the main tab bar
- verify directions works from the feeds table view
- verify clicking the location copies to the clipboard
- verify clicking the card shows a full view of the feed item
- verify directions works from the feed item view

### Settings Views
- verify that clicking on the name of the current event brings up the event information and allows you to set custom defaults
- verify these defaults get set properly
- verify the different display settings are followed

## Admin Users
These are things that are different from a regular user that should be tested

### Event Chooser Screen
- verify that the admin user can see all events, including ones that they are not in
- verify that the admin user can choose an event they are not in

### Map Interaction
- verify that users and observations are shown for an event the admin user is not in
- verify the report location button is greyed out and clicking on it results in a message about not being in the event

### Creating an Observation
- verify if this user is not in the event, they cannot create an observation and clicking on the create observation button results in a message about not being in the event

## No Edit User
A no edit user should have all the same interactions as a regular user except that they can only create observations, not edit them

### Creating an Observation
- verify the user can create a new observation

### Editing an Observation
- verify the user cannot edit an observation

## Offline Mode

## Login Methods

