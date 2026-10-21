# If I have a list iof email addresses the only thing I need 
# is to replace all newlines with a tab and an ID.  (Say 125 for ReturnPath)

# I am just recording this so i do not have to re-invent/rethink under pressure.
# Step #1 Copy/paste data from ReturnPath into a file
# 
# Step #2 use perl inline editing to do the text transform
perl -i.org -pe "s/\n/\t125\n/" returnpath.2012-03-22
