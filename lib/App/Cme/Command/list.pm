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
installed Config::Model modules. Applications are divided in 3 categories:
- system: for system wide applications (e.g. daemon like sshd)
- user: for user applications (e.g. ssh configuration)
- application: misc application like Debian packaging
EOD
}

sub opt_spec {
    my ( $class, $app ) = @_;
    return (
        [ "dev!"               => "list includes a model under development"],
    );
}

my %help = (
    system => "system configuration files. Use sudo to run cme",
    user => "user configuration files",
    application => "miscellaneous application configuration",
);

sub execute {
    my ($self, $opt, $args) = @_;

    my ( $categories, $appli_info, $appli_map ) = Config::Model::Lister::available_models($opt->dev());
    foreach my $cat ( qw/system user application/ ) {
        my $names = $categories->{$cat} || [];
        next unless @$names;
        print $cat," ( ",$help{$cat}," ):\n  ", join( "\n  ", @$names ), "\n";
    }
    return;
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
