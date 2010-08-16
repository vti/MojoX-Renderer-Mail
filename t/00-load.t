#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MojoX::Renderer::Mail::Lite' ) || print "Bail out!
";
}

diag( "Testing MojoX::Renderer::Mail::Lite $MojoX::Renderer::Mail::Lite::VERSION, Perl $], $^X" );
