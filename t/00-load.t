#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MojoX::Renderer::Mail' ) || print "Bail out!
";
}

diag( "Testing MojoX::Renderer::Mail $MojoX::Renderer::Mail::VERSION, Perl $], $^X" );
