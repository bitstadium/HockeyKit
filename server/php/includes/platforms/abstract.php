<?php

/**
* abstract platform implementation
*/
abstract class AbstractAppUpdater extends AppUpdater
{
    // abstract protected function deliver($bundleidentifier, $api, $type);
    abstract protected function deliverJSON($api, $files);
}

?>
