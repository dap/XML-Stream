use 5.006_001;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'  => 'XML::Stream',
    'PM'   => {
        'Stream.pm' => '$(INST_LIBDIR)/Stream.pm',
        'Stream/Tree.pm' => '$(INST_LIBDIR)/Stream/Tree.pm',
        'Stream/Node.pm' => '$(INST_LIBDIR)/Stream/Node.pm',
        'Stream/Namespace.pm' => '$(INST_LIBDIR)/Stream/Namespace.pm',
        'Stream/Parser.pm' => '$(INST_LIBDIR)/Stream/Parser.pm',
        'Stream/Parser/DTD.pm' => '$(INST_LIBDIR)/Stream/Parser/DTD.pm',
        'Stream/XPath.pm' => '$(INST_LIBDIR)/Stream/XPath.pm',
        'Stream/XPath/Op.pm' => '$(INST_LIBDIR)/Stream/XPath/Op.pm',
        'Stream/XPath/Query.pm' => '$(INST_LIBDIR)/Stream/XPath/Query.pm',
        'Stream/XPath/Value.pm' => '$(INST_LIBDIR)/Stream/XPath/Value.pm',
    },
    'VERSION_FROM' => 'Stream.pm',
    'dist'      => {
        'COMPRESS' => 'gzip --best'
    }
);

