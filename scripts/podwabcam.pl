#!/usr/bin/env perl

package WABCAM::Constants;

use strict;

use vars qw/$PLAYLIST $TMPDIR $STOREDIR $ROOTURL $EPISODELENGTH $MAXEP $IMGURL/;

$PLAYLIST = 'http://provisioning.streamtheworld.com/pls/WABCAM.pls';
$TMPDIR = '/tmp/wabcam';
$STOREDIR = '/var/www/tefd.co.uk/hannity';
$ROOTURL = 'http://tefd.co.uk/podcasts/hannity';
$IMGURL = 'http://www.foxnewsradio.com/wp-content/uploads/2009/03/hannity.jpg';
$EPISODELENGTH = 3*60*60;
$MAXEP = 20;

1;

package WABCAM::Worker;

use strict;

use File::MimeInfo;
use File::Path qw/mkpath/;
use File::stat;
use POSIX qw/strftime/;
use XML::RSS;

sub Rip($) {
	my ($playlist) = @_;
	
	local $SIG{INT} = sub { die 'INTERRUPT' };
	
	my $tmpdir = $WABCAM::Constants::TMPDIR . '/' . $$;
	
	unless (-d) {
		mkpath($tmpdir);	
	}
	
	my $tmpfile = $tmpdir . '/' . time;
	
	open STDIN, '/dev/null';
	
	my $cmd = "mplayer -playlist $playlist -dumpstream -dumpfile $tmpfile";
	
	exec($cmd);
}

sub Encode($) {
	my ($tmp) = @_;
	
	unless (-d $WABCAM::Constants::STOREDIR) {
		mkpath($WABCAM::Constants::STOREDIR);
	}
	
	my $filename = $WABCAM::Constants::STOREDIR . '/' . strftime("%Y-%m-%d", localtime) . ".mp3";
	
	my $cmd = "ffmpeg -y -i $tmp/* -ab 50k -ar 44100 -ac 2 -vn $filename";
	
	system($cmd);
}

sub UpdatePodcast() {
	my $rss = XML::RSS->new(version => '2.0');
	
	$rss->channel(
		title => 'Sean Hannity',
		link => $WABCAM::Constants::ROOTURL,
		description => 'The Sean Hannity Show on WABCAM',
		pubDate  => strftime('%a, %d %b %Y %T %z', gmtime(time)),
		lastBuildDate  => strftime('%a, %d %b %Y %T %z', gmtime(time)),
	);
	
	$rss->image(
		title => 'Sean Hannity',
		description => 'Sean Hannity',
		url => $WABCAM::Constants::IMGURL,
		link => $WABCAM::Constants::ROOTURL,
	);
	
	opendir DIR, $WABCAM::Constants::STOREDIR;
	
	my $count = 0;
	
	foreach my $file (reverse sort grep { /mp3$/ } readdir DIR) {
		my $filepath = $WABCAM::Constants::STOREDIR . '/' . $file;
		
		if ($count <= $WABCAM::Constants::MAXEP) {
			my $stat = stat($filepath);
			
			my @date = gmtime($stat->mtime);
			
			$rss->add_item(
				title => "Sean Hannity - " . strftime('%a, %d %b %Y', @date),
				description => "The Sean Hannity show for " . strftime('%a, %d %b %Y', @date),
				pubDate => strftime('%a, %d %b %Y %T %z', @date),
				enclosure => {
					url => $WABCAM::Constants::ROOTURL . '/' . $file,
					length => -s $filepath,
					type => mimetype($filepath)
				},
				permaLink => $WABCAM::Constants::ROOTURL . '/' . $file
			);	
		}
		else {
			unlink($filepath);	
		}
		$count++;
	}
	
	closedir DIR;
	
	$rss->save($WABCAM::Constants::STOREDIR . '/feed.rss');
}

1;

use strict;

use File::Path qw/rmtree/;

use vars qw/$VERSION/;

$VERSION = '0.0.1';

my $pid = fork;

if($pid) {
	eval {
		local $SIG{ALRM} = sub { die 'TIMEOUT' };
		
		alarm($WABCAM::Constants::EPISODELENGTH);
		
		waitpid($pid, 0);
		
		alarm(0);	
	} or do {
		if ($@ =~ /TIMEOUT/) {
			kill 'INT' => $pid;
		}
	};
	
	my $tmpdir = $WABCAM::Constants::TMPDIR . '/' . $pid;
	
	WABCAM::Worker::Encode($tmpdir);
	
	WABCAM::Worker::UpdatePodcast();
	
	rmtree($tmpdir);
}
else {
	WABCAM::Worker::Rip($WABCAM::Constants::PLAYLIST);
}
