//
//  ViewController.swift
//  google_calendar_api2
//
//  Created by 中村祐太 on 2016/09/26.
//  Copyright © 2016年 中村祐太. All rights reserved.
//

import GoogleAPIClient
import GTMOAuth2
import UIKit

class ViewController: UIViewController {
    
    fileprivate let kKeychainItemName = "Google Calendar API"
    fileprivate let kClientID = "YOUR_CLIENT_ID_HERE"
    
    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app.
    fileprivate let scopes = [kGTLAuthScopeCalendarReadonly]
    
    fileprivate let service = GTLServiceCalendar()
    let output = UITextView()
    
    // When the view loads, create necessary subviews
    // and initialize the Google Calendar API service
    override func viewDidLoad() {
        super.viewDidLoad()
        
        output.frame = view.bounds
        output.isEditable = false
        output.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        output.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        view.addSubview(output);
        
        if let auth = GTMOAuth2ViewControllerTouch.authForGoogleFromKeychain(
            forName: kKeychainItemName,
            clientID: kClientID,
            clientSecret: nil) {
            service.authorizer = auth
        }
        
    }
    
    // When the view appears, ensure that the Google Calendar API service is authorized
    // and perform API calls
    override func viewDidAppear(_ animated: Bool) {
        if let authorizer = service.authorizer,
            let canAuth = authorizer.canAuthorize , canAuth {
            fetchEvents()
        } else {
            present(
                createAuthController(),
                animated: true,
                completion: nil
            )
        }
    }
    
    // Construct a query and get a list of upcoming events from the user calendar
    func fetchEvents() {
        let query = GTLQueryCalendar.queryForEventsList(withCalendarId: "primary")
        query?.maxResults = 10
        query?.timeMin = GTLDateTime(date: Date(), timeZone: TimeZone.autoupdatingCurrent)
        query?.singleEvents = true
        query?.orderBy = kGTLCalendarOrderByStartTime
        service.executeQuery(
            query!,
            delegate: self,
            didFinish: #selector(ViewController.displayResultWithTicket(_:finishedWithObject:error:))
        )
    }
    
    // Display the start dates and event summaries in the UITextView
    func displayResultWithTicket(
        _ ticket: GTLServiceTicket,
        finishedWithObject response : GTLCalendarEvents,
        error : NSError?) {
        
        if let error = error {
            showAlert("Error", message: error.localizedDescription)
            return
        }
        
        var eventString = ""
        
        if let events = response.items() , !events.isEmpty {
            for event in events as! [GTLCalendarEvent] {
                let start : GTLDateTime! = event.start.dateTime ?? event.start.date
                let startString = DateFormatter.localizedString(
                    from: start.date,
                    dateStyle: .short,
                    timeStyle: .short
                )
                eventString += "\(startString) - \(event.summary)\n"
            }
        } else {
            eventString = "No upcoming events found."
        }
        
        output.text = eventString
    }
    
    
    // Creates the auth controller for authorizing access to Google Calendar API
    fileprivate func createAuthController() -> GTMOAuth2ViewControllerTouch {
        let scopeString = scopes.joined(separator: " ")
        return GTMOAuth2ViewControllerTouch(
            scope: scopeString,
            clientID: kClientID,
            clientSecret: nil,
            keychainItemName: kKeychainItemName,
            delegate: self,
            finishedSelector: #selector(ViewController.viewController(_:finishedWithAuth:error:))
        )
    }
    
    // Handle completion of the authorization process, and update the Google Calendar API
    // with the new credentials.
    func viewController(_ vc : UIViewController,
                        finishedWithAuth authResult : GTMOAuth2Authentication, error : NSError?) {
        
        if let error = error {
            service.authorizer = nil
            showAlert("Authentication Error", message: error.localizedDescription)
            return
        }
        
        service.authorizer = authResult
        dismiss(animated: true, completion: nil)
    }
    
    // Helper for showing an alert
    func showAlert(_ title : String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.alert
        )
        let ok = UIAlertAction(
            title: "OK",
            style: UIAlertActionStyle.default,
            handler: nil
        )
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
