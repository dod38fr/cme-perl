# ABSTRACT: Edit the configuration of an application with a shell

package App::Cme::Command::shell ;

use strict;
use warnings;
use 5.10.1;

use App::Cme -command ;

use base qw/App::Cme::Common/;

sub validate_args {
    my ($self, $opt, $args) = @_;
    $self->process_args($opt,$args);
}

sub opt_spec {
    my ( $class, $app ) = @_;
    return ( 
        [ "open-item=s" => "open a specific item of the configuration" ],
        $class->global_options,
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

    $self->run_shell_ui($root, $inst->application) ;
}

1;

__END__

=head1 SYNOPSIS

  # simple shell like interface
  cme shell dpkg-copyright

=head1 DESCRIPTION

Edit the configuration with a shell like interface.  See L<Config::Model::TermUI>
for details. This is a shortcut for C<cme edit -ui shell>. See L<App::Cme::Command::shell>.

=head1 Common options

See L<cme/"Global Options">.

=head1 options

=over

=item -open-item

Open a specific item of the configuration when opening the editor

=back

=head1 SEE ALSO

L<cme>

=cut
