use 5.008_000;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
	module_name       => 'XML::Stream',
	dist_author       => 'Darian Anthony Patrick <dapatrick@cpan.org>',
	dist_version_from => 'lib/XML/Stream.pm',
	requires => {
		'perl'          => 'v5.8.0',
		'Authen::SASL'  => 0,
		'Carp'          => 0,
		'Encode'        => 0,
		'FileHandle'    => 0,
		'IO::Select'    => 0,
		'IO::Socket'    => 0,
		'MIME::Base64'  => 0,
		'POSIX'         => 0,
		'Sys::Hostname' => 0,
		'utf8'          => 0,
	},

	configure_requires => {
		'Module::Build' => '0.360300',
	},

	build_requires => {
		'Test::More'    => '0.92',
	},

	sign               => 1,
	license            => 'lgpl',
	create_makefile_pl => 'traditional',
	meta_merge => {
		'resources' => {
			'bugtracker' => 'https://rt.cpan.org/Dist/Display.html?Queue=XML-Stream',
			'repository' => 'http://github.com/dap/XML-Stream',
		}
	},
);

$build->create_build_script;
