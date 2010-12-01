<?php 
    require '../../includes/main.php';
    $ios = new iOSUpdater(dirname(__FILE__).DIRECTORY_SEPARATOR."..".DIRECTORY_SEPARATOR);
    $baseURL = "http://".$_SERVER['SERVER_NAME'].$_SERVER['REQUEST_URI'];
?>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <title>iOS App Installer Statistics</title>
    	<meta name="viewport" content="width=device-width" />
        <link rel="stylesheet" href="../blueprint/screen.css" type="text/css" media="screen, projection">
        <link rel="stylesheet" href="../blueprint/print.css" type="text/css" media="print">
        <!--[if IE]><link rel="stylesheet" href="../blueprint/ie.css" type="text/css" media="screen, projection"><![endif]-->
        <link rel="stylesheet" href="../blueprint/plugins/buttons/screen.css" type="text/css" media="screen, projection">
        <link rel="stylesheet" type="text/css" href="../css/stylesheet.css">
    </head>
    <body class='browser-desktop'>
        <div id="container" class="container">            
            <div class='desktop'>
                <h1>Install Apps Statistics</h1>

            <?php 
                foreach ($ios->applications as $i => $app) :
            ?>
                <div class="column span-3">
                <?php if ($app[iOSUpdater::INDEX_IMAGE]) { ?>
                    <img class="icon" src="../<?php echo $app[iOSUpdater::INDEX_IMAGE] ?>">
                <?php } ?>
                </div>
                <div class="column span-8">
                    <h2><?php echo $app[iOSUpdater::INDEX_APP] ?></h2>
                  <?php if ($app[iOSUpdater::INDEX_SUBTITLE]) { ?>
                    <p><b>Version:</b> <?php echo $app[iOSUpdater::INDEX_SUBTITLE] ?> (<?php echo $app[iOSUpdater::INDEX_VERSION] ?>)</p>
                  <?php } else { ?>
                    <p><b>Version:</b> <?php echo $app[iOSUpdater::INDEX_VERSION] ?></p>
                  <?php } ?>
                    <p><b>Released:</b> <?php echo date('m/d/Y H:i:s', $app[iOSUpdater::INDEX_DATE]) ?></p>

                <?php if ($app[iOSUpdater::INDEX_NOTES]) : ?>
                    <p><b>What's New:</b><br/><?php echo $app[iOSUpdater::INDEX_NOTES] ?></p>
                <?php endif ?>

                </div>
                
                <div class="column span-12">
                    <table>
                        <tr>
                            <th>Version</th>
                            <th>User</th>
                            <th>iOS</th>
                            <th>Device</th>
                            <th>Last Check</th>
                        </tr>
            <?php 
                array_multisort($app[iOSUpdater::INDEX_STATS], SORT_NUMERIC, SORT_DESC);
                foreach ($app[iOSUpdater::INDEX_STATS] as $i => $device) :
                    echo "<tr>";
                    echo "  <td>".$device[iOSUpdater::DEVICE_APPVERSION]."</td>";
                    echo "  <td>".$device[iOSUpdater::DEVICE_USER]."</td>";
                    echo "  <td>".$device[iOSUpdater::DEVICE_OSVERSION]."</td>";
                    echo "  <td>".$device[iOSUpdater::DEVICE_PLATFORM]."</td>";
                    echo "  <td>".$device[iOSUpdater::DEVICE_LASTCHECK]."</td>";
                    echo "</tr>";
                endforeach;
            ?>
                    </table>
                </div>
                <div style='clear:both;'><br/></div>
            <?php
                endforeach;
            ?>

              <hr/>
              <p>Drag this bookmarklet <a href='javascript:(function(){var%20expIDs%20=%20/<td%20class="id"%20title="([^"]+)/g;var%20elIDs=%20document.body.innerHTML.match(expIDs);var%20expNames=/<td%20class="name">.*?<span([^<]+)/g;var%20elNames=document.body.innerHTML.match(expNames);var%20content%20=%20"";for%20(var%20i=0;%20i<elIDs.length;%20i++){var%20id=elIDs[i].substr(elIDs[i].lastIndexOf("\"")+1);var%20name="";if%20(elNames[i].search("<span%20title=")>-1){var%20start=elNames[i].lastIndexOf("title=")+7;var%20amount=elNames[i].lastIndexOf(">")-1-start;name=elNames[i].substr(start,amount);}else{name=elNames[i].substr(elNames[i].lastIndexOf(">")+1);}content+=id+";"+name+"<br>\n";}document.body.innerHTML=content;alert("Copy%20the%20content%20and%20paste%20it%20into%20userlist.txt%20in%20your%20Hockey%20stats%20directory")}());'>Hockey iOS Portal Device Parser</a> into your bookmarks bar. Then open the <a href="https://developer.apple.com/ios/manage/devices/index.action">iOS Provisioning Portal</a>, invoke the bookmarklet and paste the resulting new content into the userlist.txt inside this stats directory.</p>

            </div>
        </div>
    </body>
</html>