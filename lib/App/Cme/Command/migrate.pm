# ABSTRACT: Migrate the configuration of an application

package App::Cme::Command::migrate ;

use strict;
use warnings;
use 5.10.1;

use App::Cme -command ;

use base qw/App::Cme::Common/;

use Config::Model::ObjTreeScanner;

sub validate_args {
    my ($self, $opt, $args) = @_;
    $self->process_args($opt,$args);
}

sub opt_spec {
    my ( $class, $app ) = @_;
    return (
        [ "quiet!" => "Suppress progress messages" ],
        $class->cme_global_options,
    );
}

sub usage_desc {
  my ($self) = @_;
  my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
  return "$desc [application] [file | ~~ ]";
}

sub description {
    my ($self) = @_;
    return $self->get_documentation;
}

sub execute {
    my ($self, $opt, $args) = @_;

    my ($model, $inst, $root) = $self->init_cme($opt,$args);

    $root->migrate;

    $self->save($inst,$opt) ;
}

1;

__END__

=head1 SYNOPSIS

  # check dpkg files, update deprecated parameters and save
  cme migrate dpkg

=head1 DESCRIPTION

Checks the content of the configuration file of an application (and show
warnings if needed), update deprecated parameters (old value are saved
to new parameters) and save the new configuration. See L<App::Cme::Command::migrate>.

For more details, see L<Config::Model::Value/Upgrade>

=head1 Common options

See L<cme/"Global Options">.

=head1 SEE ALSO

L<cme>

=cut
