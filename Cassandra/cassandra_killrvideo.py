#!/Users/mrex/bin/python

# This is from my Cassandra training course.  This was written on my VM on my linux workstation.

# Given
#CREATE TABLE killrvideo.videos_by_tag (
#    tag text,
#    added_date timestamp,
#    video_id timeuuid,
#    title text,
#    PRIMARY KEY (tag, added_date, video_id)
#) WITH CLUSTERING ORDER BY (added_date DESC, video_id ASC)
#    AND bloom_filter_fp_chance = 0.01
#    AND caching = {'keys': 'ALL', 'rows_per_partition': 'NONE'}
#    AND comment = ''
#    AND compaction = {'class': 'org.apache.cassandra.db.compaction.SizeTieredCompactionStrategy', 'max_threshold': '32', 'min_threshold': '4'}
#    AND compression = {'chunk_length_in_kb': '64', 'class': 'org.apache.cassandra.io.compress.LZ4Compressor'}
#    AND crc_check_chance = 1.0
#    AND dclocal_read_repair_chance = 0.1
#    AND default_time_to_live = 0
#    AND gc_grace_seconds = 864000
#    AND max_index_interval = 2048
#    AND memtable_flush_period_in_ms = 0
#    AND min_index_interval = 128
#    AND read_repair_chance = 0.0
#    AND speculative_retry = '99PERCENTILE';

from cassandra.cluster import Cluster
cluster = Cluster(protocol_version = 3)
session = cluster.connect('killrvideo')

session.execute('use killrvideo')
rows = session.execute('SELECT * FROM videos_by_tag')

# Basic output
#for row in rows:
#	print(row.tag, row.added_date, row.title)

print('SELECT * FROM videos_by_tag;')
# More complex formatting
print('{0:12} {1:40} {2:5}'.format('Tag', 'ID', 'Title')) 
for val in session.execute("select * from videos_by_tag"):
	print('{0:12} {1:40} {2:5}'.format(val[0], val[2], val[3]))

print('Inserting record...')
# Insert some data
newdata = session.execute("INSERT INTO videos_by_tag (tag, added_date, video_id, title) VALUES ('datastax', '2021-11-08', 4845ed9c-14bd-11e5-76ef-8338355b7e45, 'Cassandra Test Record deux')") 

print('{0:12} {1:40} {2:5}'.format('Tag', 'ID', 'Title')) 
for val in session.execute("select * from videos_by_tag"):
	print('{0:12} {1:40} {2:5}'.format(val[0], val[2], val[3]))

print('Deleting record...')
delnewdata = session.execute("DELETE FROM videos_by_tag WHERE tag = 'datastax' AND added_date = '2021-11-08' AND video_id = 4845ed9c-14bd-11e5-76ef-8338355b7e45") 

print('{0:12} {1:40} {2:5}'.format('Tag', 'ID', 'Title')) 
for val in session.execute("select * from videos_by_tag"):
	print('{0:12} {1:40} {2:5}'.format(val[0], val[2], val[3]))
