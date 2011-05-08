package WABCAM::Worker;

use strict;

use File::Path qw/mkpath/;
use File::stat;
use WABCAM::Constants;
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
	
	my $cmd = "ffmpeg -y -i $tmp/* -ab 48k -ar 44100 -ac 2 -vn $filename";
	
	system($cmd);
}

sub UpdatePodcast() {
	my $rss = XML::RSS->new(version => '2.0');
	
	$rss->channel(
		title => 'Sean Hannity',
		link => $WABCAM::Constants::ROOTURL,
		description => 'The Sean Hannity Show on WABCAM',
		pubDate => strftime("%c", localtime)
	);
	
	$rss->image(
		title => 'Sean Hannity',
		description => 'Sean Hannity',
		url => $WABCAM::Constants::ROOTURL . '/hannity.jpg',
		link => $WABCAM::Constants::ROOTURL,
	);
	
	opendir DIR, $WABCAM::Constants::STOREDIR;
	
	my $count = 0;
	
	foreach my $file (reverse sort grep { /mp3$/ } readdir DIR) {
		my $filepath = $WABCAM::Constants::STOREDIR . '/' . $file;
		
		if ($count <= $WABCAM::Constants::MAXEP) {
			my $stat = stat($filepath);
			
			my $date = $stat->mtime;
			
			$rss->add_item(
				title => "Sean Hannity - " . strftime("%Y-%m-%d", localtime($date)),
				description => "The Sean Hannity show for " . strftime("%A %B %e %Y", localtime($date)),
				pubDate => strftime("%c", localtime($date)),
				enclosure => {
					url => $WABCAM::Constants::ROOTURL . '/' . $file,
					length => -s $filepath,
					type => 'audio/mpeg'
				}
			);	
		}
		else {
			unlink($filepath);	
		}
		$count++;
	}
	
	closedir DIR;
	
	print $rss->save($WABCAM::Constants::STOREDIR . '/podcast.rss');
}

1;
