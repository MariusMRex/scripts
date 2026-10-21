<?php
include_once("functions/db.php");

if (!isset($title))
{
   $title = "Home";
}

echo '<?xml version="1.0" encoding="iso-8859-1"?>';
?>
<!DOCTYPE html 
     PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">

<head>
   <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
   <meta http-equiv="Description" content="Eastern Chirurgeonate" />
   <meta http-equiv="Keywords" content="SCA, The East, Chirurgeon, First Aid" />
   <meta http-equiv="Copyright" content="Kingdom of The East/SCA, Inc. 2008" />
   <title>The Eastern Chirurgeonate - <?php echo $title; ?></title>
   <link rel="stylesheet" type="text/css" href="<?php echo $HOME_DIR; ?>style.css" />
	<link rel="shortcut icon" href="<?php echo $HOME_DIR; ?>favicon.ico" />
</head>

<body>
<table>
   <tr>
      <td valign="top" nowrap="nowrap">
      <!-- Navigation -->
      <img src="<?php echo $IMAGES_DIR; ?>EKOFFICERS_chiurgeon_color.gif" alt="Chirurgeon's Badge" /><br/>
      &gt; <a href="<?php echo $HOME_DIR; ?>index.php">Welcome</a><br/>
      &gt; <a href="<?php echo $HOME_DIR; ?>staff.php">Staff</a><br/>
      &gt; <a href="<?php echo $HOME_DIR; ?>requirements.php">Requirements</a><br/>
      &gt; <a href="<?php echo $HOME_DIR; ?>roster.php">Roster</a><br/>
      &gt; <a href="<?php echo $HOME_DIR; ?>forms.php">Forms</a><br/>
      &gt; <a href="<?php echo $HOME_DIR; ?>reports.php">Reports</a><br/>
      &gt; <a href="<?php echo $HOME_DIR; ?>training.php">Training</a><br/>
      </td>
      <td>
      <!-- Body -->
      <!--<img src="images/Welcome_NBanner.gif" alt="The Eastern Chirurgeonate" />-->
      <br/>
