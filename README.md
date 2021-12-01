# About this repository
This repository contains a package for easy and robust error handling in Oracle APEX. To harness its full potential you will need to install the [Logger-framework](https://github.com/OraOpenSource/Logger) (we have added some functions and renamed it to `apps_logger`, but it should be fairly easy to recreate) and create an application holding all your error messages. The ID of the application must then be hard-coded into the package `error_handling`. The error message application will also need a default message with the identifier `DEFAULT_EXCEPTION_TEXT` that will be used for unexpected error. This message has to contain a placeholder to present the log ID to the user. It could look something like: 
```
An unexpected error occured. Please contact the support team and provide the following ID: %0
```



## Installation
To properly install and use the error handling you have to run the script `install.sql`. This will install all necessary components in the current schema. Additionally, you have to install the `error_handling_application.sql` in an APEX workspace using said schema. Afterwards, you will have to adjust the variable `gc_message_handling_application` in `error_handling` to the ID of the error handling application.

If you want to use the error handling function for an application you need to open `Shared Components > Application Definition Attributes > Error Handling` and paste in `error_handling.handle_apex_error` as error handling function.

The application already comes with some predefined error messages to help you hit the ground running.

## TO DO:
The modified version of Logger (apps_logger) is just included as a single script. This may change in future iterations.