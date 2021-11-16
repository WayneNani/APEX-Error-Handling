# About this repository
This repository contains a package for easy and robust error handling in Oracle APEX. To harness its full potential you will need to install the [Logger-framework](https://github.com/OraOpenSource/Logger) (we have added some functions and renamed it to `apps_logger`, but it should be fairly easy to recreate) and create an application holding all your error messages. The ID of the application must then be hard-coded into the package `error_handling`. The error message application will also need a default message with the identifier `DEFAULT_EXCEPTION_TEXT` that will be used for unexpected error. This message has to contain a placeholder to present the log ID to the user. It could look something like: 
```
An unexpected error occured. Please contact the support team and provide the following ID: %0
```

If you want to use the error handling function for an application you need to open `Shared Components > Application Definition Attributes > Error Handling` and paste in `error_handling.handle_apex_error` as error handling function.

## TO DO:
In the future, I will also publish a modified version of the Logger-framework that includes all necessary modifications and provide an error message management app that makes all these functionalities more accessible. But currently I'm terribly busy...