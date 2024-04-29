import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/time;

import wso2/choreo.sendemail as ChoreoEmail;

// Define a configurable string to hold the URL of the appointments API
configurable string appointmentApiUrl = ?;

// Define a record type to represent appointment data
type Appointment record {
    string appointmentDate;
    string email;
    int id;
    string name;
    string phoneNumber;
    string 'service; // Note: Backtick is used here to handle the 'service' field name
};

// Entry point of the program
public function main() returns error? {
    // Print the appointment API URL to the console
    io:println("Appointment URL: " + appointmentApiUrl);
    
    // Create an HTTP client to interact with the appointments API
    http:Client appointmentsApiEndpoint = check new (appointmentApiUrl);

    // Fetch upcoming appointments from the API
    Appointment[] appointments = check appointmentsApiEndpoint->/appointments(upcoming = "true");

    // Iterate over each appointment and send reminder emails
    foreach Appointment appointment in appointments {
        check sendEmail(appointment);
    }
}

// Function to send reminder emails for appointments
function sendEmail(Appointment appointment) returns error? {
    // Format the appointment date to IST time zone
    string formattedAppointmentDate = check getIstTimeString(appointment.appointmentDate);
    
    // Capitalize the service name
    string serviceName = convertAndCapitalize(appointment.'service);
    
    // Construct the email content
    string finalContent = string `
Dear ${appointment.name},

This is a reminder that you have a Ride scheduled for ${serviceName} at ${formattedAppointmentDate}.

Thank you for choosing Proride for your Transport needs. We are here to assist you at every step of your Rides journey.

Warm regards,
The Proride Team

---

Proride - Your Partner in Rides

Website: https://www.proride.com
Support: support@proride.com
Phone: +123 (456) 789-0

Follow us on:
- Facebook: https://www.facebook.com/ProRide
- Twitter: https://twitter.com/ProRide

Privacy Policy | Terms of Use | Unsubscribe

This message is intended only for the addressee and may contain confidential information. 
If you are not the intended recipient, you are hereby notified that any use, dissemination, copying, or storage of this message or its attachments is strictly prohibited.
`;

    // Create an email client and send the email
    ChoreoEmail:Client emailClient = check new ();
    string sendEmailResponse = check emailClient->sendEmail(appointment.email, "Upcoming Booked Rides Reminder", finalContent);
    
    // Log the email sent status
    log:printInfo("Email sent successfully to: " + appointment.email + " with response: " + sendEmailResponse);
}

// Function to convert UTC time string to IST time zone string
function getIstTimeString(string utcTimeString) returns string|error {
    // Parse the UTC time string
    time:Utc utcTime = check time:utcFromString(utcTimeString);

    // Convert to IST time zone
    time:TimeZone zone = check new ("Asia/Colombo");
    time:Civil istTime = zone.utcToCivil(utcTime);

    // Format the IST time string for email
    string emailFormattedString = check time:civilToEmailString(istTime, time:PREFER_TIME_ABBREV);
    return emailFormattedString;
}

// Function to capitalize each word in a hyphen-separated string
function convertAndCapitalize(string input) returns string {
    string:RegExp r = re `-`;
    // Split the input string by '-'
    string[] parts = r.split(input);

    // Capitalize the first letter of each part and join them with a space
    string result = "";
    foreach var word in parts {
        string capitalizedWord = word.substring(0, 1).toUpperAscii() + word.substring(1).toLowerAscii();
        if (result.length() > 0) {
            result = result + " " + capitalizedWord;
        } else {
            result = capitalizedWord;
        }
    }

    return result;
}
