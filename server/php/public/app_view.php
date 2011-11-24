<?php 
require_once('config.php');

class AppView
{
	//Android and iPhone/iPod Touch
	public function getSmallScreenInfoView($app, $b) 
	{
		require(constant('HOCKEY_LANG_STRINGS'));
		//Conditionals
		$title = '';
		if (isset($app[AppUpdater::INDEX_SUBTITLE]) && $app[AppUpdater::INDEX_SUBTITLE])
        {
        	$title= $app[AppUpdater::INDEX_SUBTITLE] . " (" . $app[AppUpdater::INDEX_VERSION] . ")";
        } 
        else
        {
        	$title= $app[AppUpdater::INDEX_VERSION];
        }
		$app_size='';
		if ($app[AppUpdater::INDEX_APPSIZE])
        {
            $app_size="<b>" . $size . "</b> " . round($app[AppUpdater::INDEX_APPSIZE] / 1024 / 1024, 1) . " MB<br/>";
        }
		$notes='';
		if ($app[AppUpdater::INDEX_NOTES])
		{
        	$notes=	'<p><br><br></p>'.
        			'<p><b>'.$whats_new.'</b><br>'.
        				$app[AppUpdater::INDEX_NOTES].
        			'</p>';
		}
		$iphone_clear='';
		$mob_prof='';
		$install_platform_url=$b.'api/2/apps/'.$app[AppUpdater::INDEX_DIR].'?format=apk';//Android
		if (DeviceDetector::$isNewIOSDevice) 
        {
			$iphone_clear="<div style='clear:both;'></div>";	
			$install_platform_url='itms-services://?action=download-manifest&amp;url='.urlencode($b.'api/2/apps/'.$app[AppUpdater::INDEX_DIR].'?format=plist');
       		if (isset($app[AppUpdater::INDEX_PROFILE]) && $app[AppUpdater::INDEX_PROFILE])
        	{
				$mob_prof='<a class="button" href="'.$b.'api/2/apps/'.$app[AppUpdater::INDEX_DIR].'?format=mobileprovision">'.$install_prof.'</a>';
			}
		}
		//The Info div
        $content = 	'<div class="version">';
        $content.=		'<p class="borderbottom"></p>';
        $content.=		'<a name="'.$app[AppUpdater::INDEX_APP].'"><br/></a>';
        $content.=		$this->getImageView($app, $b);
        $content.= 		'<h2>'.$app[AppUpdater::INDEX_APP].'</h2>';
        $content.= 		'<p><b>'.$version.'</b>';
        $content.=		$title;
        $content.=		"<br/>";
        $content.=		$app_size;
        $content.=		"<b>" . $released . "</b> " . date($date_string, $app[AppUpdater::INDEX_DATE]);
		$content.=		'</p>';
		$content.=		$iphone_clear;
        $content.=		$mob_prof;
        $content.=		'<a class="button" href="'.$install_platform_url.'">'.$install_app.'</a>';
		$content.=		$notes;
    	$content.=	'</div>';
		return $content;
	}
	//Desktop and iPad
	public function getInfoView($app, $b) 
	{
		require(constant('HOCKEY_LANG_STRINGS'));
		//Conditionals
		$title = '';
		if (isset($app[AppUpdater::INDEX_SUBTITLE]) && $app[AppUpdater::INDEX_SUBTITLE])
        {
        	$title= $app[AppUpdater::INDEX_SUBTITLE] . " (" . $app[AppUpdater::INDEX_VERSION] . ")";
        } 
        else
        {
        	$title= $app[AppUpdater::INDEX_VERSION];
        }
		$app_size='';
		if ($app[AppUpdater::INDEX_APPSIZE])
        {
            $app_size="<b>" . $size . "</b> " . round($app[AppUpdater::INDEX_APPSIZE] / 1024 / 1024, 1) . " MB<br/>";
        }
        $mob_prof='';
        if (isset($app[AppUpdater::INDEX_PROFILE]) && $app[AppUpdater::INDEX_PROFILE])
        {
        	$button_title='';
        	if (DeviceDetector::$isiPad4Device) 
        	{
        		$button_title=$install_prof;
        	}
        	else 
        	{
        		$button_title=$download_prof;
        	}
			$mob_prof='<a class="button" href="'.$b.'api/2/apps/'.$app[AppUpdater::INDEX_DIR].'?format=mobileprovision">'.$button_title.'</a>';
		}
		$install_platform='';
		$download_platform='';
		$span='span-8';
		$button_class='desktopbuttons';
        if (DeviceDetector::$isiPad4Device) 
        {
        	$span='span-6';
        	$button_class='ipadbuttons';
        	$install_platform='<a class="button" href="itms-services://?action=download-manifest&amp;url='.urlencode($b.'api/2/apps/'.$app[AppUpdater::INDEX_DIR].'?format=plist').'">'.$install_app.'</a>';
        }
		else 
		{
			if ($app[AppUpdater::INDEX_PLATFORM] == AppUpdater::APP_PLATFORM_IOS)
	        {
				$download_platform='<a class="button" href="'.$b.$app['path'].'">'.$download_app.'</a>'; 
			}
			elseif ($app[AppUpdater::INDEX_PLATFORM] == AppUpdater::APP_PLATFORM_ANDROID)
			{
				$download_platform='<a class="button" href="'.$b.$app['path'].'">'.$download_app.'</a>'; 
			}
		}
		$notes='';
		if ($app[AppUpdater::INDEX_NOTES])
		{
        	$notes=	'<p><br><br></p>'.
        			'<p><b>'.$whats_new.'</b><br>'.
        				$app[AppUpdater::INDEX_NOTES].
        			'</p>';
		}
		//The Info div
        $content = 	'<div class="column '.$span.'">';
        $content.= 		'<h2>'.$app[AppUpdater::INDEX_APP].'</h2>';
        $content.= 		'<p><b>'.$version.'</b>';
        $content.=		$title;
        $content.=		"<br/>";
        $content.=		$app_size;
        $content.=		"<b>" . $released . "</b> " . date($date_string, $app[AppUpdater::INDEX_DATE]);
		$content.=		'</p>';
        $content.=		'<div class="'.$button_class.'">';
        $content.=			$mob_prof;
        $content.=			$install_platform;
        $content.=			$download_platform;
        $content.=		'</div>';
		$content.=		$notes;
    	$content.=	'</div>';
		return $content;
	}
	//Android and iPhone/iPod Touch
	public function getSmallScreenIconView($app, $b) 
	{
		//The icon div
		$content =	'<div class="column span-4">';
		$content.= 		'<a href="#'.$app[AppUpdater::INDEX_APP].'">';
		$content.=			$this->getImageView($app, $b);
		$content.= 			'<h4>'.$app[AppUpdater::INDEX_APP].'</h4>';
		$content.=		'</a>';
        $content.= 	'</div>';
		return $content;
	}
	//Desktop and iPad
	public function getIconView($app, $b) 
	{
		//The icon div
		$content =	'<div class="column span-3">';
		$content.=		$this->getImageView($app, $b);
        $content.= 	'</div>';
		return $content;
	}
	//Checks and gets the image
	static function getImageView($app, $b)
	{
		$img = '';		
		if ($app[AppUpdater::INDEX_IMAGE])
        {
			$img= '<img class="icon" src="'.$b.$app[AppUpdater::INDEX_IMAGE].'">'; 		 
		}
		return $img;
	}

}
?>