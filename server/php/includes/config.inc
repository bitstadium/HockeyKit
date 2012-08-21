<?php
    define('HOCKEY_AUTH_SECRET', 'ChangeThisToYourOwnSecretString');
    define('ENABLE_LOGGING', true);
    // for use behind reverse proxy
    // Ex: define('BASE_URL', 'http://example.com/HockeyKit/');
    define('BASE_URL', NULL); 

// it is ok to leave out the closing PHP tag. That way you don't need to be careful about extra line breaks at the end of the file with output_buffering disabled