<?php 
    require '../includes/main.php';
    $ios = new iOSUpdater(dirname(__FILE__).DIRECTORY_SEPARATOR);
    $baseURL = "http://".$_SERVER['SERVER_NAME'].$_SERVER['REQUEST_URI'];
?>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <title>iOS Beta Apps Installer</title>
        <style type="text/css" media="screen">@import "jqtouch/jqtouch.css";</style>
        <style type="text/css" media="screen">@import "jqtouch/themes/jqt/theme.css";</style>
        <script src="jqtouch/jquery-1.4.2.js" type="text/javascript" charset="utf-8"></script>
        <script src="jqtouch/jqtouch.js" type="application/x-javascript" charset="utf-8"></script>
        <script type="text/javascript" charset="utf-8">
            var jQT = new $.jQTouch({
                addGlossToIcon: false,
                statusBar: 'black',
                useFastTouch: false,
                preloadImages: [
                    'jqtouch/themes/jqt/img/back_button.png',
                    'jqtouch/themes/jqt/img/back_button_clicked.png',
                    'jqtouch/themes/jqt/img/button_clicked.png',
                    'jqtouch/themes/jqt/img/grayButton.png',
                    'jqtouch/themes/jqt/img/whiteButton.png',
                    'jqtouch/themes/jqt/img/loading.gif'
                    ]
            });
        </script>
        <style type="text/css" media="screen">
            #jqt.fullscreen #home .info {
                display: none;
            }
            div#jqt #about {
                padding: 100px 10px 40px;
                text-shadow: rgba(255, 255, 255, 0.3) 0px -1px 0;
                font-size: 13px;
                text-align: center;
                background: #161618;
            }
            div#jqt #about p {
                margin-bottom: 8px;
            }
            div#jqt #about a {
                color: #fff;
                font-weight: bold;
                text-decoration: none;
            }
        </style>
    </head>
    <body>
        <div id="jqt">
            <div id="about" class="selectable">
                    <p><strong>iOS Beta App Installer</strong><br />Version 0.1 beta<br />
                        <a href="http://www.buzzworks.de">By buzzworks.de</a></p>
                    <p><em>Update iOS beta apps and updates without iTunes from anywhere</em></p>
                    <p>
                        <a href="http://twitter.com/buzzworksHQ" target="_blank">@buzzworksHQ on Twitter</a>
                    </p>
                    <p><br /><br /><a href="#" class="grayButton goback">Close</a></p>
            </div>
            <?php foreach ($ios->applications as $i => $app) : ?>
                <div id="app_<?php echo $i ?>">
                    <div class="toolbar">
                        <h1><?php echo $app[iOSUpdater::INDEX_APP] ?></h1>
                        <a class="back" href="#home">Home</a>
                    </div>
                    
                <?php if ($app[iOSUpdater::INDEX_PROFILE]) { ?>
                    <h2>Provisioning Profile</h2>
                    <ul class="rounded">
                        <li><?php echo date('d.m.Y H:i:s', $app[iOSUpdater::INDEX_PROFILE_UPDATE]) ?></li>
                    </ul>
                    <div style="margin: 10px;">
                        <a href="<?php echo $app[iOSUpdater::INDEX_PROFILE] ?>" class="grayButton">Install Profile</a>
                    </div>
                <?php } ?>

                    <h2>Application</h2>
                    <ul class="rounded">
                        <li><?php echo $app[iOSUpdater::INDEX_APP] ?></li>
                        <li><small><?php echo $app[iOSUpdater::INDEX_VERSION] ?></small> Latest Version</li>
                        <?php if ($app[iOSUpdater::INDEX_NOTES]) : ?>
                            <li><p>Release Notes:<br/><?php echo $app[iOSUpdater::INDEX_NOTES] ?></p></li>
                        <?php endif ?>
                    </ul>

                    <div style="margin: 10px;">
                        <a href="itms-services://?action=download-manifest&amp;url=<?php echo urlencode($baseURL . 'index.php?type=' . iOSUpdater::TYPE_APP . '&bundleidentifier=' . $app[iOSUpdater::INDEX_DIR]) ?>" class="grayButton">Install Application</a>
                    </div>
                    <div class="info">
                        Use the Install buttons to either install the provisioning profile or the application.
                    </div>

                </div>
            <?php endforeach ?>
            <div id="home" class="current">
                <div class="toolbar">
                    <h1>iOS Beta Apps</h1>
                    <a class="button slideup" id="infoButton" href="#about">About</a>
                </div>
                <ul class="rounded">
            <?php foreach ($ios->applications as $i => $app) : ?>
              <li class="arrow"><a href="#<?php echo 'app_'.$i ?>"><?php echo $app[iOSUpdater::INDEX_APP] ?></a></li>
            <?php endforeach ?>
                </ul>
                <div class="info">
                    Choose the app from above you want to install on your device.
                </div>
            </div>
        </div>
    </body>
</html>
