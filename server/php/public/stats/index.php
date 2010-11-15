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
                    <p><b>Version:</b> <?php echo $app[iOSUpdater::INDEX_VERSION] ?></p>
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

            </div>
        </div>
    </body>
</html>