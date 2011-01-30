<?php

/**
* abstract platform implementation
*/
abstract class AbstractAppUpdater extends AppUpdater
{

    public function route() {
        
        // clients always have to send bundleindentifier
        
        if (!isset($_GET[self::CLIENT_KEY_BUNDLEID]))
        {
            Logger::log('Unknown API called. Client request w/o bundle id.');
            Helper::sendJSONAndExit(self::E_UNKNOWN_API);
        }
        
        $bundleidentifier = $this->validateDir($_GET[self::CLIENT_KEY_BUNDLEID]);
        
        if (!$bundleidentifier) {
            Logger::log('No such bundle id: dir did not validate.');
            Helper::sendJSONAndExit(self::E_UNKNOWN_BUNDLE_ID);
        }
        
        $type = isset($_GET[self::CLIENT_KEY_TYPE]) ?
            $this->validateType($_GET[self::CLIENT_KEY_TYPE]) : null;
        $api = isset($_GET[self::CLIENT_KEY_APIVERSION]) ?
            $this->validateAPIVersion($_GET[self::CLIENT_KEY_APIVERSION]) : self::API_V1;

        return $this->deliver($bundleidentifier, $api, $type);
    }

    // abstract protected function deliver($bundleidentifier, $api, $type);
    abstract protected function deliverJSON($api, $files);

}

?>
