use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WABCAMPodcaster',
    VERSION_FROM      => 'scripts/podwabcam.pl', # finds $VERSION
    PREREQ_PM         => { 'File::Basename', 'File::MimeInfo', 'File::Path', 'File::Spec::Functions', 'File::stat', 'POSIX', 'XML::RSS' }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'Create WABCAM podcast', 
       AUTHOR         => 'James Telford <james@tefd.co.uk>') : ()),
       EXE_FILES         => [ 'scripts/podwabcam.pl' ],
);