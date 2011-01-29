<?php

/**
* abstract platform implementation
*/
abstract class AbstractAppUpdater extends AppUpdater
{

    protected function route() {
        $bundleidentifier = isset($_GET[self::CLIENT_KEY_BUNDLEID]) ?
            $this->validateDir($_GET[self::CLIENT_KEY_BUNDLEID]) : null;
        $type = isset($_GET[self::CLIENT_KEY_TYPE]) ?
			$this->validateType($_GET[self::CLIENT_KEY_TYPE]) : null;
        $api = isset($_GET[self::CLIENT_KEY_APIVERSION]) ?
			$this->validateAPIVersion($_GET[self::CLIENT_KEY_APIVERSION]) : self::API_V1;

        return $this->deliver($bundleidentifier, $api, $type);
    }

    abstract protected function deliver($bundleidentifier, $api, $type);
    abstract protected function deliverJson($api, $files);
	

}

?>
