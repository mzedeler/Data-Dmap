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

{
    my $count = 0;
    my($result) = dmap { if(ref eq 'ARRAY') {$count++; $_ = $object; } $_ } { a => $array, b => $array, c => $array };
    is($count, 1, 'Whitebox test: repeated replacements of same reference are cached.');
    for(qw{a b c}) {
        is(refaddr($result->{$_}), refaddr($object), 'Map from array to object returns the same object every time.');
    }
}

{
    my($result) = dmap { $_ = 2 if not ref; $_ } { thingy => 1 };
    is($result->{thingy}, 2, 'Replacing hash value.');
}

{
    my($result) = dmap { $_ = 2 if not ref; $_ } [ 1 ];
    is($result->[0], 2, 'Replacing array value.');
}

{
    my $a = 1;
    my($result) = dmap { $_ = 2 if ref eq 'SCALAR'; $_ } \$a;
    is($result, 2, 'Replacing SCALAR ref.');
}

{
    my $a = 1;
    my($result) = dmap { $_ = 2 if not ref; $_ } \$a;
    is($$result, 2, 'Replacing value pointed to by scalar ref.');
}

done_testing;
