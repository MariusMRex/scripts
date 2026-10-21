<?php
include_once("defines.php");
include_once("validation_format.php");

$DBNAME_UNIVERSITY = 'east_university';
$DBNAME_REGNUM = 'east_regnum';
$DBNAME_ORDER = 'east_order';
$DBNAME_OP = 'east_op_test';
$DBNAME_SPIKE = 'east_spike';
$DBNAME_BRANCH = 'east_branch';
$DBNAME_AUTH = 'east_auth';
$DBNAME = $DBNAME_REGNUM;

/**
 * Change these for your own configuration
 */
$DBUSER = 'chirurgeon_ek';
$DBPASS = '35MHYUMyCfj4EBzE';

# We only have one User, so
# I guess I am adding the same 
# credentuals twice - Marius 2012-02-08
$DBUSER_ADMIN = 'chirurgeon_ek';
$DBPASS_ADMIN = '35MHYUMyCfj4EBzE';

/**
 * Connect to DB as read-only user
 */
function db_connect()
{
   global $DBHOST, $DBNAME, $DBUSER, $DBPASS;

   /* Connecting, selecting database */
   $link = mysql_connect($DBHOST, $DBUSER, $DBPASS)
      or die("Could not connect: " . mysql_error());
   mysql_select_db($DBNAME) 
      or die("Could not select database");
   return $link;
}

/**
 * Connect as admin user
 */
function admin_db_connect()
{
   global $DBHOST, $DBNAME, $DBUSER_ADMIN, $DBPASS_ADMIN;

   /* Connecting, selecting database */
   $link = mysql_connect($DBHOST, $DBUSER_ADMIN, $DBPASS_ADMIN)
      or die("Could not connect: " . mysql_error());
   mysql_select_db($DBNAME) 
      or die("Could not select database");
   return $link;
}

/**
 * Disconnect from the database
 */
function db_disconnect($link)
{
   mysql_close($link);
}

/**
 * List the branches
 */
function list_branches($gname)
{
   global $DBNAME_BRANCH;

   $select = "SELECT branch, branch_type, incipient " .
             "FROM $DBNAME_BRANCH.current_eastern_branch JOIN $DBNAME_BRANCH.branch_type ON current_eastern_branch.branch_type_id = branch_type.branch_type_id " .
             "ORDER BY branch";
   $query = mysql_query($select) or die ("Query Error 1 ($select).  Please notify webminister@eastkingdom.org with this error");

   while ($row = mysql_fetch_array($query, MYSQL_ASSOC))
   {
      $name = stripslashes($row["branch"]);
      $type = stripslashes($row["branch_type"]);
      $incipient = $row["incipient"];
      $insp = "";
      if ($incipient == 1)
      {
         $insp = "Incipient ";
      }
      $group_display = "$name, $insp$type of";
      $selected = "";
      if ($gname == $name)
      {
         $selected = " selected";
      }

      echo "<option value=\"$name\"$selected>" . htmlspecialchars($group_display). "</option>\n";
   }
   return;
}

/**
 * List the events in the date range specified
 */
function list_events($e_id, $start_range, $end_range, $external)
{
   global $DBNAME_SPIKE;

   $query = "SELECT event_id, name, gname, start_date, end_date, city, state FROM $DBNAME_SPIKE.event_main " . 
            "WHERE start_date >= " . value_or_null($start_range) . " and start_date <= " . value_or_null($end_range) . " AND publish = 1 AND cancel != 1 ";
   if ($external == 0)
   {
      $query .= "AND external = 0 ";
   }
   $query .= "ORDER BY start_date";
   $result = mysql_query($query) or die ("Query Error ($query).  Please notify webminister@eastkingdom.org with this error.");
   while ($data = mysql_fetch_array($result, MYSQL_BOTH))
   {
      $event_id = clean($data['event_id']);
      $event_name = clean($data['name']);
      $host_group = clean($data['gname']);
      $start_date = clean($data['start_date']);
      $end_date = clean($data['end_date']);
      $city = clean($data['city']);
      $state = clean($data['state']);

      $date_display = "";
      // Single-day event
      if ($start_date == $end_date)
      {
         $date_display = format_short_date($start_date);
      }
      // Multi-day event
      else
      {
         $sdate = strtotime($start_date);
         $edate = strtotime($end_date);
         // Same month
         if (date("n", $sdate) == date("n", $edate))
         {
            $date_display = date("n/j", $sdate) . "-" . date("j/Y", $edate);
         }
         // Different month
         else
         {
            $date_display = date("n/j/Y", $sdate) . "-" . date("n/j/Y", $edate);
         }
      }
      $event_display = "$date_display - $event_name ($host_group)";
      $selected = "";
      if ($event_id == $e_id)
      {
         $selected = " selected";
      }

      echo "<option value=\"$event_id\"$selected>" . htmlspecialchars($event_display) . "</option>\n";
   }
   mysql_free_result($result);
   return;
}

