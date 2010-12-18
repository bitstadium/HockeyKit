<?php
    require_once('config.php');
    require(constant('HOCKEY_INCLUDE_DIR'));
    
    $ios = new iOSUpdater(dirname(__FILE__).DIRECTORY_SEPARATOR);
    $baseURL = "http://".$_SERVER['SERVER_NAME'].$_SERVER['REQUEST_URI'];
	$baseURL = str_replace("/feed.php", "/", $baseURL);
    echo '<?xml version="1.0" encoding="utf-8"?>';
?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title><?php echo $_SERVER['SERVER_NAME'] ?> iOS Apps Updates</title>
  <subtitle></subtitle>
  <link rel="alternate" type="text/html" href="<?php echo $baseURL ?>"/>
  <link rel="self" type="application/atom+xml" href="<?php echo $baseURL ?>/feed.php"/>
  <id><?php echo $baseURL ?></id>
<?php 
    foreach ($ios->applications as $i => $app) :
?>

  <entry>
    <title><?php echo $app[iOSUpdater::INDEX_APP] ?> V<?php 
    if ($app[iOSUpdater::INDEX_SUBTITLE]) {
      echo $app[iOSUpdater::INDEX_SUBTITLE]." (".$app[iOSUpdater::INDEX_VERSION].")";
    } else {
      echo $app[iOSUpdater::INDEX_VERSION];
    } ?></title>
    <id><?php echo $app[iOSUpdater::INDEX_APP].$app[iOSUpdater::INDEX_SUBTITLE].$app[iOSUpdater::INDEX_VERSION] ?></id>
    <link rel="alternate" type="text/html" href="<?php echo $baseURL ?>"/>
    <published><?php echo date('Y-m-d\TH:i:s\Z', $app[iOSUpdater::INDEX_DATE]) ?></published>
    <updated><?php echo date('Y-m-d\TH:i:s\Z', $app[iOSUpdater::INDEX_DATE]) ?></updated>
    <content type="html" xml:base="http://<?php echo $_SERVER['SERVER_NAME'] ?>/" xml:lang="en"><![CDATA[
    <?php if ($app[iOSUpdater::INDEX_IMAGE]) { ?>
        <p><img src="<?php echo $baseURL."/../".$app[iOSUpdater::INDEX_IMAGE] ?>"></p>
    <?php } ?>
    <p><b>Application:</b> <?php echo $app[iOSUpdater::INDEX_APP] ?></p>
    <?php if ($app[iOSUpdater::INDEX_SUBTITLE]) { ?>
      <p><b>Version:</b> <?php echo $app[iOSUpdater::INDEX_SUBTITLE] ?> (<?php echo $app[iOSUpdater::INDEX_VERSION] ?>)</p>
    <?php } else { ?>
      <p><b>Version:</b> <?php echo $app[iOSUpdater::INDEX_VERSION] ?></p>
    <?php } ?>
    <p><b>Released:</b> <?php echo date('m/d/Y H:i:s', $app[iOSUpdater::INDEX_DATE]) ?></p>
    <?php if ($app[iOSUpdater::INDEX_NOTES]) : ?>
        <p><b>What's New:</b><br/><?php echo $app[iOSUpdater::INDEX_NOTES] ?></p>
    <?php endif ?>]]></content>
  </entry>
<?php 
    endforeach;
?>
</feed>
