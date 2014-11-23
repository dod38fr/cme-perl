# ABSTRACT: List applications handled by cme

package App::Cme::Command::list ;

use strict;
use warnings;
use 5.10.1;

use App::Cme -command ;
use Config::Model::Lister;

sub description {
    return << "EOD"
Show a list all applications where a model is available. This list depends on
installed Config::Model modules.
EOD

}

sub execute {
    my ($self, $opt, $args) = @_;

    my ( $categories, $appli_info, $appli_map ) = Config::Model::Lister::available_models;
    foreach my $cat ( keys %$categories ) {
        my $names = $categories->{$cat} || [];
        next unless @$names;
        print "$cat:\n  ", join( "\n  ", @$names ), "\n";
    }
}

1;


=head1 SYNOPSIS

 cme list

=head1 DESCRIPTION

Show a list all applications where a model is available. This list depends on
installed Config::Model modules.

=head1 SEE ALSO

L<cme>

=cut
