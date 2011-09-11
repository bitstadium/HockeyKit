<?php 
    require_once('../config.php');
    require('../' . constant('HOCKEY_INCLUDE_DIR'));
    
    $router = Router::get(array('appDirectory' => dirname(dirname(__FILE__)).DIRECTORY_SEPARATOR, 'logic' => 'stats'));
    $apps = $router->app;
    $baseURL = $router->baseURL;
?>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <title>App Installer Statistics</title>
    	<meta name="viewport" content="width=device-width" />
        <link rel="stylesheet" href="../blueprint/screen.css" type="text/css" media="screen, projection">
        <link rel="stylesheet" href="../blueprint/print.css" type="text/css" media="print">
        <!--[if IE]><link rel="stylesheet" href="../blueprint/ie.css" type="text/css" media="screen, projection"><![endif]-->
        <link rel="stylesheet" href="../blueprint/plugins/buttons/screen.css" type="text/css" media="screen, projection">
        <link rel="stylesheet" type="text/css" href="../css/stylesheet.css">
        <script type="text/javascript">
            activeAppId = -1;
            function showAppStats(appId) {
                if (activeAppId >= -1) {
                    document.getElementById('app' + activeAppId).style.display = "none";
                }
                document.getElementById('app' + appId).style.display = "block";
                activeAppId = appId;
            }
        </script>
    </head>
    <body class='browser-desktop'>
        <div id="container" class="container">            
            <div class='desktop'>
                <h1>App Statistics</h1>

                <div class="column span-23">
            <?php 
                foreach ($apps->applications as $i => $app) :
                    echo "<div class=\"column span-3 appgridelement\"><a href=\"javascript:showAppStats(".$i.")\">";
                    if ($app[AppUpdater::INDEX_IMAGE]) {
                        echo "<img src=\"../" . $app[AppUpdater::INDEX_IMAGE] . "\" title=\"" . $app[AppUpdater::INDEX_APP] . "\" class=\"appgridicon\"><br/>";
                    }
                    echo $app[AppUpdater::INDEX_APP] . "</a></div>";
                endforeach;
            ?>
                </div>
                <div style='clear:both;'><br/></div>
                <hr/>
                <div class="column span-23" id="app-1" style="display:block;">
                    <p>Please select an app from above to see its statistics</p>
                </div>
            <?php
                foreach ($apps->applications as $i => $app) :
            ?>
                <div class="column span-23" id="app<?php echo $i ?>" style="display:none;">
                <div class="column span-3">
                <?php if ($app[AppUpdater::INDEX_IMAGE]) { ?>
                    <img class="appgridicon" src="../<?php echo $app[AppUpdater::INDEX_IMAGE] ?>">
                <?php } ?>
                </div>
                <div class="column span-6">
                    <h2><?php echo $app[AppUpdater::INDEX_APP] ?></h2>
                  <?php if (isset($app[AppUpdater::INDEX_SUBTITLE]) && $app[AppUpdater::INDEX_SUBTITLE]) { ?>
                    	<b>Version:</b> <?php echo $app[AppUpdater::INDEX_SUBTITLE] ?> (<?php echo $app[AppUpdater::INDEX_VERSION] ?>)
                  <?php } else { ?>
                    	<b>Version:</b> <?php echo $app[AppUpdater::INDEX_VERSION] ?>
                  <?php } ?>
                      	<br/>
						<b>Released:</b> <?php echo date('m/d/Y H:i:s', $app[AppUpdater::INDEX_DATE]) ?>
					
                </div>

                <div class="column span-13">
                <?php if (isset($app[AppUpdater::INDEX_NOTES]) && $app[AppUpdater::INDEX_NOTES]) : ?>
                    <p><b>What's New:</b><br/><?php echo $app[AppUpdater::INDEX_NOTES] ?></p>
                <?php endif ?>
                </div>
                
                <div class="column span-23">
                    <table>
                        <tr>
                            <th>Version</th>
                            <th>User</th>
                            <th>iOS</th>
                            <th>Device</th>
                            <th>Lang</th>
                            <th>Installed</th>
                            <th>Usage Time</th>
                            <th>Last Check</th>
                        </tr>
            <?php 
                foreach ($app[AppUpdater::INDEX_STATS] as $i => $device) :
                    echo "<tr>";
                    echo "  <td>".urldecode($device[AppUpdater::DEVICE_APPVERSION])."</td>";
					if (strlen($device[AppUpdater::DEVICE_USER]) > 15) {
						echo "  <td title='".$device[AppUpdater::DEVICE_USER]."'>".substr($device[AppUpdater::DEVICE_USER],0,12)."...</td>";
					} else {
                    	echo "  <td>".$device[AppUpdater::DEVICE_USER]."</td>";
					}
                    echo "  <td>".$device[AppUpdater::DEVICE_OSVERSION]."</td>";
                    echo "  <td>".$device[AppUpdater::DEVICE_PLATFORM]."</td>";
                    echo "  <td>".$device[AppUpdater::DEVICE_LANGUAGE]."</td>";
                    echo "  <td>".$device[AppUpdater::DEVICE_INSTALLDATE]."</td>";
                    echo "  <td>".Helper::secondsToTime($device[AppUpdater::DEVICE_USAGETIME])."</td>";
                    echo "  <td>".$device[AppUpdater::DEVICE_LASTCHECK]."</td>";
                    echo "</tr>";
                endforeach;
            ?>
                    </table>
                </div>
                </div>
            <?php
                endforeach;
            ?>

              <hr/>
              <p>Drag this bookmarklet <a href='javascript:(function(){var%20expIDs%20=%20/<td%20class="id"%20title="([^"]+)/g;var%20elIDs=%20document.body.innerHTML.match(expIDs);var%20expNames=/<td%20class="name">.*?<span([^<]+)/g;var%20elNames=document.body.innerHTML.match(expNames);var%20content%20=%20"";for%20(var%20i=0;%20i<elIDs.length;%20i++){var%20id=elIDs[i].substr(elIDs[i].lastIndexOf("\"")+1);var%20name="";if%20(elNames[i].search("<span%20title=")>-1){var%20start=elNames[i].lastIndexOf("title=")+7;var%20amount=elNames[i].lastIndexOf(">")-1-start;name=elNames[i].substr(start,amount);}else{name=elNames[i].substr(elNames[i].lastIndexOf(">")+1);}content+=id+";"+name+"<br>\n";}document.body.innerHTML=content;alert("Copy%20the%20content%20and%20paste%20it%20into%20userlist.txt%20in%20your%20Hockey%20stats%20directory")}());'>Hockey iOS Portal Device Parser</a> into your bookmarks bar. Then open the <a href="https://developer.apple.com/ios/manage/devices/index.action">iOS Provisioning Portal</a>, invoke the bookmarklet and paste the resulting new content into the userlist.txt inside this stats directory.</p>

            </div>
        </div>
    </body>
</html>