# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
use strict;

use vars qw($Total_tests);

my $loaded;
my $test_num = 1;
BEGIN { $| = 1; $^W = 1; }
END {print "not ok $test_num\n" unless $loaded;}
print "1..$Total_tests\n";
use Class::Virtually::Abstract;
$loaded = 1;
ok(1, 'compile');
######################### End of black magic.

# Utility testing functions.
sub ok {
    my($test, $name) = @_;
    print "not " unless $test;
    print "ok $test_num";
    print " - $name" if defined $name;
    print "\n";
    $test_num++;
}

sub eqarray  {
    my($a1, $a2) = @_;
    return 0 unless @$a1 == @$a2;
    my $ok = 1;
    for (0..$#{$a1}) {
        my($e1,$e2) = ($a1->[$_], $a2->[$_]);
        unless($e1 eq $e2) {
            if( UNIVERSAL::isa($e1, 'ARRAY') and 
                UNIVERSAL::isa($e2, 'ARRAY') ) 
            {
                $ok = eqarray($e1, $e2);
            }
            else {
                $ok = 0;
            }
            last unless $ok;
        }
    }
    return $ok;
}

# Change this to your # of ok() calls + 1
BEGIN { $Total_tests = 16 }

my @vmeths = qw(new foo bar this that);
my $ok;

package Test::Virtual;
use base qw(Class::Virtually::Abstract);
__PACKAGE__->virtual_methods(@vmeths);

::ok( ::eqarray([sort __PACKAGE__->virtual_methods], [sort @vmeths]),
    'Declaring virtual methods' );

eval {
    __PACKAGE__->virtual_methods(qw(this wont work));
};
$ok = $@ =~ /^Attempt to reset virtual methods/;
::ok( $ok,        "Disallow reseting by virtual class" );


package Test::This;
use base qw(Test::Virtual);

::ok( ::eqarray([sort __PACKAGE__->virtual_methods], [sort @vmeths]),
    'Subclass listing virtual methods');
::ok( ::eqarray([sort __PACKAGE__->missing_methods], [sort @vmeths]),
    'Subclass listing missing methods');

*foo = sub { 42 };
*bar = sub { 23 };

::ok( defined &foo && defined &bar );

::ok( ::eqarray([sort __PACKAGE__->missing_methods], [sort qw(new this that)]),
      'Subclass handling some methods');

eval {
    __PACKAGE__->virtual_methods(qw(this wont work));
};
$ok = $@ =~ /^Attempt to reset virtual methods/;
::ok( $ok,        "Disallow reseting by subclass" );


package Test::Virtual::Again;
use base qw(Class::Virtually::Abstract);
__PACKAGE__->virtual_methods('bing');

package Test::Again;
use base qw(Test::Virtual::Again);
::ok( ::eqarray([sort __PACKAGE__->virtual_methods], [sort qw(bing)] ),
      'Virtual classes not interfering' );
::ok( ::eqarray([sort __PACKAGE__->missing_methods], [sort qw(bing)] ),
      'Missing methods not interfering' );

::ok( ::eqarray([sort Test::This->virtual_methods], [sort @vmeths]),
      'Not overwriting virtual methods');
::ok( ::eqarray([sort Test::This->missing_methods], [sort qw(new this that)]),
      'Not overwriting missing methods');

eval {
    Test::This->new;
};
::ok( $@ =~ /^Test::This forgot to implement new\(\) at/,
      'virtual method unimplemented, ok');

eval {
    Test::This->bing;
};
::ok( $@ =~ /^Can't locate object method "bing" via package "Test::This" at/,
      'virtual methods not leaking');   #')


eval {
    Test::Again->import;
};
::ok( $@ =~ /^Class Test::Again must define bing for class Test::Virtual::Again/ );

package Test::More;
use base qw(Test::Again);
sub import { 42 }

eval {
    Test::More->import;
};
# ::ok( $@ =~ /^Class Test::More must define bing for class Test::Virtual::Again/ );  # TODO



package Test::Yet::Again;
use base qw(Class::Virtually::Abstract);
__PACKAGE__->virtual_methods('foo');

sub import {
    $Test::Yet::Again = 42;
}


package Test::Yet;
use base qw(Test::Yet::Again);

sub foo { 23 }

eval {
    Test::Yet->import;
};
::ok( !$@ and $Test::Yet::Again == 42 );