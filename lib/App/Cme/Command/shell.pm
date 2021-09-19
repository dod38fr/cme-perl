# ABSTRACT: Edit the configuration of an application with a shell

package App::Cme::Command::shell ;

use strict;
use warnings;
use 5.10.1;

use App::Cme -command ;

use base qw/App::Cme::Common/;

sub validate_args {
    my ($self, $opt, $args) = @_;
    $self->check_unknown_args($args);
    $self->process_args($opt,$args);
    return;
}

sub opt_spec {
    my ( $class, $app ) = @_;
    return ( 
        [ "open-item=s" => "open a specific item of the configuration" ],
        [ "backup:s"  => "Create a backup of configuration files before saving." ],
        [ "bare!"       => "run bare terminal UI"],
        $class->cme_global_options,
    );
}

sub usage_desc {
  my ($self) = @_;
  my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
  return "$desc [application] [file ]";
}

sub description {
    my ($self) = @_;
    return $self->get_documentation;
}

sub execute {
    my ($self, $opt, $args) = @_;

    my ($model, $inst, $root) = $self->init_cme($opt,$args);

    $root->deep_check;

    if ($opt->{bare})  {
        require Config::Model::SimpleUI;
        $self->run_shell_ui('Config::Model::SimpleUI', $inst) ;
    }
    else {
        require Config::Model::TermUI;
        $self->run_shell_ui('Config::Model::TermUI', $inst) ;
    }

    return;
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

=item -bare

Use Term UI without auto-completion or font enhancements.

=back

=head1 SEE ALSO

L<cme>

=cut
