use 5.006_001;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'  => 'XML::Stream',
    'VERSION_FROM' => 'lib/XML/Stream.pm',
    'dist'      => {
        'COMPRESS' => 'gzip --best'
    }
);

