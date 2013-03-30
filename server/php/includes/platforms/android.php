<?php

/**
* Android implementation
*/
class AndroidAppUpdater extends AbstractAppUpdater
{

    protected function status($arguments) {
        $api = self::API_V2;
        $bundleidentifier = $arguments[self::PARAM_2_IDENTIFIER];
        
        $files = $this->getApplicationVersions($bundleidentifier, self::PLATFORM_ANDROID);
        
        if (count($files) == 0) {
            Logger::log("no versions found: $bundleidentifier $type");
            return Helper::sendJSONAndExit(self::E_NO_VERSIONS_FOUND);
        }

        $this->addStats($bundleidentifier, null);
        return $this->deliverJSON($api, $files);
    }

    protected function download($arguments) {
        
        $bundleidentifier = $arguments[self::PARAM_2_IDENTIFIER];
        $format           = $arguments[self::PARAM_2_FORMAT];
        
        $files = $this->getApplicationVersions($bundleidentifier, self::PLATFORM_ANDROID);
        if (count($files) == 0) {
            Logger::log("no versions found: $bundleidentifier $type");
            return Helper::sendJSONAndExit(self::E_NO_VERSIONS_FOUND);
        }

        $path = $files[self::VERSIONS_SPECIFIC_DATA];
        $dir = array_shift(array_keys($path)); // Only variables should be passed by reference
        $current = $files[self::VERSIONS_SPECIFIC_DATA][$dir];
        
        if ($format == self::PARAM_2_FORMAT_VALUE_APK)
        {
            $file = isset($current[self::FILE_ANDROID_APK]) ? $current[self::FILE_ANDROID_APK] : null;
            
            if (!$file)
            {
                return Router::get()->serve404();
            }

            @ob_end_clean();
            return Helper::sendFile($file, self::CONTENT_TYPE_APK);
//            if ($dir == 0) $dir = ""; else $dir .= '/';
//            @ob_end_clean();
//            header('Location: ' . Router::get()->baseURL.$bundleidentifier.'/'.$dir.basename($file));
            exit;
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
            $appversion =  Router::arg(self::PARAM_2_APP_VERSION);
            
            // API version is V2 by default, even if the client provides V1
            foreach ($files[self::VERSIONS_SPECIFIC_DATA] as $version) {
                $apk = $version[self::FILE_ANDROID_APK];
                $json = $version[self::FILE_ANDROID_JSON];
                $note = $version[self::FILE_COMMON_NOTES];
                
                // parse the json file
                $parsed_json = json_decode(file_get_contents($json), true);
            
                $newAppVersion = array();
                // add the latest release notes if available
                if ($note) {
                    $newAppVersion[self::RETURN_V2_NOTES]       = Helper::nl2br_skip_html(file_get_contents($note));
                }

                $newAppVersion[self::RETURN_V2_TITLE]           = $parsed_json['title'];

                $newAppVersion[self::RETURN_V2_SHORTVERSION]    = $parsed_json['versionName'];
                $newAppVersion[self::RETURN_V2_VERSION]         = $parsed_json['versionCode'];
        
                $newAppVersion[self::RETURN_V2_TIMESTAMP]       = filectime($apk);
                $newAppVersion[self::RETURN_V2_APPSIZE]         = filesize($apk);

                // add the latest release notes if available
                if (isset($parsed_json['notes'])) {
                    $newAppVersion[self::RETURN_V2_NOTES] = Helper::nl2br_skip_html($parsed_json['notes']);
                }

                $result[] = $newAppVersion;
            }
            return Helper::sendJSONAndExit($result);
        }
        Logger::log("no versions found: android/deliverJSON");
        return Helper::sendJSONAndExit(self::E_NO_VERSIONS_FOUND);
    }
}

?>
