package Data::Dmap;

use warnings;
use strict;
require v5.10;
use feature 'switch';
use Carp 'croak';
use Exporter 'import';
our @EXPORT = qw{ dmap };
use Scalar::Util qw{ reftype refaddr };

=head1 NAME

Data::Dmap - just like map, but on deep data structures

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module provides the single function C<dmap> which carries out a
C<map>-like operation on deep data structures.

    use Data::Dmap;

    my $foo = {
        cars => [ 'ford', 'opel', 'BMW' ],
        birds => [ 'cuckatoo', 'ostrich', 'frigate' ],
        handler => sub { print "barf\n" }
    };

    # This removes all keys named 'cars'    
    my($bar) = dmap { delete $_->{cars} if ref eq 'HASH'; $_ } $foo;

    # This replaces arrays with the number of elements they contains
    my($other) = dmap { $_ = scalar @$_ if ref eq 'ARRAY'; $_ } $foo;

    use Data::Dumper;
    print Dumper $other;
    #
    # Prints
    # {
    #    birds => 3,
    #    handler => sub { "DUMMY" }
    # }
    # (Data::Dumper doesn't dump subs)

    $other->{handler}->();
    # Prints
    # barf

=head1 EXPORT

=over

=item C<dmap> - the dmap function that does deep in-place mapping

=back

=head1 SUBROUTINES/METHODS

=head2 C<dmap>

=cut

sub _store_cache {
    my $cache  = shift;
    my $ref    = shift;
    $cache->{refaddr($ref)} = [@_];
}

sub _get_cache {
    my $cache = shift;
    my $ref   = shift;
    @{$cache->{refaddr($ref)}};
}

sub _has_cache {
    my $cache = shift;
    my $ref   = shift;
    exists $cache->{refaddr($ref)};
}

sub _dmap {
    my $cache = shift;
    my $callback = shift;
    map {
        my @result;
        if(ref) {
            my $orig_ref = $_;
            if(not _has_cache($cache, $orig_ref)) {
                my @mapped = $callback->($orig_ref);
                foreach my $val (@mapped) {
                    given(reftype $val) {
                        when('HASH') {
                            for(keys %$val) {
                                my @res = _dmap($cache, $callback, $val->{$_});
                                croak 'Multi value return in hash value assignment'
                                    if @res > 1;
                                $val->{$_} = $res[0] if @res;
                            }
                            push @result, $val;
                        }
                        when('ARRAY') {
                            for(0 .. $#$val) {
                                if(exists $val->[$_]) {
                                    # TODO Use splice to allow multi-value returns
                                    my @res = _dmap($cache, $callback, $val->[$_]);
                                    croak 'Multi value return in array single value assignment'
                                        if @res > 1;
                                    $val->[$_] = $res[0] if @res;
                                }
                            }
                            push @result, $val;
                        }
                        when('SCALAR') {
                            my @res = _dmap($cache, $callback, $$val);
                            croak 'Multi value return in single value assignment'
                                if @res > 1;
                            $$val = $res[0] if @res;
                        }
                        default {
                            push @result, $val;
                        }
                    }
                }
                _store_cache($cache, $orig_ref, @result);
            } else {
                push @result, _get_cache($cache, $_);
            }
        } else {
            @result = $callback->($_);
        }
        @result;
    } @_
}

# Stub that inserts empty map cache
sub dmap(&@) { _dmap({}, @_) }

=head1 AUTHOR

Michael Zedeler, C<< <"michael@zedeler.dk"> >>

=head1 BUGS

If you find a bug, please consider helping to fix the bug by doing this:

=over

=item Fork C<Data::Dmap> from L<http://github.com/mzedeler/Data-Dmap>

=item Write a test case in the C<t> directory, commit and push it.

=item Fix the bug or (if you don't know how to fix it), report the bug

=back

Bugs and feature requests can be reported through the web interface at
L<http://github.com/mzedeler/Data-Dmap/issues>. I may not be notified, so send
me a mail too.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Dmap

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://github.com/mzedeler/Data-Dmap/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Dmap>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Dmap>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Dmap/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 "Michael Zedeler".

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Data::Dmap
