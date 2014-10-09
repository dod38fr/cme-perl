# ABSTRACT: List applications handled by cme

package App::Cme::Command::list ;
use strict;
use warnings;
use 5.10.1;

use App::Cme -command ;
use Config::Model::Lister;
use base qw/App::Cme::Common/;


sub opt_spec {
    my ( $class, $app ) = @_;
    return (
        $class->global_options,
    );
}

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

