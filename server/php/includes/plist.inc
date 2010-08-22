<?php
	## Code provided by http://blog.iconara.net/2007/05/08/php-plist-parsing/

    ## Defines only available in PHP 5, created for PHP4
    if(!defined('PHP_URL_SCHEME')) define('PHP_URL_SCHEME', 1);
    if(!defined('PHP_URL_HOST')) define('PHP_URL_HOST', 2);
    if(!defined('PHP_URL_PORT')) define('PHP_URL_PORT', 3);
    if(!defined('PHP_URL_USER')) define('PHP_URL_USER', 4);
    if(!defined('PHP_URL_PASS')) define('PHP_URL_PASS', 5);
    if(!defined('PHP_URL_PATH')) define('PHP_URL_PATH', 6);
    if(!defined('PHP_URL_QUERY')) define('PHP_URL_QUERY', 7);                        
    if(!defined('PHP_URL_FRAGMENT')) define('PHP_URL_FRAGMENT', 8);    
    
    function parse_url_compat($url, $component=NULL){
        
        if(!$component) return parse_url($url);
        
        ## PHP 5
        if(phpversion() >= 5)
            return parse_url($url, $component);

        ## PHP 4
        $bits = parse_url($url);
        
        switch($component){
            case PHP_URL_SCHEME: return $bits['scheme'];
            case PHP_URL_HOST: return $bits['host'];
            case PHP_URL_PORT: return $bits['port'];
            case PHP_URL_USER: return $bits['user'];
            case PHP_URL_PASS: return $bits['pass'];
            case PHP_URL_PATH: return $bits['path'];
            case PHP_URL_QUERY: return $bits['query'];
            case PHP_URL_FRAGMENT: return $bits['fragment'];
        }
        
    }
    
    function parseValue( $valueNode ) {
        $valueType = $valueNode->nodeName;

        $transformerName = "parse_$valueType";

  		if ( is_callable($transformerName) ) {
    		// there is a transformer function for this node type
    		return call_user_func($transformerName, $valueNode);
  		}

  		// if no transformer was found
  		return null;
	}

	function parse_integer( $integerNode ) {
  		return $integerNode->textContent;
	}

	function parse_string( $stringNode ) {
  		return $stringNode->textContent;  
	}

	function parse_date( $dateNode ) {
  		return $dateNode->textContent;
	}

	function parse_true( $trueNode ) {
  		return true;
	}

	function parse_false( $trueNode ) {
  		return false;
	}

	function parse_dict( $dictNode ) {
  		$dict = array();

  		// for each child of this node
  		for (
    		$node = $dictNode->firstChild;
    		$node != null;
    		$node = $node->nextSibling
  			) {
    			if ( $node->nodeName == "key" ) {
      				$key = $node->textContent;

      				$valueNode = $node->nextSibling;

      				// skip text nodes
      				while ( $valueNode->nodeType == XML_TEXT_NODE ) {
        				$valueNode = $valueNode->nextSibling;
      				}

      				// recursively parse the children
      				$value = parseValue($valueNode);

      				$dict[$key] = $value;
    			}
  		}

 		return $dict;
	}

	function parse_array( $arrayNode ) {
  		$array = array();

  		for (
    		$node = $arrayNode->firstChild;
    		$node != null;
    		$node = $node->nextSibling
  			) {
    			if ( $node->nodeType == XML_ELEMENT_NODE ) {
      				array_push($array, parseValue($node));
    			}
  		}

  		return $array;
	}

	function parsePlist( $document ) {
  		$plistNode = $document->documentElement;

  		$root = $plistNode->firstChild;

  		// skip any text nodes before the first value node
  		while ( $root->nodeName == "#text" ) {
    		$root = $root->nextSibling;
  		}

  		return parseValue($root);
	}

?>