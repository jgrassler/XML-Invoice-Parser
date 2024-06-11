#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'XML::Invoice::Parser' ) || print "Bail out!\n";
}

diag( "Testing XML::Invoice::Parser $XML::Invoice::Parser::VERSION, Perl $], $^X" );
