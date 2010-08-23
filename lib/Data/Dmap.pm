package Data::Dmap;

use warnings;
use strict;
use feature 'switch';
require v5.10;
use Scalar::Util qw{ reftype refaddr };
use Exporter 'import';
our @EXPORT = qw{ dmap };

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
        birds => [ 'cuckatoo', 'ostrich', 'frigate' ]
        handlers => 
    ...

=head1 EXPORT

=over

=item C<dmap> - the dmap function that does deep mapping for you

=back

=head1 SUBROUTINES/METHODS

=head2 C<dmap>

=cut

sub _store_cache {
    my $cache  = shift;
    my $ref    = shift;
    my @values = @_;
    $cache->{refaddr($ref)} = [@values];
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
                my @result = eval { $callback->($orig_ref) };
                foreach my $ref (@result) {
                    my $addr = refaddr $ref;
                    my $type = reftype $ref;
                    given(reftype $_) {
                        when('HASH') {
                            for(keys %$ref) {
                                _dmap($cache, $callback, $ref->{$_});
                            }
                        }
                        when('ARRAY') {
                            map { $_ => _dmap($cache, $callback, $_) } @$ref;
                        }
                        when('SCALAR') {
                            _dmap($cache, $callback, $ref);
                        }
                        default {
                            @result = ($orig_ref);
                        }
                    }
                    _store_cache($cache, $orig_ref, @result);
                }
            } else {
                _get_cache($cache, $_);
            }
        } else {
            @result = $callback->($_);
        }
        @result;
    } @_
}

sub dmap(&@) { _dmap({}, @_) }

=head1 AUTHOR

Michael Zedeler, C<< <"michael@zedeler.dk"> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-dmap at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Dmap>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Dmap


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Dmap>

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
