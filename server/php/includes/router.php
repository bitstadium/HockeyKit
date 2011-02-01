<?php

/**
* Simple router
*/
class Router
{
	static $routes = array(
		'/' => '/index',
		'/app/:bundleidentifier@[\w-.]+' => '/app',
		'/api/ios/status/:bundleidentifier@[\w-.]+' => 'ios/status',
		'/api/ios/download/:type@(profile|plist|app)/:bundleidentifier@[\w-.]+' => 'ios/download',
		'/api/android/status/:bundleidentifier@[\w-.]+' => 'android/status',
		'/api/android/download/:type@app/:bundleidentifier@[\w-.]+' => 'android/download',
	);

	static protected $instance;
	
	// there can only be one
	static public function get() {
		
		if (!self::$instance) {
			$class = __CLASS__;
			self::$instance = new $class();
			self::$instance->init();
		}
		
		return self::$instance;
	}
	
	public $controller;
	public $action;
	public $arguments;
	
	protected function init() {
		// $url = "http://".$_SERVER['SERVER_NAME'].$_SERVER['REQUEST_URI'];
		// $this->baseURL = substr($url, 0, strrpos($url, "/") + 1);
		$this->baseURL = '/';

		$url = $_SERVER['REQUEST_URI'];
        // Logger::log("URL:\t$url");

		foreach (self::$routes as $route => $info) {
			if (self::match($url, $route, $info))
			{
				return $this->run();
			}
		}
		
		$this->serve404();
	}
	
	public function match($url, $route, $info)
	{
        // Logger::log("Route:\t$route");
		list($controller, $action) = explode('/', $info);
		
		$url_exploded = explode('/', $url);
		$route_exploded = explode('/', $route);

		if (count($url_exploded) != count($route_exploded))
		{
            // Logger::log('!!! Length does not match');
			return false;
		}
		
		$arguments = array();
		
		$count = count($url_exploded);
		$i = 0;
		$is_matching = true;
		
		while ($is_matching && $i < $count)
		{
			$url_part   = $url_exploded[$i];
			$route_part = $route_exploded[$i];
			
			// special route part?
			if (strpos($route_part, ':') === 0)
			{
				// argument
				if (!preg_match('/:([\w_]+)(@(.*))?/', $route_part, $matches))
				{
                    // Logger::log("!!! Argument $route_part does not match");
					return false;
				}
				
				$argument = $matches[1];
				$value = $url_part;
				
				if (!isset($matches[3]) || !preg_match("/{$matches[3]}/u", $value))
				{
                    // Logger::log("!!! Argument {$matches[1]} = $value does not match");
					return false;
				}
				
				$arguments[$argument] = $value;
			}
			elseif ($url_part != $route_part)
			{
                // Logger::log("!!! $url_part does not match $route_part");
				return false;
			}
			
			$i++;
		}
		
        // Logger::log("*** Match $controller/$action");

		$this->controller = $controller;
		$this->action     = $action;
		$this->arguments  = $arguments;
		
		return true;
	}
	
	protected function run()
	{
		$this->app = AppUpdater::factory($this->controller);
		$this->app->execute($this->action, $this->arguments);
	}
	
	public function serve404()
	{
		ob_end_clean();
		header('HTTP/1.1 404 Not Found');
		exit('404');
	}
}

?>