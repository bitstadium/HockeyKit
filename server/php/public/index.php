<?php
    require_once('config.php');
    require(constant('HOCKEY_INCLUDE_DIR'));
    
    $ios = new iOSUpdater(dirname(__FILE__).DIRECTORY_SEPARATOR);
    $protocol = $_SERVER["HTTPS"]?'https':'http';
    $port = '';
    if ((($protocol=='http')&&($_SERVER["SERVER_PORT"]!='80')) ||
        (($protocol=='https')&&($_SERVER["SERVER_PORT"]!='443'))) {
      $port = ':'.$_SERVER["SERVER_PORT"];
    }
    $baseURL = $protocol."://".$_SERVER['SERVER_NAME'].$port.$_SERVER['REQUEST_URI'];
?>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <title>iOS App Installer</title>
    	<meta name="viewport" content="width=device-width" />
        <link rel="stylesheet" href="blueprint/screen.css" type="text/css" media="screen, projection">
        <link rel="stylesheet" href="blueprint/print.css" type="text/css" media="print">
        <!--[if IE]><link rel="stylesheet" href="blueprint/ie.css" type="text/css" media="screen, projection"><![endif]-->
        <link rel="stylesheet" href="blueprint/plugins/buttons/screen.css" type="text/css" media="screen, projection">
        <link rel="stylesheet" type="text/css" href="css/stylesheet.css">
        <link rel="alternate" type="application/rss+xml" title="iOS Apps Updates" href="feed.php" />
    </head>
    <body>
        <div id="container" class="container">
            
            <div class='old-ios'>

                <h3>Direct Installation Not Supported</h3>

                <p>You are running a version of iOS that does not support direct installation. Please visit this page on your Mac or PC to download an app.</p>
                <p>If you are able to upgrade your device to iOS 4.0 or later, simply visit this page with your iPad, iPhone, or iPod touch and you can install an app directly on your device.</p>

            </div>

            <div class='desktop'>
            
                <h1>Install Apps</h1>

                <p class='hintdevice'>Visit this page directly from your your iPad, iPhone, or iPod touch and you will be able to install an app directly on your device. (requires iOS 4.0 or later)</p>

                <p class='hintdevice'>If your device does not have iOS 4.0 or later, please download the provisioning profile and the application on your computer from this page and install it <a href="itunes-installation.html">manually</a> via iTunes.
                </p>
                
                <p class='hintipad'>If installation of an application fails, please install the provisioning profile. After you install the provisioning profile, try to install the application again. If it still fails, your device might not have been approved yet.</p>

                <br/>
                <p class="bordertop"><br/></p>

            <?php 
                $column= 0;
                foreach ($ios->applications as $i => $app) :
                    $column++;
            ?>
                <div class="column span-3">
                <?php if ($app[iOSUpdater::INDEX_IMAGE] != "") { ?>
                    <img class="icon" src="<?php echo $app[iOSUpdater::INDEX_IMAGE] ?>">
                <?php } ?>
                </div>
                <div class="column span-8">
                    <h2><?php echo $app[iOSUpdater::INDEX_APP] ?></h2>
                  <?php if (array_key_exists(iOSUpdater::INDEX_SUBTITLE, $app)) { ?>
                    <p><b>Version:</b> <?php echo $app[iOSUpdater::INDEX_SUBTITLE] ?> (<?php echo $app[iOSUpdater::INDEX_VERSION] ?>)</p>
                  <?php } else { ?>
                    <p><b>Version:</b> <?php echo $app[iOSUpdater::INDEX_VERSION] ?></p>
                  <?php } ?>
                    <p><b>Released:</b> <?php echo date('m/d/Y H:i:s', $app[iOSUpdater::INDEX_DATE]) ?></p>

                    <div class="desktopbuttons">
                <?php if (array_key_exists(iOSUpdater::INDEX_PROFILE, $app)) { ?>
                        <a class="button" href="<?php echo $baseURL . 'index.php?type=' . iOSUpdater::TYPE_PROFILE . '&bundleidentifier=' . $app[iOSUpdater::INDEX_DIR] ?>">Download Profile </a>
                <?php } ?>
                        <a class="button" href="<?php echo $baseURL . 'index.php?type=' . iOSUpdater::TYPE_IPA . '&bundleidentifier=' . $app[iOSUpdater::INDEX_DIR] ?>">Download Application</a>
                    </div>

                <?php if ($app[iOSUpdater::INDEX_NOTES] != "") : ?>
                    <p><br/><br/></p>
                    <p><b>What's New:</b><br/><?php echo $app[iOSUpdater::INDEX_NOTES] ?></p>
                <?php endif ?>

                </div>

            <?php 
                    if ($column == 2) {
                        echo "<div style='clear:both;'><br/><p  class='bordertop'><br/></p></div>";
                        $column = 0;
                    }
                endforeach;
            ?>

            </div>

            <div class='ipad-ios4'>
            
                <h1>Install Apps</h1>

                <p class='hintdevice'>Visit this page directly from your your iPad, iPhone, or iPod touch and you will be able to install an app directly on your device. (requires iOS 4.0 or later)</p>

                <p class='hintdevice'>If your device does not have iOS 4.0 or later, please download the provisioning profile and the application on your computer from this page and install it <a href="itunes-installation.html">manually</a> via iTunes.
                </p>
                
                <p class='hintipad'>If installation of an application fails, please install the provisioning profile. After you install the provisioning profile, try to install the application again. If it still fails, your device might not have been approved yet.</p>

                <br/>
                <p class="bordertop"><br/></p>

            <?php 
                $column= 0;
                foreach ($ios->applications as $i => $app) :
                    $column++;
            ?>
                <div class="column span-3">
                <?php if ($app[iOSUpdater::INDEX_IMAGE] != "") { ?>
                    <img class="icon" src="<?php echo $app[iOSUpdater::INDEX_IMAGE] ?>">
                <?php } ?>
                </div>
                <div class="column span-6">
                    <h2><?php echo $app[iOSUpdater::INDEX_APP] ?></h2>
                <?php if (array_key_exists(iOSUpdater::INDEX_SUBTITLE, $app)) { ?>
                    <p><b>Version:</b> <?php echo $app[iOSUpdater::INDEX_SUBTITLE] ?> (<?php echo $app[iOSUpdater::INDEX_VERSION] ?>)</p>
                <?php } else { ?>
                    <p><b>Version:</b> <?php echo $app[iOSUpdater::INDEX_VERSION] ?></p>
                <?php } ?>
                    <p><b>Released:</b> <?php echo date('m/d/Y H:i:s', $app[iOSUpdater::INDEX_DATE]) ?></p>

                    <div class="ipadbuttons">
                <?php if (array_key_exists(iOSUpdater::INDEX_PROFILE, $app)) { ?>
                        <a class="button" href="<?php echo $baseURL . 'index.php?type=' . iOSUpdater::TYPE_PROFILE . '&bundleidentifier=' . $app[iOSUpdater::INDEX_DIR] ?>">Install Profile</a>
                <?php } ?>
                        <a class="button" href="itms-services://?action=download-manifest&amp;url=<?php echo urlencode($baseURL . 'index.php?type=' . iOSUpdater::TYPE_APP . '&bundleidentifier=' . $app[iOSUpdater::INDEX_DIR]) ?>">Install Application</a>
                    </div>

                <?php if ($app[iOSUpdater::INDEX_NOTES] != "") : ?>
                    <p><br/><br/></p>
                    <p><b>What's New:</b><br/><?php echo $app[iOSUpdater::INDEX_NOTES] ?></p>
                <?php endif ?>

                </div>

            <?php 
                    if ($column == 2) {
                        echo "<div style='clear:both;'><br/><p  class='bordertop'><br/></p></div>";
                        $column = 0;
                    }
                endforeach;
            ?>

            </div>

            
            <div class='new-ios'>
            
                <h1>Install Apps</h1>

                <p>If installation of an application fails, please install the provisioning profile. After you install the provisioning profile, try to install the application again. If it still fails, your device might not have been approved yet.</p>
            <?php if (count($ios->applications) > 1) { ?>
                <p class="bordertop"></p>
                <div class="grid">
                    <h2>Choose Your App:</h2>
            <?php
                    $column= 0;
                    foreach ($ios->applications as $i => $app) :
                        $column++;
            ?>
                    <div class="column span-4">
                        <a href="#<?php echo $app[iOSUpdater::INDEX_APP] ?>">
            <?php if ($app[iOSUpdater::INDEX_IMAGE] != "") { ?>
                            <img class="icon" src="<?php echo $app[iOSUpdater::INDEX_IMAGE] ?>">
            <?php } ?>
                            <h4><?php echo $app[iOSUpdater::INDEX_APP] ?></h4>
                        </a>
                    </div>

            <?php
                        if ($column == 2) {
                            echo "<div style='clear:both;'></div>";
                            $column = 0;
                        }
                    endforeach;
            ?>
                </div>
            <?php
                }
            ?>
                <div style='clear:both;'><br/></div>

            <?php if (count($ios->applications) > 1) { ?>
                <p><br/></p>
            <?php } ?>
            <?php foreach ($ios->applications as $i => $app) : ?>

                <div class="version">
                    <p class="borderbottom"></p>
                    <a name="<?php echo $app[iOSUpdater::INDEX_APP] ?>"><br/></a>
                <?php if ($app[iOSUpdater::INDEX_IMAGE] != "") { ?>
                    <img class="icon" src="<?php echo $app[iOSUpdater::INDEX_IMAGE] ?>">
                <?php } ?>
                    <h2><?php echo $app[iOSUpdater::INDEX_APP] ?></h2>
                <?php if (array_key_exists(iOSUpdater::INDEX_SUBTITLE, $app)) { ?>
                    <p><b>Version:</b> <?php echo $app[iOSUpdater::INDEX_SUBTITLE] ?> (<?php echo $app[iOSUpdater::INDEX_VERSION] ?>)</p>
                <?php } else { ?>
                    <p><b>Version:</b> <?php echo $app[iOSUpdater::INDEX_VERSION] ?></p>
                <?php } ?>
                    <p><b>Released:</b> <?php echo date('m/d/Y H:i:s', $app[iOSUpdater::INDEX_DATE]) ?></p>
                <?php if (array_key_exists(iOSUpdater::INDEX_PROFILE, $app)) { ?>                    
                    <a class="button" href="<?php echo $baseURL . 'index.php?type=' . iOSUpdater::TYPE_PROFILE . '&bundleidentifier=' . $app[iOSUpdater::INDEX_DIR] ?>">Install Profile</a>
                <?php } ?>
                    <a class="button" href="itms-services://?action=download-manifest&amp;url=<?php echo urlencode($baseURL . 'index.php?type=' . iOSUpdater::TYPE_APP . '&bundleidentifier=' . $app[iOSUpdater::INDEX_DIR]) ?>">Install Application</a>
                <?php if ($app[iOSUpdater::INDEX_NOTES] != "") : ?>
                    <p><br/><br/></p>
                    <p><b>What's New:</b><br/><?php echo $app[iOSUpdater::INDEX_NOTES] ?></p>
                <?php endif ?>
                </div>
            <?php endforeach ?>
        	</div>

        <script>
        
            var isOldIOSDevice = false; 
            var isNewIOSDevice = false;
            var isiPad4Device = false;
            var className = "";
            
            var agent = navigator.userAgent;

            if (agent.indexOf('iPad') != -1) {
                if (agent.indexOf('OS 3') != -1) {
                    isOldIOSDevice = true;
                } else {
                    isiPad4Device = true;
                }
            } else if (agent.indexOf('iPhone') != -1) {
                if (agent.indexOf('iPhone OS 3') != -1) {
                    isOldIOSDevice = true;
                } else {
                    isNewIOSDevice = true;
                }
            }
            
            if (isNewIOSDevice) {
                className += "browser-ios4";
            } else if (isiPad4Device) {
                className += "browser-ipad4";
            } else if (isOldIOSDevice) {
                className += "browser-old-ios";
            } else {
                className += "browser-desktop";
            }

            document.getElementsByTagName('body')[0].className = className;
            
        </script>
        <script>/mobile/i.test(navigator.userAgent) && !window.location.hash && setTimeout(function () {
                window.scrollTo(0, 1);
            }, 2000);</script>
    </body>
</html>