/**
* Quote a variable to make it safe for SQL
*/
function quote_smart($value)
{
   // Stripslashes if we need to
   if (get_magic_quotes_gpc()) 
   {
      $value = stripslashes($value);
   }

   // Quote it if it's not a number
   if (!is_numeric($value)) 
   {
      $value = "'" . mysql_real_escape_string(trim($value)) . "'";
   }

   return $value;
}

/**
* Quote a variable to make it right for CSV load
*/
function csv_quote($value)
{
   // Stripslashes if we need to
   if (get_magic_quotes_gpc()) 
   {
      $value = stripslashes($value);
   }

   // Double quote it if it's not a number
   if (!is_numeric($value)) 
   {
      $value = "\"" . str_replace('"', '""', $value) . "\"";
   }

   return $value;
}

function format_mysql_date($date_field)
{
   return date("Y-m-d", strtotime($date_field));
}

/**
 * Converts the array data into a comma separated list suitable for an SQL IN clause
 */
function create_in_clause_from_array($arr)
{
   $in_clause = "";
   for ($i = 0; $i < count($arr); $i++)
   {
      if (strlen($in_clause) > 0)
      {
         $in_clause .= ",";
      }
      $in_clause .= $arr[$i];
   }
   return $in_clause;
}

function generate_password($uname)
{
   srand((double)microtime()*1000000);
   $ran = rand(0,1000000);
   $npasswd = "$ran$uname";
   $passwd = substr(md5($npasswd),0, 16);
   return $passwd;
}

/**
 * Function: display_officer
 */
function display_chirurgeon()
{
   global $DBNAME_REGNUM;

   $link = db_connect();
   $office = 'Chirurgeon';

   $query = "select * from $DBNAME_REGNUM.goofs where office = '$office' and deputy = 0";
   $result = mysql_query($query) or die("Failed");
   $data = mysql_fetch_array($result, MYSQL_ASSOC);

   $title = stripslashes($data['title']);

   if (isset($data['term_end_date']))
   {
      $term_end_date = stripslashes($data['term_end_date']);
      $title .= " (" . date("m/y", strtotime($term_end_date)) . ")";
   }
   #display information
   echo '<b>'. $title .'</b><br/>';
   echo display_person($data);

   mysql_free_result($result);
   db_disconnect($link);
   return;
}

/**
 * Function: display_officer
 */
function display_chirurgeon_name()
{
   global $DBNAME_REGNUM;

   $link = db_connect();
   $office = 'Chirurgeon';

   $query = "select honorific, sname from $DBNAME_REGNUM.goofs where office = '$office' and deputy = 0";
   $result = mysql_query($query) or die("Failed");
   $data = mysql_fetch_array($result, MYSQL_ASSOC);

   $honorific = stripslashes($data['honorific']);
   $sname = stripslashes($data['sname']);

   #display information
   echo $honorific . ' ' . $sname;

   mysql_free_result($result);
   db_disconnect($link);
   return;
}

/**
 * Function: display_deputy
 */
