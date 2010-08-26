<?php 
  header('Content-type: text/xml');
  header('Cache-Control: no-cache, must-revalidate'); // HTTP/1.1
  header('Expires: Mon, 26 Jul 1997 05:00:00 GMT'); // Date in the past
  echo '<?xml version="1.0" encoding="UTF-8"?' . ">\n";
  echo '<response>';
  $query = $_SERVER['QUERY_STRING'];
  $url = "http://lyberservices-dev.stanford.edu/workflow/workflow_queue?repository=sdr&" . $query;
  #echo $url . "\n";
  $ch = curl_init($url);
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);
  curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, FALSE); 
  curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, FALSE);
  curl_setopt($ch, CURLOPT_SSLCERT, "/var/www/certs/ls-dev.crt");
  curl_setopt($ch, CURLOPT_SSLKEY, "/var/www/certs/ls-dev.key");
  curl_setopt($ch, CURLOPT_SSLKEYPASSWD, "lsdev");
  $data = curl_exec($ch);
#  $info = curl_getinfo($ch);
#  var_export($info);
#  echo "data: " . $data . "\n"; 
  if( preg_match('/^No objects found/', $data) || trim($data) == ''){
    echo "<result>0</result>";
  } else {
    $xml = new DOMDocument;
    $xml->loadXML($data);
    $results = $xml->getElementsByTagName('object');
    if($results->length > 0){
      echo "<result>" . $results->length . "</result>";
    }else{
      echo "<result>0</result>";
    }
  }
  echo '</response>';
?>

