<?php
include_once("functions/defines.php");
include_once("functions/db.php");
include_once("functions/validation_format.php");

$report_type = $RT_QUARTERLY;
if (isset($_REQUEST['report_type']))
{
   $report_type = clean($_REQUEST['report_type']);
}

// Get starting point (today)
$today = date("n/j/Y");
$curr_year = date('Y');

// Determine current quarter
$month = date("m");
$md = date("m-d");

$curr_quarter = 1;
if ($md >= $Q2_START && $md < $Q3_START)
{
   $curr_quarter = 2;
}
else if ($md >= $Q3_START && $md < $Q4_START)
{
   $curr_quarter = 3;
}
else if ($md >= $Q4_START && $md < $Q1_START)
{
   $curr_quarter = 4;
}

$quarter = $curr_quarter;
// Allow submission of current quarter within two weeks centered on quarter end date
$may_submit = false;
if ($md >= $Q1_RANGE_START && $md <= $Q1_RANGE_END)
{
   $quarter = 1;
   if ($report_type == $RT_QUARTERLY)
   {
      $may_submit = true;
   }
}
else if ($md >= $Q2_RANGE_START && $md <= $Q2_RANGE_END)
{
   $quarter = 2;
   if ($report_type == $RT_QUARTERLY)
   {
      $may_submit = true;
   }
}
else if ($md >= $Q3_RANGE_START && $md <= $Q3_RANGE_END)
{
   $quarter = 3;
   if ($report_type == $RT_QUARTERLY)
   {
      $may_submit = true;
   }
}
else if ($md >= $Q4_RANGE_START && $md <= $Q4_RANGE_END)
{
   $quarter = 4;
   $may_submit = true;
}

// Q1 m 12 - year is curr_year for all but Q1 end date, which is curr_year + 1
// Q1 m 1 or 2 - year is curr_year - 1 for all but Q1 end date, which is curr_year
// Q2 - year is curr_year for Q2 and end Q1, curr_year - 1 otherwise
// Q3 - year is curr_year for Q3, Q2 and end Q1, curr_year - 1 otherwise
// Q4 - year is curr_year for Q4, Q3, Q2 and end Q1, curr_year - 1 otherwise
$q1_start_year = $curr_year - 1;
$q1_end_year = $curr_year;
$q2year = $curr_year;
$q3year = $curr_year;
$q4year = $curr_year;

switch ($curr_quarter)
{
   case 1:
      if ($month == 12)
      {
         $q1_start_year = $curr_year;
         $q1_end_year = $curr_year + 1;
      }
      else
      {
         $q2year = $curr_year - 1;
         $q3year = $curr_year - 1;
         $q4year = $curr_year - 1;
      }
      break;
   case 2:
      $q3year = $curr_year - 1;
      $q4year = $curr_year - 1;
      break;
   case 3:
      $q4year = $curr_year - 1;
      break;
   case 4:
      break;
}

// Create date range based on report quarter
switch ($quarter)
{
   case 1:
      $start_range = "$q1_start_year-$Q1_START";
      $end_range = "$q1_end_year-$Q2_START";
      break;
   case 2:
      $start_range = "$q2year-$Q2_START";
      $end_range = "$q2year-$Q3_START";
      break;
   case 3:
      $start_range = "$q3year-$Q3_START";
      $end_range = "$q3year-$Q4_START";
      break;
   case 4:
      $start_range = "$q4year-$Q4_START";
      $end_range = "$q4year-$Q1_START";
      break;
}

// Subtract 1 day from end range for quarter end date
$edate = date_create($end_range);
date_modify($edate, '-1 day');
$q_start_date = format_full_date($start_range);
$q_end_date = format_full_date(date_format($edate, 'Y-m-d'));

$a_start_year = $curr_year - 2;
$a_end_year = $curr_year - 1;
if ($month == 11 || $month == 12)
{
   $a_start_year = $curr_year - 1;
   $a_end_year = $curr_year;
}

$title = "Chirurgeon $report_type Report";
$report_title = $title;
if ($report_type == $RT_QUARTERLY)
{
   $report_title .= " - Quarter " . $quarter . ": " . $q_start_date . " - " . $q_end_date;
}
else
{
   $report_title .= ": December 1, " . $a_start_year . " - November 30, " . $a_end_year;
}

include("header.php");

