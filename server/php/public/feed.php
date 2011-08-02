<?php
    require_once('config.php');
    require(constant('HOCKEY_INCLUDE_DIR'));
    
    $router = Router::get(array('appDirectory' => dirname(__FILE__).DIRECTORY_SEPARATOR));
    $apps = $router->app;
    $baseURL = $router->baseURL;
    echo '<?xml version="1.0" encoding="utf-8"?>';
?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title><?php echo $router->servername; ?> Apps Updates</title>
  <subtitle></subtitle>
  <link rel="alternate" type="text/html" href="<?php echo $baseURL ?>"/>
  <link rel="self" type="application/atom+xml" href="<?php echo $baseURL ?>/feed.php"/>
  <id><?php echo $baseURL ?></id>
<?php 
    foreach ($apps->applications as $i => $app) :
?>

  <entry>
    <title><?php echo $app[AppUpdater::INDEX_APP] ?> V<?php 
    if (isset($app[AppUpdater::INDEX_SUBTITLE]) && $app[AppUpdater::INDEX_SUBTITLE]) {
      echo $app[AppUpdater::INDEX_SUBTITLE]." (".$app[AppUpdater::INDEX_VERSION].")";
    } else {
      echo $app[AppUpdater::INDEX_VERSION];
    } ?></title>
    <id><?php echo preg_replace(
      '/\W/',
      '_',
      $app[AppUpdater::INDEX_APP].
      (
        isset($app[AppUpdater::INDEX_SUBTITLE]) ?
          $app[AppUpdater::INDEX_SUBTITLE] :
          ''
      ).
      $app[AppUpdater::INDEX_VERSION]) ?></id>
		<link rel="alternate" type="text/html" href="<?php echo $baseURL ?>"/>
    <published><?php echo date('Y-m-d\TH:i:s\Z', $app[AppUpdater::INDEX_DATE]) ?></published>
    <updated><?php echo date('Y-m-d\TH:i:s\Z', $app[AppUpdater::INDEX_DATE]) ?></updated>
    <content type="html" xml:base="http://<?php echo $router->servername ?>/" xml:lang="en"><![CDATA[
    <?php if ($app[AppUpdater::INDEX_IMAGE]) { ?>
        <p><img src="<?php echo $baseURL.$app[AppUpdater::INDEX_IMAGE] ?>"></p>
    <?php } ?>
    <p><b>Application:</b> <?php echo $app[AppUpdater::INDEX_APP] ?></p>
    <?php if (isset($app[AppUpdater::INDEX_SUBTITLE]) && $app[AppUpdater::INDEX_SUBTITLE]) { ?>
      <p><b>Version:</b> <?php echo $app[AppUpdater::INDEX_SUBTITLE] ?> (<?php echo $app[AppUpdater::INDEX_VERSION] ?>)</p>
    <?php } else { ?>
      <p><b>Version:</b> <?php echo $app[AppUpdater::INDEX_VERSION] ?></p>
    <?php } ?>
    <p><b>Released:</b> <?php echo date('m/d/Y H:i:s', $app[AppUpdater::INDEX_DATE]) ?></p>
    <?php if (isset($app[AppUpdater::INDEX_NOTES]) && $app[AppUpdater::INDEX_NOTES]) : ?>
        <p><b>What's New:</b><br/><?php echo $app[AppUpdater::INDEX_NOTES] ?></p>
    <?php endif ?>]]></content>
  </entry>
<?php 
    endforeach;
?>
</feed>