function display_deputy()
{
   global $DBNAME_REGNUM;

   $link = db_connect();
   $office = 'Chirurgeon';

   #Deputies are always blockquoted (Depth = 1)
   echo '<blockquote>';

   $query = "select * from $DBNAME_REGNUM.goofs where office = '$office' and deputy = 1 and parent = '$office' order by disp_order";
   $result = mysql_query($query) or die ("Failed");
   $count = mysql_num_rows($result);

   for ($a = 0; $a < $count; $a++)
   {
      $data = mysql_fetch_array($result, MYSQL_ASSOC);
      $parent = stripslashes($data['parent']);
      $child = stripslashes($data['child']);
      $title = stripslashes($data['title']);
      $vacant = $data['vacant'];

      #Begin Display
      if ($vacant == 1)
      {
         echo '<b>'. $title .'</b><br/>';
         echo '<i>Vacant</i>';
         echo '<p />';
      }
      else
      {
         if (isset($data['term_end_date']))
         {
            $term_end_date = stripslashes($data['term_end_date']);
            $title .= " (" . date("m/y", strtotime($term_end_date)) . ")";
         }
         #Display Deputies
         echo '<b>'. $title .'</b><br/>';
         echo display_person($data);
         echo '<p />';

         #Check for Sub-Deputies
         if ($child !='')
         {
            display_child($office,$parent,$child);
         }
      }
   }

   #close blockquites
   echo '</blockquote>';
   mysql_free_result($result);
   mysql_close($link);
   return;
}

/**
 * Function: display_child
 */
function display_child($office,$parent,$child)
{
   global $DBNAME_REGNUM;

   $child = "select * from $DBNAME_REGNUM.goofs where office = '$office' and parent = '$child'";
   $result = mysql_query($child);
   $num = mysql_num_rows($result);

   echo '<blockquote>';

   for ($a = 0; $a < $num; $a++)
   {
      $data = mysql_fetch_array($result, MYSQL_ASSOC);
      $parent = stripslashes($data['parent']);
      $child = stripslashes($data['child']);
      $title = stripslashes($data['title']);
      $vacant = $data['vacant'];

      if ($vacant == 1)
      {
         echo '<b>'. $title .'</b><br/>';
         echo '<i>Vacant</i><br/>';
         echo '<p />';
      }
      else
      {
         if (isset($data['term_end_date']))
         {
            $term_end_date = stripslashes($data['term_end_date']);
            $title .= " (" . date("m/y", strtotime($term_end_date)) . ")";
         }
         #Display Deputies
         echo '<b>'. $title .'</b><br/>';
         echo display_person($data);
         echo '<p />';

         #Check for Additional Deputies
         if ($child != '')
         {
            display_child($office,$parent,$child);
         }
      }
   }
   echo '</blockquote>';
   return;
}

/**
 * Function: display_person
 */
function display_person($data)
{
   $honorific = stripslashes($data['honorific']);
   $sname = stripslashes($data['sname']);
   $mname = stripslashes($data['mname']);
   $addr = stripslashes($data['addr']);
   $city = stripslashes($data['city']);
   $state = stripslashes($data['state']);
   $zip = $data['zip'];
   $phone = $data['phone'];
   $nlt = $data['nlt'];
   $email = stripslashes($data['email']);
   $website = stripslashes($data['website']);
   $mpriv = $data['mpriv'];
   $apriv = $data['apriv'];
   $ppriv = $data['ppriv'];
   $epriv = $data['epriv'];
   $term_end_date = '';

   $disp_name = '';
   #Handle Null Values in Names
   if ($sname != '')
   {
      $disp_name = $sname;
      if ($honorific != '')
      {
         $disp_name = "$honorific $sname";
      }
   }
   if (($mpriv == 0) && ($mname != ''))
   {
      $disp_name .= " ($mname)";
   }
   if ($disp_name != '')
   {
      $disp_name .= "<br />";
   }

   $disp_addr = '';
   if ($apriv != 1)
   {
      $disp_addr = $addr .', '. $city .', '. $state .' '. $zip .'<br />';
   }

   $disp_phone = '';
   if ($ppriv != 1)
   {
      if ($nlt != '')
      {
         $disp_phone = 'Phone:  '. $phone .' ('. $nlt .')<br />';
      }
      else
      {
         $disp_phone = 'Phone:  '.$phone .'<br />';
      }
   }

   $disp_email = '';
   if ($epriv != 1)
   {
      $disp_email = priv_email($email);
   }

   $disp_web = '';
   if ($website != '')
   {
      $disp_web = "Web Site: " . display_url($website) . "<br />";
   }

   echo $disp_name . $disp_addr . $disp_phone . $disp_email . $disp_web;
   return;
}

/**
 * Function: display_email
 */
