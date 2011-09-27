# API

## Browser: Index

* v2: `http://hockey/`
* v1: `http://hockey/`

### Input

* none

### Output

* HTML
* List of non-private Applications for all platforms
* Platform filter with JavaScript


## Browser: Single App (v2 only)

* v-:         `http://hockey/?bundleidentifier=de.buzzworks.worldview`
* v2:         `http://hockey/apps/<bundleidentifier>`
* v2 Example: `http://hockey/apps/de.buzzworks.worldview`

### Input

* bundleidentifier = `([\w.-]+)`

### Output

* HTML
* App details for app matching bundle ID, highest non-private version.
* If no matching bundle ID or all versions are non-public, show placeholder text
* If multiple platforms share the same bundle identifier, show them all


## Browser: Download profile

TODO


## Browser: Download app

TODO


## Browser: Download plist

TODO


## iOS client: Status of an app (v1 only)

* v1:               `http://hockey/?bundleidentifier=<bundleidentifier>`
* v1 Example:       `http://hockey/?bundleidentifier=de.buzzworks.worldview`
* v1 w/ parameters: `http://hockey/?bundleidentifier=de.buzzworks.worldview&udid=f00`

### Input

* bundleidentifier = `[\w.-]+`

Optional parameters

* udid = `[1-9a-f]{40}` (*optional*, UDID of user’s device, for statistics)
* version               (*optional*, version of app running on user’s device, for statistics)
* ios                   (*optional*, OS version of user’s device, for statistics)
* platform              (*optional*, Device type of user’s device [e.g. “i386”, “iPhone1,1”, “iPod4,1”, “iPad1,1”], for statistics)

### Output

* JSON
* Success: `{"notes":release notes,"title":app title,"result":version number}`
* Error: `{ result: "-1" }`
* Info of highest app version


## Any Platform Client: Status of an app (v2 only)

* v2:         `http://hockey/api/<apiversion>/apps/<bundleidentifier>`
* v2 Example: `http://hockey/api/2/apps/de.buzzworks.worldview`

### Input

* apiversion = for now 2
* bundleidentifier = ([\w.-]+)

Other parameters, *HTTP GET/POST*.

* format = 'json'       (return requested data in json format)

Optional parameters, *HTTP GET/POST*.

* udid = `[1-9a-f]{40}` (*semi-optional* (authentication), UDID of user’s device, for *statistics*, *authentication* and *team membership*)
* app_version           (version of app running on user’s device, for *statistics*)
* os                    (OS name of user’s device, for *statistics*)
* os_version            (OS version of user’s device, for *statistics*)
* device                (Device type of user’s device [e.g. “i386”, “iPhone1,1”, “iPod4,1”, “iPad1,1”], for *statistics*)
* lang                  (2 letter language code, for *statistics*)
* first_start_at        (first start of an app version as a string, for *statistics*)
* usage_time            (amount of time a version is in usage, ?d ?h ?m, where minutes are in max. 15 minute granularity, for *statistics*)

**NOTICE**: former parameter `platform` changed to `device`!

### Output

* JSON
* Success: ` [{"notes":release notes,"mandatory":true,"title":app title,"result":version number}, {"notes":release notes,"mandatory":false,"title":app title,"result":version number}, ...]`
* Error: `{ result: "-1" }`
* Info about app versions (multiple versions, authentication and team membership by UDID)


## iOS client: Download mobile provisioning profile

* v1:         `http://hockey/?bundleidentifier=de.buzzworks.worldview&type=profile`
* v2:         `http://hockey/api/<apiversion>/apps/<bundleidentifier>`
* v2 Example: `http://hockey/api/2/apps/de.buzzworks.worldview`

### API V2 Input

* apiversion = for now 2
* bundleidentifier = ([\w.-]+)

Other Parameters (HTTP POST/GET)

* format = 'mobileprovision'   (binary download of the iOS mobile provisioning profile)


### Output

* Binary data: `application/octet-stream`
* `.mobileprovision` File


## iOS client: Download plist file

* v1:         `http://hockey/?bundleidentifier=de.buzzworks.worldview&type=app`
* v2:         `http://hockey/api/<apiversion>/apps/<bundleidentifier>`
* v2 Example: `http://hockey/api/2/apps/de.buzzworks.worldview`

### API V2 Input *HTTP GET/POST*

* apiversion = for now 2
* bundleidentifier = ([\w.-]+)
* format = 'plist'     (binary download of the iOS ipa package)

Optional parameters

* udid = `[1-9a-f]{40}` (*semi-optional* (authentication), UDID of user’s device, for *statistics*, *authentication* and *team membership*)

### Output

* Binary data: `application/octet-stream`
* Modified `.plist` File


## iOS client: Download mobile App

* v1:         `http://hockey/?bundleidentifier=de.buzzworks.worldview&type=ipa`
* v2:         `http://hockey/api/<apiversion>/apps/<bundleidentifier>`
* v2 Example: `http://hockey/api/2/apps/de.buzzworks.worldview`

### API V2 Input *HTTP GET/POST*

* apiversion = for now 2
* bundleidentifier = ([\w.-]+)
* format = 'ipa'        (binary download of the iOS ipa package)

Optional parameters

* udid = `[1-9a-f]{40}` (*semi-optional* (authentication), UDID of user’s device, for *statistics*, *authentication* and *team membership*)

### Output

* Binary data: `application/octet-stream`
* `.ipa` File


## Android client: Download mobile App (v2 only)

* v2:         `http://hockey/api/<apiversion>/apps/<bundleidentifier>`
* v2 Example: `http://hockey/api/2/apps/de.buzzworks.worldview`

### API V2 Input *HTTP GET/POST*

* apiversion = for now 2
* bundleidentifier = ([\w.-]+)
* format = 'apk'        (binary download of the Android apk package)

### Output

* Binary data: `application/octet-stream`
* `.apk` File


## iOS client: Authentication code retrieval (v2 only, iOS only)

* v2:         `http://hockey/api/<apiversion>/apps/<bundleidentifier>`
* v2 Example: `http://hockey/api/2/apps/de.buzzworks.worldview`

### Input *HTTP GET/POST*

* apiversion = for now 2
* bundleidentifier = ([\w.-]+)

Other Parameters (HTTP POST/GET)

* udid = `[1-9a-f]{40}` (*semi-optional* (authentication), UDID of user’s device, for *statistics*, *authentication* and *team membership*)
* format = 'json'       (return requested data in json format)
* authorize = 'yes'     (*iOS only*, request authorization code for running the requested app version on the requested device)
* app_version           (version of app running on user’s device, for *statistics*)

### Output

* JSON
* Error: `{"authcode":"FAILED"}`
* Success: `{"authcode":"4970637a68200e12b779b6a0377c3937"}`

