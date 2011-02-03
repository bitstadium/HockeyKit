<?php

/**
* iOS implementation
*/
class AndroidAppUpdater extends AbstractAppUpdater
{

    protected function status($arguments) {
        $api = self::API_V2;
        $bundleidentifier = $arguments['bundleidentifier'];
        
        // return $this->deliver($arguments['bundleidentifier'], self::API_V2, '');
        $files = $this->getApplicationVersions($bundleidentifier, self::PLATFORM_ANDROID);
        
        if (count($files) == 0) {
            Logger::log("no versions found: $bundleidentifier $type");
            return Helper::sendJSONAndExit(self::E_NO_VERSIONS_FOUND);
        }

        $this->addStats($bundleidentifier);
        return $this->deliverJSON($api, $files);
    }

    protected function download($arguments) {
        
        $bundleidentifier = $arguments['bundleidentifier'];
        $type             = $arguments['type'];
        
        $files = $this->getApplicationVersions($bundleidentifier, self::PLATFORM_ANDROID);
        if (count($files) == 0) {
            Logger::log("no versions found: $bundleidentifier $type");
            return Helper::sendJSONAndExit(self::E_NO_VERSIONS_FOUND);
        }
        $this->addStats($bundleidentifier);

        $current = current($files[self::VERSIONS_SPECIFIC_DATA]);
        
        if ($type == 'app')
        {
            $file = isset($current[self::FILE_ANDROID_APK]) ? $current[self::FILE_ANDROID_APK] : null;

            if (!$file)
            {
                return Router::get()->serve404();
            }
            return Helper::sendFile($file, AppUpdater::CONTENT_TYPE_APK);
        }
        
        return Router::get()->serve404();
    }

    protected function deliverJSON($api, $files)
    {
        // check for available updates for the given bundleidentifier
        // and return a JSON string with the result values

        $current = current($files[self::VERSIONS_SPECIFIC_DATA]);
        $apk  = isset($current[self::FILE_ANDROID_APK]) ? $current[self::FILE_ANDROID_APK] : null;
        $json = isset($current[self::FILE_ANDROID_JSON]) ? $current[self::FILE_ANDROID_JSON] : null;
        
        $image = $files[self::VERSIONS_COMMON_DATA][self::FILE_COMMON_ICON];
        
        if ($apk && $json) {
            $result = array();
            $appversion =  Router::arg(self::CLIENT_KEY_APPVERSION);
            
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

                $result[] = $newAppVersion;
                
                // only send the data until the current version if provided
                if ($appversion == $parsed_json['versionCode']) break;
            }
            return Helper::sendJSONAndExit($result);
        }
        Logger::log("no versions found: android/deliverJSON");
        return Helper::sendJSONAndExit(self::E_NO_VERSIONS_FOUND);
    }

    protected function deliver($bundleidentifier, $api, $type)
    {
        $files = $this->getApplicationVersions($bundleidentifier);

        if (count($files) == 0) {
            Logger::log("no versions found: $bundleidentifier $api $type");
            return Helper::sendJSONAndExit(self::E_NO_VERSIONS_FOUND);
        }
                        
        $current = current($files[self::VERSIONS_SPECIFIC_DATA]);
        $apk  = isset($current[self::FILE_ANDROID_APK]) ? $current[self::FILE_ANDROID_APK] : null;
        $json = isset($current[self::FILE_ANDROID_JSON]) ? $current[self::FILE_ANDROID_JSON] : null;
        
        // notes file is optional, other files are required
        if (!$apk || !$json) {
            Logger::log("files incomplete: $bundleidentifier $api $type");
            return Helper::sendJSONAndExit(self::E_FILES_INCOMPLETE);
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