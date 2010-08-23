#!perl -T

use strict;
use warnings;
use Test::More;
use Scalar::Util 'refaddr';

use Data::Dmap;

my $array = [ 1 .. 10 ];
my $hash  = {};
my $code  = sub { }; #dummy
my $object = bless [], 'foobar';

my %types = (
    Array => $array,
    Hash  => $hash,
    Code  => $code,
    Object => $object
);

for(keys %types) {
    my @result = dmap { $_ } 1, $types{$_}, 2;
    is(scalar(@result), 3, 'Trivial map using ' . lc($_). ' returns same number of elements as given.');
    is(refaddr($result[1]), refaddr($types{$_}), $_ . ' address unchanged.');
}

{
    my($result) = dmap { $_ } { a => $array };
    is(scalar(keys %$result), 1, 'Trivial map of hash returns same number of keys.');
    ok(exists $result->{a}, 'Trivial map of hash returns hash with same key.');
    is(refaddr($result->{a}), refaddr($array), 'Trivial map of hash returns array address unchanged.');
}

{
    my($result) = dmap { $_ } { a => $array, b => $array, c => $array };
    is(scalar(keys %$result), 3, 'Trivial map of hash returns same number of keys.');
    for(qw{a b c}) {
        ok(exists $result->{$_}, 'Trivial map of hash returns hash with same key.');
        is(refaddr($result->{$_}), refaddr($array), 'Trivial map of hash returns array address unchanged.');
    }
}

done_testing;
