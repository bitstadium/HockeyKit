<?php

/**
* Simple router
*/
class Router
{
    static $routes = array(
        '/' => '/index',
        '/apps' => '/index',
        '/apps/' => '/index',
        '/apps/:bundleidentifier@^[\w-.]+$' => '/app',
        '/api/2/apps/:bundleidentifier@^[\w-.]+$' => '/api'
    );

    static protected $instance;
    
    // there can only be one
    static public function get($options = null) {
        
        if (!self::$instance) {
            $class = __CLASS__;
            self::$instance = new $class();
            self::$instance->init($options);
        }
        
        return self::$instance;
    }
    
    static public function arg($name, $default = null) {
        $instance = self::get();
        if (!isset($instance->args[$name]))
        {
            Logger::log("arg `$name` not set", true);
            return $default;
        }
        return $instance->args[$name];
    }
    
    static public function arg_variants($names, $default = null) {
        $instance = self::get();
        
        foreach ($names as $name) {
            if (isset($instance->args[$name]))
            {
                return $instance->args[$name];
            }
        }
        Logger::log('args `'.join('`, `', $names).'` not set', true);
        return $default;
    }
    
    static public function arg_match($name, $regexp, $default = null) {
        $instance = self::get();
        if (!isset($instance->args[$name]))
        {
            Logger::log("arg `$name` not set", true);
            return $default;
        }
        
        $value = $instance->args[$name];
        if (!preg_match($regexp, $value))
        {
            return $default;
        }
        
        return $value;
    }
    
    
    public $controller;
    public $action;
    public $arguments;
    public $api;
    public $servername;
    public $args          = array();
    protected $args_get   = array();
    protected $args_post  = array();
    protected $args_files = array();
    
