use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	      'NAME'	  => 'XML::Stream',
	      'PM' 	  => {
			      'Stream.pm' => '$(INST_LIBDIR)/Stream.pm'
			     },
	      'PREREQ_PM' => {
			      'XML::Parser' => 0 
			     },
	      'VERSION'   => '0.1',
	      'dist'      => { 'COMPRESS' => 'gzip --best' }
	     );