// Data submitted
$errmsg = "";
if (isset($_POST['submit']))
{
   // Capture form data
   $u_legal_name = "";
   if (isset($_POST['u_legal_name']))
   {
      $u_legal_name = clean($_POST['u_legal_name']);
   }
   $legal_name = "";
   if (isset($_POST['legal_name']))
   {
      $legal_name = clean($_POST['legal_name']);
   }
   $u_sca_name = "";
   if (isset($_POST['u_sca_name']))
   {
      $u_sca_name = clean($_POST['u_sca_name']);
   }
   $sca_name = "";
   if (isset($_POST['sca_name']))
   {
      $sca_name = clean($_POST['sca_name']);
   }
   $u_address = "";
   if (isset($_POST['u_address']))
   {
      $u_address = clean($_POST['u_address']);
   }
   $address1 = "";
   if (isset($_POST['address1']))
   {
      $address1 = clean($_POST['address1']);
   }
   $address2 = "";
   if (isset($_POST['address2']))
   {
      $address2 = clean($_POST['address2']);
   }
   $city = "";
   if (isset($_POST['city']))
   {
      $city = clean($_POST['city']);
   }
   $state = "";
   if (isset($_POST['state']))
   {
      $state = clean($_POST['state']);
   }
   $zip = "";
   if (isset($_POST['zip']))
   {
      $zip = clean($_POST['zip']);
   }
   $u_phone = "";
   if (isset($_POST['u_phone']))
   {
      $u_phone = clean($_POST['u_phone']);
   }
   $phone = "";
   if (isset($_POST['phone']))
   {
      $phone = clean($_POST['phone']);
   }
   $u_mphone = "";
   if (isset($_POST['u_mphone']))
   {
      $u_mphone = clean($_POST['u_mphone']);
   }
   $mphone = "";
   if (isset($_POST['mphone']))
   {
      $mphone = clean($_POST['mphone']);
   }
   $u_email = "";
   if (isset($_POST['u_email']))
   {
      $u_email = clean($_POST['u_email']);
   }
   $email = "";
   if (isset($_POST['email']))
   {
      $email = clean($_POST['email']);
   }
   $u_home_branch = "";
   if (isset($_POST['u_home_branch']))
   {
      $u_home_branch = clean($_POST['u_home_branch']);
   }
   $home_branch = "";
   if (isset($_POST['home_branch']))
   {
      $home_branch = clean($_POST['home_branch']);
   }
   $u_branch_chir = "";
   if (isset($_POST['u_branch_chir']))
   {
      $u_branch_chir = clean($_POST['u_branch_chir']);
   }
   $branch_chir = "";
   if (isset($_POST['branch_chir']))
   {
      $branch_chir = clean($_POST['branch_chir']);
   }
   $chir_branch = "";
   if (isset($_POST['chir_branch']))
   {
      $chir_branch = clean($_POST['chir_branch']);
   }
   $u_membership = "";
   if (isset($_POST['u_membership']))
   {
      $u_membership = clean($_POST['u_membership']);
   }
   $membership_number = "";
   if (isset($_POST['membership_number']))
   {
      $membership_number = clean($_POST['membership_number']);
   }
   $expiration_date = "";
   if (isset($_POST['expiration_date']))
   {
      $expiration_date = clean($_POST['expiration_date']);
   }
   $u_first_aid = "";
   if (isset($_POST['u_first_aid']))
   {
      $u_first_aid = clean($_POST['u_first_aid']);
   }
   $first_aid_date = "";
   if (isset($_POST['first_aid_date']))
   {
      $first_aid_date = clean($_POST['first_aid_date']);
   }
   $first_aid_agency = "";
   if (isset($_POST['first_aid_agency']))
   {
      $first_aid_agency = clean($_POST['first_aid_agency']);
   }
   $first_aid_agency_other = "";
   if (isset($_POST['first_aid_agency_other']))
   {
      $first_aid_agency_other = clean($_POST['first_aid_agency_other']);
   }
   $u_adult_cpr = "";
   if (isset($_POST['u_adult_cpr']))
   {
      $u_adult_cpr = clean($_POST['u_adult_cpr']);
   }
   $adult_cpr_date = "";
   if (isset($_POST['adult_cpr_date']))
   {
      $adult_cpr_date = clean($_POST['adult_cpr_date']);
   }
   $adult_cpr_agency = "";
   if (isset($_POST['adult_cpr_agency']))
   {
      $adult_cpr_agency = clean($_POST['adult_cpr_agency']);
   }
   $adult_cpr_agency_other = "";
   if (isset($_POST['adult_cpr_agency_other']))
   {
      $adult_cpr_agency_other = clean($_POST['adult_cpr_agency_other']);
   }
   $u_child_cpr = "";
   if (isset($_POST['u_child_cpr']))
   {
      $u_child_cpr = clean($_POST['u_child_cpr']);
   }
   $child_cpr_date = "";
   if (isset($_POST['child_cpr_date']))
   {
      $child_cpr_date = clean($_POST['child_cpr_date']);
   }
   $child_cpr_agency = "";
   if (isset($_POST['child_cpr_agency']))
   {
      $child_cpr_agency = clean($_POST['child_cpr_agency']);
   }
   $child_cpr_agency_other = "";
   if (isset($_POST['child_cpr_agency_other']))
   {
      $child_cpr_agency_other = clean($_POST['child_cpr_agency_other']);
   }
   $u_other_certs = "";
   if (isset($_POST['u_other_certs']))
   {
      $u_other_certs = clean($_POST['u_other_certs']);
   }
   $other_certs = "";
   if (isset($_POST['other_certs']))
   {
      $other_certs = clean($_POST['other_certs']);
   }
   $comments = "";
   if (isset($_POST['comments']))
   {
      $comments = clean($_POST['comments']);
   }

   // Validate data
   // Contact information
   if ($legal_name == "")
   {
      $errmsg .= "Please enter your legal name.<br/>";
   }
   if ($sca_name == "")
   {
      $errmsg .= "Please enter your SCA name.<br/>";
   }
   if ($address1 == "" || $city == "" || $state == "" || $zip == "")
   {
      $errmsg .= "Please enter your full address (Line 1, City, State and Zip).<br/>";
   }
   else if (!validate_zip($zip))
   {
      $errmsg .= "Please enter a valid zip code.<br/>";
   }
   if ($phone == "")
   {
      $errmsg .= "Please enter your home phone number.<br/>";
   }
   else if (!validate_phone($phone))
   {
      $errmsg .= "Please enter a valid home phone number.<br/>";
   }
   if ($mphone != "")
   {
      if (!validate_phone($mphone))
      {
         $errmsg .= "Please enter a valid mobile phone number.<br/>";
      }
   }
   if ($email == "")
   {
      $errmsg .= "Please enter your email address.<br/>";
   }
   else if (!validate_email($email))
   {
      $errmsg .= "Please enter a valid email address with one @ and no spaces.<br/>";
   }
   if ($home_branch == "")
   {
      $errmsg .= "Please select your home branch.<br/>";
   }
   if ($branch_chir == 1)
   {
      if ($chir_branch == "")
      {
         $errmsg .= "Please select the branch for you are the group chirurgeon.<br/>";
      }
   }
   if ($membership_number == "")
   {
      $errmsg .= "Please enter your SCA membership number.<br/>";
   }
   else if (!validate_positive_integer($membership_number))
   {
      $errmsg .= "Please enter a valid SCA membership number.<br/>";
   }
   if ($expiration_date == "")
   {
      $errmsg .= "Please enter your SCA membership expiration date.<br/>";
   }
   else if (!validate_date($expiration_date))
   {
      $errmsg .= "Please enter a valid date for your SCA membership expiration date.<br/>";
   }
   else if (!validate_future_date($expiration_date))
   {
      $errmsg .= "Your SCA membership expiration date must be in the future.<br/>";
   }
   // Certification information
   if ($first_aid_date == "")
   {
      $errmsg .= "Please enter your First Aid certification expiration date.<br/>";
   }
   else if (!validate_date($first_aid_date))
   {
      $errmsg .= "Please enter a valid date for your First Aid certification expiration date.<br/>";
   }
   else if (!validate_future_date($first_aid_date))
   {
      $errmsg .= "Your First Aid certification expiration date must be in the future.<br/>";
   }
   if ($first_aid_agency == "Other")
   {
      if ($first_aid_agency_other == "")
      {
         $errmsg .= "Please specify your other First Aid certification agency.<br/>";
      }
   }
   if ($adult_cpr_date == "")
   {
      $errmsg .= "Please enter your Adult CPR certification expiration date.<br/>";
   }
   else if (!validate_date($adult_cpr_date))
   {
      $errmsg .= "Please enter a valid date for your Adult CPR certification expiration date.<br/>";
   }
   else if (!validate_future_date($adult_cpr_date))
   {
      $errmsg .= "Your Adult CPR certification expiration date must be in the future.<br/>";
   }
   if ($adult_cpr_agency == "Other")
   {
      if ($adult_cpr_agency_other == "")
      {
         $errmsg .= "Please specify your other Adult CPR certification agency.<br/>";
      }
   }
   if ($child_cpr_date != "")
   {
      if (!validate_date($child_cpr_date))
      {
         $errmsg .= "Please enter a valid date for your Infant &amp; Child CPR certification expiration date.<br/>";
      }
      else if (!validate_future_date($child_cpr_date))
      {
         $errmsg .= "Your Infant &amp; Child CPR certification expiration date must be in the future.<br/>";
      }
   }
   if ($child_cpr_agency == "Other")
   {
      if ($child_cpr_agency_other == "")
      {
         $errmsg .= "Please specify your other Infant &amp; Child CPR certification agency.<br/>";
      }
   }

   // Activities information
   for ($j = 1; $j <= $MAX_EVENTS; $j++)
   {
      ${"event_id" . $j} = "";
      if (isset($_POST["event_id" . $j]))
      {
         ${"event_id" . $j} = clean($_POST["event_id" . $j]);
      }
      ${"position" . $j} = "";
      if (isset($_POST["position" . $j]))
      {
         ${"position" . $j} = clean($_POST["position" . $j]);
      }
      if (${"event_id" . $j} != "" && ${"position" . $j} == "")
      {
         $errmsg .= "Please select a position for Event " . $j . "<br/>";
      }
      if (${"event_id" . $j} == "" && ${"position" . $j} != "")
      {
         $errmsg .= "Please select an event for position " . $j . "<br/>";
      }
   }

   // If data is valid
   if ($errmsg == "")
   {
      $link = db_connect();

      $headers = "From:  \"$sca_name\" <$email>\n";
      $headers .= "Sender:  <$CHIRURGEON_EMAIL>\n";
      $headers .= "X-Mailer:  PHP/" . phpversion() . "\n";
      $recip = "$CHIRURGEON_EMAIL, $email";
      $subject = $report_title;

      $response_extra = "";

      // Create email message
      $body = "$report_title\n\n";
      // Reminder to send in updated certifications
      if ($u_membership == 1 || $u_first_aid == 1 || $u_adult_cpr == 1 || $u_child_cpr == 1 || $u_other_certs == 1)
      {
         $body .= "Don't forget to send the Kingdom Chirurgeon a scanned copy or photocopy of the updated documents for membership/certification changes.\n\n";
      }
      $body .= "REPORT DATE: " . format_short_date(date("m/d/Y")) . "\n\n";
      $body .= "CONTACT INFORMATION:\n";
      $body .= "LEGAL NAME" . display_updated($u_legal_name) . ": $legal_name\n";
      $body .= "SCA NAME" . display_updated($u_sca_name) . ": $sca_name\n";
      $body .= "ADDRESS" . display_updated($u_address) . ": $address1\n";
      if ($address2 != "")
      {
         $body .= "         $address2\n";
      }
      $body .= "         $city, $state $zip\n";
      $body .= "HOME PHONE" . display_updated($u_phone) . ": " . format_phone($phone) . "\n";
      if ($mphone != "")
      {
         $body .= "MOBILE PHONE" . display_updated($u_mphone) . ": " . format_phone($mphone) . "\n";
      }
      $body .= "EMAIL ADDRESS" . display_updated($u_email) . ": $email\n";
      $body .= "HOME BRANCH" . display_updated($u_home_branch) . ": $home_branch\n";
      if ($branch_chir == 1)
      {
         $body .= "BRANCH CHIRURGEON?" . display_updated($u_branch_chir) . ": Yes - $chir_branch\n";
         // Get the branch seneschal's email address to copy the report
         $query = "SELECT email " . 
                  "FROM $DBNAME_REGNUM.seneschal " . 
                  "WHERE gname = " . quote_smart($chir_branch);
         $result = mysql_query($query) or die ("Query Error ($query).  Please notify webminister@eastkingdom.org with this error.");
         if (mysql_num_rows($result) == 1)
         {
            $data = mysql_fetch_array($result, MYSQL_BOTH);
            $seneschal_email = clean($data['email']);
            $recip .= ", $seneschal_email";
            $response_extra = ", the Seneschal of $chir_branch,";
         }
      }
      else
      {
         $body .= "BRANCH CHIRURGEON" . display_updated($u_branch_chir) . ": No\n";
      }
      $body .= "SCA MEMBERSHIP" . display_updated($u_membership) . ": #$membership_number - " . format_full_month_date($expiration_date) . "\n\n";
      $body .= "CERTIFICATIONS:\n";
      $disp_first_aid_agency = $first_aid_agency;
      if ($first_aid_agency == "Other")
      {
         $disp_first_aid_agency = $first_aid_agency_other;
      }
      $body .= "FIRST AID" . display_updated($u_first_aid) . ": " . format_short_date($first_aid_date) . " - $disp_first_aid_agency\n";
      $disp_adult_cpr_agency = $adult_cpr_agency;
      if ($adult_cpr_agency == "Other")
      {
         $disp_adult_cpr_agency = $adult_cpr_agency_other;
      }
      $body .= "ADULT CPR" . display_updated($u_adult_cpr) . ": " . format_short_date($adult_cpr_date) . " - $disp_adult_cpr_agency\n";
      if ($child_cpr_date != "")
      {
         $disp_child_cpr_agency = $child_cpr_agency;
         if ($child_cpr_agency == "Other")
         {
            $disp_child_cpr_agency = $child_cpr_agency_other;
         }
         $body .= "INFANT & CHILD CPR" . display_updated($u_child_cpr) . ": " . format_short_date($child_cpr_date) . " - $disp_child_cpr_agency\n";
      }
      else
      {
         $body .= "INFANT & CHILD CPR" . display_updated($u_child_cpr) . ": None\n";
      }
      $body .= "OTHER CERTIFICATIONS" . display_updated($u_other_certs) . ": $other_certs";
      if ($other_certs == "")
      {
         $body .= "None";
      }
      $body .= "\n\n";
      if ($report_type == $RT_QUARTERLY)
      {
         $body .= "ACTIVITIES:\n";
         $evt_count = 0;
         for ($j = 1; $j <= $MAX_EVENTS; $j++)
         {
            if (${"event_id" . $j} != "" && ${"position" . $j} != "")
            {
               $body .= "\nPOSITION: " . ${"position" . $j} . "\n";
               $evt_count++;
               $query = "SELECT e.event_id, e.name, e.gname, e.start_date, e.end_date, e.site_name, e.address, e.city, e.state, e.zip " . 
                        "FROM $DBNAME_SPIKE.event_main e " . 
                        "WHERE e.event_id = " . quote_smart(${"event_id" . $j});
               $result = mysql_query($query) or die ("Query Error ($query).  Please notify webminister@eastkingdom.org with this error.");
               $data = mysql_fetch_array($result, MYSQL_BOTH);
               $event_id = clean($data['event_id']);
               $event_name = clean($data['name']);
               $host_group = clean($data['gname']);
               $start_date = clean($data['start_date']);
               $end_date = clean($data['end_date']);
               $site_name = clean($data['site_name']);
               $e_address = clean($data['address']);
               $e_city = clean($data['city']);
               $e_state = clean($data['state']);
               $e_zip = clean($data['zip']);

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

               $body .= "EVENT: $event_name\n";
               $body .= "EVENT DATES: $date_display\n";
               $body .= "HOST GROUP: $host_group\n";
               $body .= "LOCATION: $site_name\n";
               $body .= "          $e_address\n";
               $body .= "          $e_city, $e_state $e_zip\n";
               mysql_free_result($result);
            }
         }
         if ($evt_count == 0)
         {
            $body .= "None\n";
         }
         $body .= "\n";
      } // Activities
      $body .= "COMMENTS: $comments";
      if ($comments == "")
      {
         $body .= "None";
      }
      $body .= "\n\n";

      $response = "<p>Your report has been sent to the Kingdom Chirurgeon" . $response_extra . " and a copy sent to you at $email.  The report text is displayed below.</p>";
      if (!mail($recip, $subject, $body, $headers))
      {
         $response = "<p>We're sorry; we are unable to send your report at this time.  Please try again later.<p>";
      }
      echo $response;

      // Display on screen
      $report = str_replace("\n", "<br/>", $body);
      echo $report;

      db_disconnect($link);
   }
}
if (!isset($_POST['submit']) || (isset($_POST['submit']) && $errmsg != ""))
{
   $link = db_connect();
?>
<h2>Chirurgeon <?php echo $report_type; ?> Report</h2>
<p>Check the "Updated?" box for a field if the information has changed since your last report.<br/>
Don't forget to send the Kingdom Chirurgeon a scanned copy or photocopy of the updated documents for membership/certification changes.
</p>
<? 
   if ($errmsg != "")
   {
?>
<p style="color:red;font-weight:bold;"><?php echo $errmsg; ?></p>
<? 
   }
?>
<form action="<?php echo $_SERVER['PHP_SELF']; ?>" method="post">
<input type="hidden" name="report_type" id="report_type" value="<?php echo $report_type; ?>"/>
<?php
   if (isset($quarter))
   {
?>
<input type="hidden" name="quarter" id="quarter" value="<?php echo $quarter; ?>"/>
<?php
   }
?>
<table border="1" cellspacing="0" cellpadding="5" summary="Chirurgeon Report Form">
   <tr>
      <th colspan="3" class="title">REPORT</th>
   </tr>
   <tr>
      <th colspan="2" class="titleleft">REPORT DATE</th>
      <td class="data"><?php echo $today; ?></td>
   </tr>
   <tr>
      <th colspan="2" class="titleleft">REPORT TYPE</th>
      <td class="data"><?php echo $report_title; ?></td>
   </tr>
   <tr>
      <th class="title">Updated?</th>
      <th colspan="2" class="title">CONTACT INFORMATION</th>
   </tr>
   <tr>
      <td class="datacenter"><input type="checkbox" name="u_legal_name" id="u_legal_name" value="1"<?php if (isset($u_legal_name) && $u_legal_name == 1) { echo " checked=\"checked\""; } ?> /></td>
      <th class="titleleft">LEGAL NAME</th>
      <td class="data"><input type="text" name="legal_name" id="legal_name" size="50" value="<?php if (isset($legal_name)) { echo $legal_name; } ?>" /></td>
   </tr>
   <tr>
      <td class="datacenter"><input type="checkbox" name="u_sca_name" id="u_sca_name" value="1"<?php if (isset($u_sca_name) && $u_sca_name == 1) { echo " checked=\"checked\""; } ?> /></td>
      <th class="titleleft">SCA NAME</th>
      <td class="data"><input type="text" name="sca_name" id="sca_name" size="50" value="<?php if (isset($sca_name)) { echo $sca_name; } ?>" /></td>
   </tr>
   <tr>
      <td class="datacenter"><input type="checkbox" name="u_address" id="u_address" value="1"<?php if (isset($u_address) && $u_address == 1) { echo " checked=\"checked\""; } ?> /></td>
      <th class="titleleft">ADDRESS</th>
      <td class="data">
      Line 1: <input type="text" name="address1" id="address1" size="50" value="<?php if (isset($address1)) { echo $address1; } ?>" /><br/>
      Line 2: <input type="text" name="address2" id="address2" size="50" value="<?php if (isset($address2)) { echo $address2; } ?>" /><br/>
      City: <input type="text" name="city" id="city" size="30" value="<?php if (isset($city)) { echo $city; } ?>" />
      State: <select name="state" id="state">
               <option value="AL"<?php if (isset($state) && $state == "AL") { echo " selected=\"selected\""; } ?>>AL</option>
               <option value="AK"<?php if (isset($state) && $state == "AK") { echo " selected=\"selected\""; } ?>>AK</option>
               <option value="AZ"<?php if (isset($state) && $state == "AZ") { echo " selected=\"selected\""; } ?>>AZ</option>
               <option value="AR"<?php if (isset($state) && $state == "AR") { echo " selected=\"selected\""; } ?>>AR</option>
               <option value="CA"<?php if (isset($state) && $state == "CA") { echo " selected=\"selected\""; } ?>>CA</option>
               <option value="CO"<?php if (isset($state) && $state == "CO") { echo " selected=\"selected\""; } ?>>CO</option>
               <option value="CT"<?php if (isset($state) && $state == "CT") { echo " selected=\"selected\""; } ?>>CT</option>
               <option value="DE"<?php if (isset($state) && $state == "DE") { echo " selected=\"selected\""; } ?>>DE</option>
               <option value="FL"<?php if (isset($state) && $state == "FL") { echo " selected=\"selected\""; } ?>>FL</option>
               <option value="GA"<?php if (isset($state) && $state == "GA") { echo " selected=\"selected\""; } ?>>GA</option>
               <option value="HI"<?php if (isset($state) && $state == "HI") { echo " selected=\"selected\""; } ?>>HI</option>
               <option value="ID"<?php if (isset($state) && $state == "ID") { echo " selected=\"selected\""; } ?>>ID</option>
               <option value="IL"<?php if (isset($state) && $state == "IL") { echo " selected=\"selected\""; } ?>>IL</option>
               <option value="IN"<?php if (isset($state) && $state == "IN") { echo " selected=\"selected\""; } ?>>IN</option>
               <option value="IA"<?php if (isset($state) && $state == "IA") { echo " selected=\"selected\""; } ?>>IA</option>
               <option value="KS"<?php if (isset($state) && $state == "KS") { echo " selected=\"selected\""; } ?>>KS</option>
               <option value="KY"<?php if (isset($state) && $state == "KY") { echo " selected=\"selected\""; } ?>>KY</option>
               <option value="LA"<?php if (isset($state) && $state == "LA") { echo " selected=\"selected\""; } ?>>LA</option>
               <option value="ME"<?php if (isset($state) && $state == "ME") { echo " selected=\"selected\""; } ?>>ME</option>
               <option value="MD"<?php if (isset($state) && $state == "MD") { echo " selected=\"selected\""; } ?>>MD</option>
               <option value="MA"<?php if (isset($state) && $state == "MA") { echo " selected=\"selected\""; } ?>>MA</option>
               <option value="MI"<?php if (isset($state) && $state == "MI") { echo " selected=\"selected\""; } ?>>MI</option>
               <option value="MN"<?php if (isset($state) && $state == "MN") { echo " selected=\"selected\""; } ?>>MN</option>
               <option value="MS"<?php if (isset($state) && $state == "MS") { echo " selected=\"selected\""; } ?>>MS</option>
               <option value="MO"<?php if (isset($state) && $state == "MO") { echo " selected=\"selected\""; } ?>>MO</option>
               <option value="NE"<?php if (isset($state) && $state == "NE") { echo " selected=\"selected\""; } ?>>NE</option>
               <option value="NV"<?php if (isset($state) && $state == "NV") { echo " selected=\"selected\""; } ?>>NV</option>
               <option value="NH"<?php if (isset($state) && $state == "NH") { echo " selected=\"selected\""; } ?>>NH</option>
               <option value="NJ"<?php if (isset($state) && $state == "NJ") { echo " selected=\"selected\""; } ?>>NJ</option>
               <option value="NM"<?php if (isset($state) && $state == "NM") { echo " selected=\"selected\""; } ?>>NM</option>
               <option value="NY"<?php if (isset($state) && $state == "NY") { echo " selected=\"selected\""; } ?>>NY</option>
               <option value="NC"<?php if (isset($state) && $state == "NC") { echo " selected=\"selected\""; } ?>>NC</option>
               <option value="ND"<?php if (isset($state) && $state == "ND") { echo " selected=\"selected\""; } ?>>ND</option>
               <option value="OH"<?php if (isset($state) && $state == "OH") { echo " selected=\"selected\""; } ?>>OH</option>
               <option value="OK"<?php if (isset($state) && $state == "OK") { echo " selected=\"selected\""; } ?>>OK</option>
               <option value="OR"<?php if (isset($state) && $state == "OR") { echo " selected=\"selected\""; } ?>>OR</option>
               <option value="PA"<?php if (isset($state) && $state == "PA") { echo " selected=\"selected\""; } ?>>PA</option>
               <option value="RI"<?php if (isset($state) && $state == "RI") { echo " selected=\"selected\""; } ?>>RI</option>
               <option value="SC"<?php if (isset($state) && $state == "SC") { echo " selected=\"selected\""; } ?>>SC</option>
               <option value="SD"<?php if (isset($state) && $state == "SD") { echo " selected=\"selected\""; } ?>>SD</option>
               <option value="TN"<?php if (isset($state) && $state == "TN") { echo " selected=\"selected\""; } ?>>TN</option>
               <option value="TX"<?php if (isset($state) && $state == "TX") { echo " selected=\"selected\""; } ?>>TX</option>
               <option value="UT"<?php if (isset($state) && $state == "UT") { echo " selected=\"selected\""; } ?>>UT</option>
               <option value="VT"<?php if (isset($state) && $state == "VT") { echo " selected=\"selected\""; } ?>>VT</option>
               <option value="VA"<?php if (isset($state) && $state == "VA") { echo " selected=\"selected\""; } ?>>VA</option>
               <option value="WA"<?php if (isset($state) && $state == "WA") { echo " selected=\"selected\""; } ?>>WA</option>
               <option value="WV"<?php if (isset($state) && $state == "WV") { echo " selected=\"selected\""; } ?>>WV</option>
               <option value="WI"<?php if (isset($state) && $state == "WI") { echo " selected=\"selected\""; } ?>>WI</option>
               <option value="WY"<?php if (isset($state) && $state == "WY") { echo " selected=\"selected\""; } ?>>WY</option>
            </select>
      Zip: <input type="text" name="zip" id="zip" size="10" maxlength="10" value="<?php if (isset($zip)) { echo $zip; } ?>" />
      </td>
   </tr>
   <tr>
      <td class="datacenter"><input type="checkbox" name="u_phone" id="u_phone" value="1"<?php if (isset($u_phone) && $u_phone == 1) { echo " checked=\"checked\""; } ?> /></td>
      <th class="titleleft">HOME PHONE</th>
      <td class="data"><input type="text" name="phone" id="phone" size="15" value="<?php if (isset($phone)) { echo $phone; } ?>" /></td>
   </tr>
   <tr>
      <td class="datacenter"><input type="checkbox" name="u_mphone" id="u_mphone" value="1"<?php if (isset($u_mphone) && $u_mphone == 1) { echo " checked=\"checked\""; } ?> /></td>
      <th class="titleleft">MOBILE PHONE</th>
      <td class="data"><input type="text" name="mphone" id="mphone" size="15" value="<?php if (isset($mphone)) { echo $mphone; } ?>" /></td>
   </tr>
   <tr>
      <td class="datacenter"><input type="checkbox" name="u_email" id="u_email" value="1"<?php if (isset($u_email) && $u_email == 1) { echo " checked=\"checked\""; } ?> /></td>
      <th class="titleleft">EMAIL ADDRESS</th>
      <td class="data"><input type="text" name="email" id="email" size="50" value="<?php if (isset($email)) { echo $email; } ?>" /></td>
   </tr>
   <tr>
      <td class="datacenter"><input type="checkbox" name="u_home_branch" id="u_home_branch" value="1"<?php if (isset($u_home_branch) && $u_home_branch == 1) { echo " checked=\"checked\""; } ?> /></td>
      <th class="titleleft">HOME BRANCH</th>
      <td class="data">
      <select name="home_branch" id="home_branch">
         <option></option>
<?php 
   if (!isset($home_branch))
   {
      $home_branch = "";
   }
   list_branches($home_branch); 
?>
      </select>
      </td>
   </tr>
   <tr>
      <td class="datacenter"><input type="checkbox" name="u_branch_chir" id="u_branch_chir" value="1"<?php if (isset($u_branch_chir) && $u_branch_chir == 1) { echo " checked=\"checked\""; } ?> /></td>
      <th class="titleleft">BRANCH CHIRURGEON?</th>
      <td class="data">Yes <input type="checkbox" name="branch_chir" id="branch_chir" value="1"<?php if (isset($branch_chir) && $branch_chir == 1) { echo " checked=\"checked\""; } ?> />
      Branch: <select name="chir_branch" id="chir_branch">
         <option></option>
<?php 
   if (!isset($chir_branch))
   {
      $chir_branch = "";
   }
   list_branches($chir_branch); 
?>
      </select>
      </td>

   </tr>
   <tr>
      <td class="datacenter"><input type="checkbox" name="u_membership" id="u_membership" value="1"<?php if (isset($u_membership) && $u_membership == 1) { echo " checked=\"checked\""; } ?> /></td>
      <th class="titleleft">SCA MEMBERSHIP</th>
      <td class="data">
      Number: <input type="text" name="membership_number" id="membership_number" size="12" value="<?php if (isset($membership_number)) { echo $membership_number; } ?>" />
      Expiration Date: <input type="text" name="expiration_date" id="expiration_date" size="12" value="<?php if (isset($expiration_date)) { echo $expiration_date; } ?>" />
      </td>
   </tr>
   <tr>
      <th colspan="3" class="title">CERTIFICATIONS</th>
   </tr>
   <tr>
      <td colspan="3" align="center">
      <table border="1" cellspacing="0" cellpadding="5" summary="Certifications Form">
         <tr>
            <th class="title">Updated?</th>
            <th class="titleleft">Certification</th>
            <th class="titleleft">Expiration Date</th>
            <th class="titleleft">Certifying Agency</th>
         </tr>
         <tr>
            <td class="datacenter"><input type="checkbox" name="u_first_aid" id="u_first_aid" value="1"<?php if (isset($u_first_aid) && $u_first_aid == 1) { echo " checked=\"checked\""; } ?> /></td>
            <th class="titleleft">FIRST AID</th>
            <td class="data"><input type="text" name="first_aid_date" id="first_aid_date" size="12" value="<?php if (isset($first_aid_date)) { echo $first_aid_date; } ?>" /></td>
            <td class="data"><select name="first_aid_agency" id="first_aid_agency">
               <option value="American Red Cross"<?php if (isset($first_aid_agency) && $first_aid_agency == "American Red Cross") { echo " selected=\"selected\""; } ?>>American Red Cross</option>
               <option value="American Heart Association"<?php if (isset($first_aid_agency) && $first_aid_agency == "American Heart Association") { echo " selected=\"selected\""; } ?>>American Heart Association</option>
               <option value="Other"<?php if (isset($first_aid_agency) && $first_aid_agency == "Other") { echo " selected=\"selected\""; } ?>>Other</option>
            </select>
            Specify if Other: <input type="text" name="first_aid_agency_other" id="first_aid_agency_other" size="20" value="<?php if (isset($first_aid_agency_other)) { echo $first_aid_agency_other; } ?>" />
            </td>
         </tr>
         <tr>
            <td class="datacenter"><input type="checkbox" name="u_adult_cpr" id="u_adult_cpr" value="1"<?php if (isset($u_adult_cpr) && $u_adult_cpr == 1) { echo " checked=\"checked\""; } ?> /></td>
            <th class="titleleft">ADULT CPR</th>
            <td class="data"><input type="text" name="adult_cpr_date" id="adult_cpr_date" size="12" value="<?php if (isset($adult_cpr_date)) { echo $adult_cpr_date; } ?>" /></td>
            <td class="data"><select name="adult_cpr_agency" id="adult_cpr_agency">
               <option value="American Red Cross"<?php if (isset($adult_cpr_agency) && $adult_cpr_agency == "American Red Cross") { echo " selected=\"selected\""; } ?>>American Red Cross</option>
               <option value="American Heart Association"<?php if (isset($adult_cpr_agency) && $adult_cpr_agency == "American Heart Association") { echo " selected=\"selected\""; } ?>>American Heart Association</option>
               <option value="Other"<?php if (isset($adult_cpr_agency) && $adult_cpr_agency == "Other") { echo " selected=\"selected\""; } ?>>Other</option>
            </select>
            Specify if Other: <input type="text" name="adult_cpr_agency_other" id="adult_cpr_agency_other" size="20" value="<?php if (isset($adult_cpr_agency_other)) { echo $adult_cpr_agency_other; } ?>" />
            </td>
         </tr>
         <tr>
            <td class="datacenter"><input type="checkbox" name="u_child_cpr" id="u_child_cpr" value="1"<?php if (isset($u_child_cpr) && $u_child_cpr == 1) { echo " checked=\"checked\""; } ?> /></td>
            <th class="titleleft">INFANT &amp; CHILD CPR</th>
            <td class="data"><input type="text" name="child_cpr_date" id="child_cpr_date" size="12" value="<?php if (isset($child_cpr_date)) { echo $child_cpr_date; } ?>" /></td>
            <td class="data"><select name="child_cpr_agency" id="child_cpr_agency">
               <option value="American Red Cross"<?php if (isset($child_cpr_agency) && $child_cpr_agency == "American Red Cross") { echo " selected=\"selected\""; } ?>>American Red Cross</option>
               <option value="American Heart Association"<?php if (isset($child_cpr_agency) && $child_cpr_agency == "American Heart Association") { echo " selected=\"selected\""; } ?>>American Heart Association</option>
               <option value="Other"<?php if (isset($child_cpr_agency) && $child_cpr_agency == "Other") { echo " selected=\"selected\""; } ?>>Other</option>
            </select>
            Specify if Other: <input type="text" name="child_cpr_agency_other" id="child_cpr_agency_other" size="20" value="<?php if (isset($child_cpr_agency_other)) { echo $child_cpr_agency_other; } ?>" />
            </td>
         </tr>
      </table>
      </td>
   </tr>
   <tr>
      <td class="datacenter"><input type="checkbox" name="u_other_certs" id="u_other_certs" value="1"<?php if (isset($u_other_certs) && $u_other_certs == 1) { echo " checked=\"checked\""; } ?> /></td>
      <th class="title">OTHER CERTIFICATIONS / LICENSES<br/>AND EXPIRATION DATES<br/>(EMT, Paramedic, RN, MD, etc.)</th>
      <td class="data"><textarea type="text" name="other_certs" id="other_certs" cols="50" rows="10"><?php if (isset($other_certs)) { echo $other_certs; } ?></textarea></td>
   </tr>
<?php
if ($report_type == $RT_QUARTERLY)
{
?>
   <tr>
      <th colspan="3" class="title">ACTIVITIES</th>
   </tr>
<?
   // Initialize data
   for ($j = 1; $j <= $MAX_EVENTS; $j++)
   {
      if (!isset(${"event_id" . $j}))
      {
         ${"event_id" . $j} = "";
      }
   }
?>
   <tr>
      <td colspan="3" align="center" valign="top">
      <table border="1" cellspacing="0" cellpadding="5">
         <tr>
            <th class="title">Event</th>
            <th class="title">Position</th>
         </tr>
<?
   for ($j = 1; $j <= $MAX_EVENTS; $j++)
   {
?>
         <tr>
            <td class="data">
            <select name="event_id<?php echo $j; ?>" id="event_id<?php echo $j; ?>">
               <option></option>
               <?php list_events(${"event_id" . $j}, $start_range, $end_range, 1); ?>
            </select>
            </td>
            <td class="data">
            <select name="position<?php echo $j; ?>" id="position<?php echo $j; ?>">
               <option></option>
               <option value="CIC"<?php if (isset(${"position" . $j}) && ${"position" . $j} == "CIC") { echo " selected=\"selected\""; } ?>>Chirurgeon in Charge</option>
               <option value="Chirurgeon"<?php if (isset(${"position" . $j}) && ${"position" . $j} == "Chirurgeon") { echo " selected=\"selected\""; } ?>>Chirurgeon</option>
               <option value="CIT"<?php if (isset(${"position" . $j}) && ${"position" . $j} == "CIT") { echo " selected=\"selected\""; } ?>>Chirurgeon in Training</option>
            </select>
            </td>
         </tr>
<?
   }
?>
      </table>
      </td>
   </tr>
<?php
}
?>
   <tr>
      <th colspan="2" class="titleleft">COMMENTS<br/><br/><span style="font-weight:normal;">Do not include any HIPAA-protected<br/>or Personally Identifiable Information!</span></th>
      <td class="data"><textarea name="comments" id="comments" cols="50" rows="10"><?php if (isset($comments)) { echo $comments; } ?></textarea></td>
   </tr>
<?php
if ($may_submit)
{
?>
   <tr>
      <th colspan="3" class="datacenter"><input type="submit" name="submit" id="submit" value="Submit Report" /></th>
   </tr>
<?php
}
else
{
?>
   <tr>
      <th colspan="3" class="datacenter">Reports can be submitted only from one week before to one week after the last day of the quarter.</th>
   </tr>
<?php
}
?>
</table>
</form>

<?php 
db_disconnect($link);
}
include("footer.php");
?>
