<?php

/**
* iOS implementation
*/
class AndroidAppUpdater extends AbstractAppUpdater
{
    protected function deliverJson($api, $files)
    {
        // check for available updates for the given bundleidentifier
        // and return a JSON string with the result values

        $current = current($files[self::VERSIONS_SPECIFIC_DATA]);
        $ipa = $current[self::FILE_IOS_IPA];
        $plist = $current[self::FILE_IOS_PLIST];
        $apk = $current[self::FILE_ANDROID_APK];
        $json = $current[self::FILE_ANDROID_JSON];
        $note = $current[self::FILE_COMMON_NOTES];
        
        $profile = $files[self::VERSIONS_COMMON_DATA][self::FILE_IOS_PROFILE];
        $image = $files[self::VERSIONS_COMMON_DATA][self::FILE_COMMON_ICON];
        
        if ($apk && $json) {
            
            // this is an Android app
            
            $appversion = isset($_GET[self::CLIENT_KEY_APPVERSION]) ? $_GET[self::CLIENT_KEY_APPVERSION] : "";
            
            // API version is V2 by default, even if the client provides V1
            foreach ($files[self::VERSIONS_SPECIFIC_DATA] as $version) {
                $apk = $version[self::FILE_ANDROID_APK];
                $json = $version[self::FILE_ANDROID_JSON];
                $note = $version[self::FILE_COMMON_NOTES];
                
                // parse the json file
                $parsed_json = json_decode(file_get_contents($appDirectory . $json), true);
            
                $newAppVersion = array();
                // add the latest release notes if available
                if ($note) {
                    $newAppVersion[self::RETURN_V2_NOTES]       = Helper::nl2br_skip_html(file_get_contents($appDirectory . $note));
                }

                $newAppVersion[self::RETURN_V2_TITLE]           = $parsed_json['title'];

                $newAppVersion[self::RETURN_V2_SHORTVERSION]    = $parsed_json['versionName'];
                $newAppVersion[self::RETURN_V2_VERSION]         = $parsed_json['versionCode'];
        
                $newAppVersion[self::RETURN_V2_TIMESTAMP]       = filectime($appDirectory . $apk);
                $newAppVersion[self::RETURN_V2_APPSIZE]         = filesize($appDirectory . $apk);

                $this->json[] = $newAppVersion;
                
                // only send the data until the current version if provided
                if ($appversion == $parsed_json['versionCode']) break;
            }
            return $this->sendJSONAndExit();
        }
    }

    protected function deliver($bundleidentifier, $api, $type)
    {
        $files = $this->getApplicationVersions($bundleidentifier);

        if (count($files) == 0) {
            $this->json = array(self::RETURN_RESULT => -1);
            return $this->sendJSONAndExit();
        }
                        
        $current = current($files[self::VERSIONS_SPECIFIC_DATA]);
        $apk = $current[self::FILE_ANDROID_APK];
        $json = $current[self::FILE_ANDROID_JSON];
        $note = $current[self::FILE_COMMON_NOTES];

        $profile = $files[self::VERSIONS_COMMON_DATA][self::FILE_IOS_PROFILE];
        $image = $files[self::VERSIONS_COMMON_DATA][self::FILE_COMMON_ICON];
        
        // notes file is optional, other files are required
        if (!$apk || !$json) {
            $this->json = array(self::RETURN_RESULT => -1);
            return $this->sendJSONAndExit();
        }
        
        $this->addStats($bundleidentifier);
        
        if (!$type) {
            // the client requested the current available updates
            $this->deliverJSON($api, $files);
        } else if ($type == self::TYPE_APK) {
            Helper::sendFile($appDirectory . $apk, AppUpdater::CONTENT_TYPE_APK); // TODO send android apk file
        }

        exit();
    }
    
    protected function validateType($type)
    {
        if (in_array($type, array(self::TYPE_PROFILE, self::TYPE_APP, self::TYPE_IPA, self::TYPE_AUTH, self::TYPE_APK)))
        {
            return $type;
        }
        return null;
    }
}

?>