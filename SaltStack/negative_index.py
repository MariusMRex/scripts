#! /usr/bin/python

# I need a the target of a salt orchestration script to work out to be '*dbslave01'
master = 'p1-db01'  # Supplied to orch script by custome execution script
dbnum = master[-2:]  # grab last two numerals
target = "*dbslave"+dbnum # Append last two numerals from the master name

print target
