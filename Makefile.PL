use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	      'NAME'	  => 'XML::Stream',
	      'PM' 	  => {
			      'Stream.pm' => '$(INST_LIBDIR)/Stream.pm',
			      'Stream/Tree.pm' => '$(INST_LIBDIR)/Stream/Tree.pm',
			      'Stream/Hash.pm' => '$(INST_LIBDIR)/Stream/Hash.pm',
			      'Stream/Namespace.pm' => '$(INST_LIBDIR)/Stream/Namespace.pm',
			      'Stream/Parser.pm' => '$(INST_LIBDIR)/Stream/Parser.pm',
			      'Stream/Parser/DTD.pm' => '$(INST_LIBDIR)/Stream/Parser/DTD.pm',
			     },
	      'PREREQ_PM' => {
			      'Unicode::String' => 2.06,
			     },
	      'VERSION'   => '1.14',
	      'dist'      => { 'COMPRESS' => 'gzip --best' }
	     );
