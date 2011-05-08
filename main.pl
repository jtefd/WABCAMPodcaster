#!/usr/bin/perl

BEGIN {
	use FindBin;
	use lib $FindBin::Bin;
}

use strict;

use WABCAM::Worker;
use WABCAM::Constants;
use File::Path qw/rmtree/;

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

exit 0;

