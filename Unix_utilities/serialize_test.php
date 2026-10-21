<?php
#$str = 'a:12:{s:5:"email";s:30:"lindseyjohanson@lifescript.com";s:11:"postal_code";s:5:"92660";s:5:"refer";s:18:"D25-LifeScript-t25";s:10:"source_url";s:79:"http://lsa.lifescript.com/advantage/hp8831/main.aspx?utm_campaign=hp";s:22:"subscription_source_id";i:7;s:17:"subscription_date";s:19:"2011-06-14 17:56:12";s:10:"visitor_id";N;s:8:"refer_id";i:29445317;s:4:"uuid";N;s:10:"email_type";s:17:"top25WelcomeEmail";s:9:"firstname";s:7:"lindsey";s:8:"lastname";s:8:"johanson";}';
$str = 'a:12:{s:5:"email";s:30:"lindseyjohanson@lifescript.com";s:11:"postal_code";s:5:"92660";s:5:"refer";s:18:"D25-LifeScript-t25";s:10:"source_url";s:68:"http://lsa.lifescript.com/advantage/hp8831/main.aspx?utm_campaign=hp";s:22:"subscription_source_id";i:7;s:17:"subscription_date";s:19:"2011-06-14 17:56:12";s:10:"visitor_id";N;s:8:"refer_id";i:29445317;s:4:"uuid";N;s:10:"email_type";s:17:"top25WelcomeEmail";s:9:"firstname";s:7:"lindsey";s:8:"lastname";s:8:"johanson";}';

var_dump(unserialize($str));
