<?php
require_once('config.php');
require_once('app_view.php');
require(constant('HOCKEY_INCLUDE_DIR'));

$router = Router::get(array('appDirectory' => dirname(__FILE__).DIRECTORY_SEPARATOR));
$apps = $router->app;
$b = $router->baseURL;
require(constant('HOCKEY_LANG_STRINGS'));
DeviceDetector::detect();
?>
<!DOCTYPE html>

<html>
<head>
    <meta charset="utf-8">
    <title><?php echo $title ?></title>
    <meta name="viewport" content="width=device-width" />
    <link rel="stylesheet" href="<?php echo $b ?>blueprint/screen.css" type="text/css" media="screen, projection">
    <link rel="stylesheet" href="<?php echo $b ?>blueprint/print.css" type="text/css" media="print">
    <!--[if IE]><link rel="stylesheet" href="<?php echo $b ?>blueprint/ie.css" type="text/css" media="screen, projection"><![endif]-->
    <link rel="stylesheet" href="<?php echo $b ?>blueprint/plugins/buttons/screen.css" type="text/css" media="screen, projection">
    <link rel="stylesheet" type="text/css" href="<?php echo $b ?>css/stylesheet.css">
    <link rel="alternate" type="application/rss+xml" title="App Updates" href="<?php echo $b ?>feed.php" />
</head>
<body class="<?php echo DeviceDetector::$category; ?>">
    <div id='container' class='container'>
        <?php if (DeviceDetector::$isAndroidDevice)
        { ?>
        <div class='android'>
        	<h1><?php echo $header ?></h1>
        	<?php
           	$androidAppsAvailable = 0;
            foreach ($apps->applications as $i => $app) :
                if ($app[AppUpdater::INDEX_PLATFORM] == AppUpdater::APP_PLATFORM_ANDROID)
                {
                    $androidAppsAvailable++;
                }
            endforeach;

            if ($androidAppsAvailable > 1)
            {?>
            <p class="bordertop"></p>
        	<div class="grid">
            	<h2><?php echo $choose_app ?></h2>
        		<?php
                $column= 0;
                foreach ($apps->applications as $i => $app)
                {
                	if ($app[AppUpdater::INDEX_PLATFORM] != AppUpdater::APP_PLATFORM_ANDROID)
                    	continue;
                    $column++;
                	$appView = new AppView();
                	echo $appView->getSmallScreenIconView($app,$b);
                	if ($column == 2) {
                    	echo "<div style='clear:both;'></div>";
                    $column = 0;
               		}
                }?>
           	</div>
           	<div style='clear:both;'><br/></div>
           	<p><br/></p>
           	<?php
            foreach ($apps->applications as $i => $app)
            {
            	if ($app[AppUpdater::INDEX_PLATFORM] != AppUpdater::APP_PLATFORM_ANDROID)
                	continue;
            	$appView = new AppView();
            	echo $appView->getSmallScreenInfoView($app,$b);
            }
            }?>
        </div>
		<?php 
		} 
		else if (DeviceDetector::$isOldIOSDevice)
        { ?>
        <div class='old-ios'>
            <?php echo $old_IOS_string ?>
        </div>
		<?php 
		} 
		else if (DeviceDetector::$isNewIOSDevice)
        { ?>
        <div class='new-ios'>
            <h1><?php echo $header ?></h1>

            <p><?php echo $hint_app_fail ?></p>
			<?php
            $iOSAppsAvailable = 0;
            foreach ($apps->applications as $i => $app) :
                if ($app[AppUpdater::INDEX_PLATFORM] == AppUpdater::APP_PLATFORM_IOS)
                {
                    $iOSAppsAvailable++;
                }
            endforeach;

            if ($iOSAppsAvailable > 1)
            {?>
            <p class="bordertop"></p>
        	<div class="grid">
            	<h2><?php echo $choose_app ?></h2>
        		<?php
                $column= 0;
                foreach ($apps->applications as $i => $app)
                {
                	if ($app[AppUpdater::INDEX_PLATFORM] != AppUpdater::APP_PLATFORM_IOS)
                    	continue;
                    $column++;
                	$appView = new AppView();
                	echo $appView->getSmallScreenIconView($app,$b);
                	if ($column == 2) {
                    	echo "<div style='clear:both;'></div>";
                    $column = 0;
               		}
                }?>
           	</div>
           	<div style='clear:both;'><br/></div>
           	<p><br/></p>
           	<?php
            foreach ($apps->applications as $i => $app)
            {
            	if ($app[AppUpdater::INDEX_PLATFORM] != AppUpdater::APP_PLATFORM_IOS)
                	continue;
            	$appView = new AppView();
            	echo $appView->getSmallScreenInfoView($app,$b);
            }
            }?>
        </div>
		<?php 
		} 
		else if (DeviceDetector::$isiPad4Device)
        { ?>
        <div class='ipad-ios4'>
            <h1><?php echo $header ?></h1>
            <p class='hintdevice'><?php echo $hint_vis_fr_dev ?></p>
            <p class='hintdevice'><?php echo $hint_not_ios4 ?></p>
            <p class='hintipad'><?php echo $hint_app_fail ?></p><br>

            <p class="bordertop"><br></p>
            <?php
            $column= 0;
            foreach ($apps->applications as $i => $app)
            {
            	if ($app[AppUpdater::INDEX_PLATFORM] != AppUpdater::APP_PLATFORM_IOS)
                	continue;
                $column++;
            	$appView = new AppView();
            	echo $appView->getIconView($app,$b);
            	echo $appView->getInfoView($app,$b);
            	if ($column == 2)
                {
                    echo "<div style='clear:both;'><br/><p  class='bordertop'><br/></p></div>";
                    $column = 0;
                }
            }
            ?>
        </div>
		<?php 
		} 
		else
        { ?>
        <div class='desktop'>
        	<h1><?php echo $header ?></h1>
            <p class='hintdevice'><?php echo $hint_vis_fr_dev ?></p>
            <p class='hintdevice'><strong>iOS:</strong> <?php echo $hint_not_ios4 ?></p>
            <p class='hintipad'><?php echo $hint_app_fail ?></p><br>

            <p class="bordertop"><br></p>
			<?php
			$column= 0;
            foreach ($apps->applications as $i => $app)
            {
            	$column++;
            	$appView = new AppView();
            	echo $appView->getIconView($app,$b);
            	echo $appView->getInfoView($app,$b);
            	if ($column == 2)
                {
                    echo "<div style='clear:both;'><br/><p  class='bordertop'><br/></p></div>";
                    $column = 0;
                }
            }
            ?> 
        </div>
		<?php } ?>
    </div>
	<script type="text/javascript" charset="utf-8">
/mobile/i.test(navigator.userAgent) &&
            !window.location.hash &&
            setTimeout(function () { window.scrollTo(0, 1); }, 2000);
    </script>
</body>
</html>
