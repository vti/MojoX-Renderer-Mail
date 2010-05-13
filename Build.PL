use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'MojoX::Renderer::Mail',
	license             => 'perl',
	dist_author         => 'Anatoly Sharifulin <sharifulin@gmail.com>',
	dist_version_from   => 'lib/MojoX/Renderer/Mail.pm',
	dist_abstract       => 'Mail renderer for Mojo and Mojolicious, uses MIME::Lite',
	build_requires => {
		'Test::More' => 0,
	},
	requires => {
		'Encode'         => 0,
		'MIME::Lite'     => 0,
		'MIME::EncWords' => 0,
	},
	add_to_cleanup  => [],
	meta_merge => {
		resources => {
			repository => 'git://github.com/sharifulin/MojoX-Renderer-Mail.git',
		},
		keywords => ['mojo', 'mojolicious', 'mime', 'mail', 'renderer'],
	},
	create_makefile_pl => 'traditional',
);

$builder->create_build_script();
