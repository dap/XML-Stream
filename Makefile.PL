use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	      'NAME'	  => 'XML::Stream',
	      'PM' 	  => {
			      'Stream.pm' => '$(INST_LIBDIR)/Stream.pm',
			      'Stream/Namespace.pm' => '$(INST_LIBDIR)/Stream/Namespace.pm'
			     },
	      'PREREQ_PM' => {
			      'XML::Parser' => 0 
			     },
	      'VERSION'   => '1.10',
	      'dist'      => { 'COMPRESS' => 'gzip --best' }
	     );