function display_email($email)
{
   global $HOME_DIR;
   $edata = explode("@",$email);
   $user = $edata[0];
   $domain = $edata[1];

   $disp_email = '<a href="' . $HOME_DIR . 'functions/mailto.php?u='.$user .'&amp;d='. $domain .'" target="redir">'. $user .' AT '. $domain .'</a>';
   return($disp_email);
}

/**
 * Function: priv_email
 */
function priv_email($email)
{
   $disp_email = 'Email:  ' . display_email($email) . '<br/>';
   return($disp_email);
}

/**
 * Function: display_url
 */
function display_url($url)
{
   $disp_url = '<a href="' . $url . '">'. $url .'</a>';
   return($disp_url);
}

/**
 * Returns the name of the Kingdom where of the given group is located
 * YOU MUST ALREADY HAVE A DATABASE CONNECTION BEFORE USING THIS METHOD
 * @param regional_group_id The ID of the regional group for which to get the kingdom name
 * @return String The name of the kingdom
 */
function get_kingdom($regional_group_id)
{
   global $GT_KINGDOM;
   $kingdom = "";

   if (trim($regional_group_id) != "")
   {
      /* Performing SQL query */
      $query = 'SELECT regional_group_id, regional_group, group_type_id, parent_group_id FROM regional_group WHERE regional_group_id = ';

      $result = mysql_query($query . $regional_group_id) 
         or die("Kingdom Query failed : " . mysql_error());

      $data = mysql_fetch_array($result, MYSQL_BOTH);
      $group_type_id = trim($data['group_type_id']);
      $regional_group_id = trim($data['parent_group_id']);
      $kingdom = clean($data['regional_group']);
      while ($group_type_id != $GT_KINGDOM)
      {
         $result = mysql_query($query . $regional_group_id) 
            or die("Kingdom Query failed : " . mysql_error());

         $data = mysql_fetch_array($result, MYSQL_BOTH);
         $group_type_id = trim($data['group_type_id']);
         $regional_group_id = trim($data['parent_group_id']);
         $kingdom = clean($data['regional_group']);
      }
   }

   return $kingdom;
}

/**
 * Returns the name of the group where of the given ID
 * YOU MUST ALREADY HAVE A DATABASE CONNECTION BEFORE USING THIS METHOD
 * @param regional_group_id The ID of the regional group for which to get the group name
 * @return String The name of the group
 */
function get_regional_group_name($regional_group_id)
{
   global $GT_KINGDOM;
   $group_name = "";

   if (trim($regional_group_id) != "")
   {
      /* Performing SQL query */
      $query = 'SELECT regional_group_id, regional_group, group_type_id, parent_group_id FROM regional_group WHERE regional_group_id = ';

      $result = mysql_query($query . $regional_group_id) 
         or die("Regional Group Query failed : " . mysql_error());

      $data = mysql_fetch_array($result, MYSQL_BOTH);
      $group_type_id = trim($data['group_type_id']);
      $regional_group_id = trim($data['parent_group_id']);
      $group_name = clean($data['regional_group']);
   }

   return $group_name;
}

function get_webminister_display($db_link)
{
   $retval = 'Web Minister (cassandra AT jordanclan.net)';
   return $retval;
}

/**
 * Get the preferred SCA name (from Unified)
 * @param eastern_id The Eastern ID of the individual
 * @param sca_name The official SCA Name of the individual
 * @return String the preferred SCA name
 */
function get_preferred_sca_name($eastern_id, $sca_name)
{
   /* Connecting, selecting database */
   $link = unified_db_connect();

   $preferred_name = "";
   /* Performing SQL query */
   $query = 
      'SELECT eastern.preferred_sca_name '.
      'FROM eastern '.
      'WHERE eastern.eastern_id = ' . $eastern_id;

   $result = mysql_query($query) 
      or die("Preferred SCA Name Query failed : " . mysql_error());

   $data = mysql_fetch_array($result, MYSQL_BOTH);
   $preferred_name = clean($data['preferred_sca_name']);
   if ($preferred_name != "" && $preferred_name != $sca_name)
   {
      $preferred_name = " [" . $preferred_name . "]";
   }
   else
   {
      $preferred_name = "";
   }

   /* Free resultset */
   mysql_free_result($result);

   /* Closing connection */
   db_disconnect($link);

   return $preferred_name;
}
?>