    protected function init($options) {

        $path = dirname($_SERVER['SCRIPT_NAME']);

	    /* Check if HockeyKit is running on a Windows server, if so: update the path variable to let it parse correctly. */
        if( PHP_OS == "WIN32" || PHP_OS == "WINNT" )
		    $path = str_replace("\\", "/", $path);

        if ($path == '/') $path = '';

        $request = substr($_SERVER['REQUEST_URI'], strlen($path));
        Logger::log($request);

        if ($pos = strpos($request, '?')) {
            $request = substr($request, 0, $pos);
        }
        
        $this->collect_arguments();
        
        $protocol = 'http';
        $default_port = 80;
        if (isset($_SERVER['HTTPS']) && strtolower($_SERVER['HTTPS']) == 'on')
        {
            $protocol = 'https';
            $default_port = 443;
        }
        if (defined('BASE_URL') && BASE_URL !== NULL) {
        	$this->baseURL =  BASE_URL;
        } else {         
		$this->baseURL = sprintf(
			'%s://%s%s%s/',
			$protocol,
			$_SERVER['SERVER_NAME'],
			$_SERVER['SERVER_PORT'] != $default_port ? ':'.$_SERVER['SERVER_PORT'] : '',
			$path
			);
        }
        
        $this->servername =  $_SERVER['SERVER_NAME'];

        $is_v1_client = strpos($_SERVER['HTTP_USER_AGENT'], 'CFNetwork') !== false;

        $this->api = (strpos($request, '/api/') === false && strpos($request, '/apps/') === false) || $is_v1_client ?
            AppUpdater::API_V1 : AppUpdater::API_V2;

        if ($this->api == AppUpdater::API_V1)
        {
            return $this->routeV1($options, $is_v1_client);
        }

        // find matching route
        foreach (self::$routes as $route => $info) {
            if (self::match($request, $route, $info))
            {
                return $this->run($options);
            }
        }
        
        // fallback: 404
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
    
    protected function collect_arguments()
    {
        foreach ($_GET as $key => $value) {
            $this->args[$key] = $value;
            $this->args_get[$key] = $value;
            unset($_GET[$key]);
        }
        foreach ($_POST as $key => $value) {
            $this->args[$key] = $value;
            $this->args_post[$key] = $value;
            unset($_POST[$key]);
        }
    }
    
    protected function run($options)
    {
        if ($this->action != "api") {
            $this->app = AppUpdater::factory($this->controller, $options);
            $this->app->execute($this->action, array_merge($this->arguments, $this->args));
            return;
        }


        $format = self::arg_match(AppUpdater::PARAM_2_FORMAT, '/^(' . AppUpdater::PARAM_2_FORMAT_VALUE_JSON . '|' . AppUpdater::PARAM_2_FORMAT_VALUE_MOBILEPROVISION . '|' . AppUpdater::PARAM_2_FORMAT_VALUE_PLIST . '|' . AppUpdater::PARAM_2_FORMAT_VALUE_IPA . '|' . AppUpdater::PARAM_2_FORMAT_VALUE_APK . ')$/');
        $authorize = self::arg_match(AppUpdater::PARAM_2_AUTHORIZE, '/^(' . AppUpdater::PARAM_2_AUTHORIZE_VALUE_YES . '|' . AppUpdater::PARAM_2_AUTHORIZE_VALUE_NO . ')$/');
            
        if (!$format) {
            $this->app = AppUpdater::factory(null, $options);
            $this->app->execute($this->action, array_merge($this->arguments, $this->args));
            return;
        }

        switch ($format) {
            case AppUpdater::PARAM_2_FORMAT_VALUE_JSON: 
                if (strpos($_SERVER['HTTP_USER_AGENT'], 'Hockey/Android') !== false)
                    $this->controller = AppUpdater::PLATFORM_ANDROID;
                else
                    $this->controller = AppUpdater::PLATFORM_IOS;
                            
                if ($this->controller == AppUpdater::PLATFORM_IOS && $authorize && $authorize == AppUpdater::PARAM_2_AUTHORIZE_VALUE_YES) {
                    $this->action = "authorize";
                } else {
                    $this->action = "status";
                }
                break;
            case AppUpdater::PARAM_2_FORMAT_VALUE_MOBILEPROVISION: 
                $this->controller = AppUpdater::PLATFORM_IOS;
                $this->action = "download";
                break;
            case AppUpdater::PARAM_2_FORMAT_VALUE_PLIST: 
                $this->controller = AppUpdater::PLATFORM_IOS;
                $this->action = "download";
                break;
            case AppUpdater::PARAM_2_FORMAT_VALUE_IPA: 
                $this->controller = AppUpdater::PLATFORM_IOS;
                $this->action = "download";
                break;
            case AppUpdater::PARAM_2_FORMAT_VALUE_APK: 
                $this->controller = AppUpdater::PLATFORM_ANDROID;
                $this->action = "download";
                break;
            default: break;
        }
        $this->app = AppUpdater::factory($this->controller, $options);
        $this->app->execute($this->action, array_merge($this->arguments, $this->args));
    }
    
    protected function routeV1($options, $is_client = false)
    {
        $bundleidentifier = self::arg_match(AppUpdater::PARAM_1_IDENTIFIER, '/^[\w-.]+$/');
        $type             = self::arg_match(AppUpdater::PARAM_1_TYPE, '/^(' . AppUpdater::PARAM_1_TYPE_VALUE_IPA . '|' . AppUpdater::PARAM_1_TYPE_VALUE_APP . '|' .AppUpdater::PARAM_1_TYPE_VALUE_PROFILE . ')$/');

        if ($bundleidentifier && ($type || $is_client))
        {
            switch ($type) {
                case AppUpdater::PARAM_1_TYPE_VALUE_IPA: 
                    $type = AppUpdater::PARAM_2_FORMAT_VALUE_IPA;
                    break;
                case AppUpdater::PARAM_1_TYPE_VALUE_APP: 
                    $type = AppUpdater::PARAM_2_FORMAT_VALUE_PLIST;
                    break;
                case AppUpdater::PARAM_1_TYPE_VALUE_PROFILE: 
                    $type = AppUpdater::PARAM_2_FORMAT_VALUE_MOBILEPROVISION;
                    break;
                default: break;
            }
            
            $this->app = AppUpdater::factory(AppUpdater::PLATFORM_IOS, $options);
            $this->app->deliver($bundleidentifier, AppUpdater::API_V1, $type);
            exit;
        }
        
        $this->app = AppUpdater::factory(null, $options);
        $this->app->show($bundleidentifier);
    }
    
    
    public function serve404()
    {
        @ob_end_clean();
        header('HTTP/1.1 404 Not Found');
        exit('404');
    }
}

?>