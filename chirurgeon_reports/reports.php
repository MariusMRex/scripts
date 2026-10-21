<?php
$title = 'Reports';
include("header.php");
?>
<h2>Kingdom Chirurgeonate Reports</h2>

<h3>Event Reports</h3>

<ul>
   <li><a href="http://sca.org/officers/chirurgeon/pdf/ChirEventRpt-07.pdf">Chirurgeon Event Report</a> (PDF)</li>
   <li><a href="event_report.php">Chirurgeon Event Report</a> (Online)</li>
</ul>

<h3>Evaluations</h3>

<ul>
   <li><a href="http://sca.org/officers/chirurgeon/pdf/CiTEval-07.pdf">Chirurgeon In Training (CIT) Evaluation</a> (PDF)</li>
   <li><a href="cit_eval.php">Chirurgeon In Training (CIT) Evaluation</a> (Online)</li>
</ul>

<h3>Periodic Reports</h3>

<ul>
   <li><a href="periodic_report.php?report_type=<?php echo $RT_QUARTERLY; ?>">Chirurgeon Quarterly Report</a> (Online)</li>
   <li><a href="periodic_report.php?report_type=<?php echo $RT_ANNUAL; ?></a>">Chirurgeon Annual Report</a> (Online)</li>
</ul>

<table border="1" cellspacing="0" cellpadding="5">
   <caption class="titlenobg">Report Schedule</caption>
   <tr>
      <th class="title">Report</th>
      <th class="title">Reporting Period</th>
      <th class="title">Due Date</th>
   </tr>
   <tr>
      <td class="data">1st Quarter</td>
      <td class="data">December 1 - February 28 (or 29th)</td>
      <td class="data">March 5</td>
   </tr>
   <tr>
      <td class="data">2nd Quarter</td>
      <td class="data">March 1 - May 31</td>
      <td class="data">June 5</td>
   </tr>
   <tr>
      <td class="data">3rd Quarter</td>
      <td class="data">June 1 - August 31</td>
      <td class="data">September 5</td>
   </tr>
   <tr>
      <td class="data">4th Quarter</td>
      <td class="data">September 1 - November 30</td>
      <td class="data">December 5</td>
   </tr>
   <tr>
      <td class="data">Annual</td>
      <td class="data">December 1 - November 30</td>
      <td class="data">December 5</td>
   </tr>
</table>

<p>
Per section 8.7.3 of the Eastern Book of Policy, "Annual reports are required from all Chirurgeons. 
These are due in writing by December 5th for the previous twelve months. 
It shall provide a summary of all activity and care provided during that period.  . . . 
This annual report can be combined with the regular fourth quarter report.  
Failure to submit an annual report may result in the suspension of the Chirurgeon's warrant.  . . . 
For those Chirurgeons who are also designated as a group officer, a copy should be provided to the group seneschal as well."
</p>
<p>
If you submitted a 3rd quarter report, then the 4th quarter report will serve in lieu of a separate annual report.  
It will cover the period between September 1 and November 30.  If you did not submit a 3rd quarter report OR 
have not submitted any reports since last Unevent, then you must submit an annual report.  
The annual report must cover from December 1 through November 30.
</p>
<p>
If you are a warranted Chirurgeon, a quarterly report must be submitted if ANY of the following apply during a quarter:
<ul>
   <li>You served as Chirurgeon in Charge for an event</li>
   <li>You served as Chirurgeon at an event (including Pennsic)</li>
   <li>You taught any Chirurgeon-related classes (including at Pennsic)</li>
   <li>You became a warranted Chirurgeon (promoted from CIT)</li>
   <li>You updated your membership or certifications</li>
</ul>
</p>
<p>
If you updated your membership or certifications, don't forget to send the Kingdom Chirurgeon a scanned copy or photocopy of the documents.  
Without proof that your membership and certifications are current, the situation must be treated as though they have lapsed, 
and therefore you would be in 'suspended' status:  unable to serve as a Chirurgeon or CIC at an event.
</p>

<p>
<a href="http://www.adobe.com/go/EN_US-H-GET-READER" title="External Link"><img src="http://www.adobe.com/images/shared/download_buttons/get_adobe_reader.png" align="left" alt="Download Adobe Acrobat Reader" /></a>
<span style="font-size:80%">
To view PDF forms you will need to download Adobe Acrobat Reader.<br/>
Adobe, Acrobat, and the Acrobat Logo are Trademarks of Adobe Systems Inc.
</span>
</p>

<? include("footer.php"); ?>
