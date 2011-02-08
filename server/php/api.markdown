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
* v2:         `http://hockey/<platform>/app/<bundleidentifier>`
* v2 Example: `http://hockey/ios/app/de.buzzworks.worldview`

### Input

* bundleidentifier = `([\w.-]+)`
* platform (v2 only)

### Output

* HTML
* App details for app matching bundle ID, highest non-private version.
* If no matching bundle ID or all versions are non-public, show placeholder text


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

* v2:         `http://hockey/api/<platform>/status/<bundleidentifier>`
* v2 Example: `http://hockey/api/ios/status/de.buzzworks.worldview`

### Input

* platform = for now [`ios`, `android`]
* bundleidentifier = ([\w.-]+)

Optional parameters, *HTTP POST*.

* udid = `[1-9a-f]{40}` (*semi-optional* (authentication), UDID of user’s device, for *statistics*, *authentication* and *team membership*)
* version               (*iOS only*, version of app running on user’s device, for *statistics*)
* ios                   (*iOS only*, OS version of user’s device, for *statistics*)
* device                (*iOS only*, Device type of user’s device [e.g. “i386”, “iPhone1,1”, “iPod4,1”, “iPad1,1”], for *statistics*)
* lang                  (*iOS only*, 2 letter language code, for *statistics*)

**NOTICE**: former parameter `platform` changed to `device`, new parameter `platform` added!

### Output

* JSON
* Success: ` [{"notes":release notes,"title":app title,"result":version number}, {"notes":release notes,"title":app title,"result":version number}, ...]`
* Error: `{ result: "-1" }`
* Info about app versions (multiple versions, authentication and team membership by UDID)


## iOS client: Download mobile provisioning profile

* v1:         `http://hockey/?bundleidentifier=de.buzzworks.worldview&type=profile`
* v2:         `http://hockey/api/<platform>/download/<type>/<bundleidentifier>`
* v2 Example: `http://hockey/api/ios/download/profile/de.buzzworks.worldview`

### Input

* platform (v2 only)
* bundleidentifier = `[\w.-]+`
* type = `profile`

### Output

* Binary data: `application/octet-stream`
* `.mobileprovision` File


## iOS client: Download plist file

* v1:         `http://hockey/?bundleidentifier=de.buzzworks.worldview&type=app`
* v2:         `http://hockey/api/<platform>/download/<type>/de.buzzworks.worldview`
* v2 Example: `http://hockey/api/ios/download/plist/de.buzzworks.worldview`

### Input

* platform (v2 only)
* bundleidentifier = `[\w.-]+`
* type = `app` (v1 only) / `plist` (v2 only)

### Output

* Binary data: `application/octet-stream`
* Modified `.plist` File


## iOS client: Download mobile App

* v1:         `http://hockey/?bundleidentifier=de.buzzworks.worldview&type=ipa`
* v2:         `http://hockey/api/<platform>/download/<type>/<bundleidentifier>`
* v2 Example: `http://hockey/api/ios/download/app/de.buzzworks.worldview`

### Input

* platform (v2 only)
* bundleidentifier = `[\w.-]+`
* type = `ipa` (v1 only) / `app` (v2 only)

### Output

* Binary data: `application/octet-stream`
* `.ipa` File


## Android client: Download mobile App (v2 only)

* v-:         `http://hockey/?bundleidentifier=de.buzzworks.worldview-android&type=apk`
* v2:         `http://hockey/api/<platform>/download/<type>/<bundleidentifier>`
* v2 Example: `http://hockey/api/android/download/app/de.buzzworks.worldview-android`

### Input

* platform
* bundleidentifier = `[\w.-]+`
* type = `app`

### Output

* Binary data: `application/octet-stream`
* `.apk` File


## iOS client: Authentication code retrieval (v2 only)

* v-:         `http://hockey/?bundleidentifier=de.buzzworks.worldview&type=authorize&udid=f00&version=1.1`
* v2:         `http://hockey/api/<platform>/authorize/<bundleidentifier>`
* v2 Example: `http://hockey/api/ios/authorize/de.buzzworks.worldview`

### Input

* platform
* bundleidentifier = `[\w.-]+`

Other Parameters (HTTP POST in v2, GET in v1)

* udid
* version (= appversion)

### Output

* JSON
* Error: `{"authcode":"FAILED"}`
* Success: `{"authcode":"4970637a68200e12b779b6a0377c3937"}`

