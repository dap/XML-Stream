use 5.008_000;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'             => 'XML::Stream',
    'VERSION_FROM'     => 'lib/XML/Stream.pm',
    'ABSTRACT_FROM'    => 'lib/XML/Stream.pm',
    'AUTHOR'           => 'Darian Anthony Patrick <dapatrick@cpan.org>',
    'LICENSE'          => 'LGPL',
    'MIN_PERL_VERSION' => '5.008',
    'PREREQ_PM'        => {
        'Authen::SASL'  => 0,
        'MIME::Base64'  => 0,
        'Sys::Hostname' => 0,
        'IO::Socket'    => 0,
        'IO::Select'    => 0,
        'FileHandle'    => 0,
        'Carp'          => 0,
        'POSIX'         => 0,
        'utf8'          => 0,
        'Encode'        => 0,
    },
    'META_MERGE'       => {
        'resources' => {
            'bugtracker' => 'https://rt.cpan.org/Dist/Display.html?Queue=XML-Stream',
            'repository' => 'http://github.com/dap/XML-Stream',
        }
    }
);

