<?php

	## Code provided by http://www.mike-griffiths.co.uk/php-json_encode-alternative/

if (!function_exists('json_encode'))
{
	function json_encode($a=false)
	{
		// Some basic debugging to ensure we have something returned
		if (is_null($a)) return 'null';
		if ($a === false) return 'false';
		if ($a === true) return 'true';
		if (is_scalar($a))
		{
			if (is_float($a))
			{
				// Always use "." for floats.
				return floatval(str_replace(",", ".", strval($a)));
			}

			if (is_string($a))
			{
				static $jsonReplaces = array(array("\\", "/", "\n", "\t", "\r", "\b", "\f", '"'), array('\\\\', '\\/', '\\n', '\\t', '\\r', '\\b', '\\f', '\"'));
				return '"' . str_replace($jsonReplaces[0], $jsonReplaces[1], $a) . '"';
			}
			else
				return $a;
		}
		$isList = true;
		for ($i = 0; reset($a); $i) {
			if (key($a) !== $i)
			{
				$isList = false;
				break;
			}
		}
		$result = array();
		if ($isList)
		{
			foreach ($a as $v) $result[] = json_encode($v);
			return '[' . join(',', $result) . ']';
		}
		else
		{
			foreach ($a as $k => $v) $result[] = json_encode($k).':'.json_encode($v);
			return '{' . join(',', $result) . '}';
		}
	}
}

	## Code provided by http://www.php.net/manual/en/function.json-decode.php#100740
	
if (!function_exists('json_decode'))
{
	function json_decode($json)
	{
    	$comment = false;
    	$out = '$x=';
  
    	for ($i=0; $i<strlen($json); $i++)
    	{
        	if (!$comment)
        	{
            	if (($json[$i] == '{') || ($json[$i] == '['))       $out .= ' array(';
            	else if (($json[$i] == '}') || ($json[$i] == ']'))   $out .= ')';
            	else if ($json[$i] == ':')    $out .= '=>';
            	else                         $out .= $json[$i];          
        	}
        	else $out .= $json[$i];
        	if ($json[$i] == '"' && $json[($i-1)]!="\\")    $comment = !$comment;
    	}
    	eval($out . ';');
    	return $x;
	}
}

?>