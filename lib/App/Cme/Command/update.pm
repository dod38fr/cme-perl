# ABSTRACT: Update the configuration of an application

package App::Cme::Command::update ;

use strict;
use warnings;
use 5.10.1;

use App::Cme -command ;

use base qw/App::Cme::Common/;

use Config::Model::ObjTreeScanner;

use Config::Model;

sub validate_args {
    my ($self, $opt, $args) = @_;
    $self->process_args($opt,$args);
}

sub opt_spec {
    my ( $class, $app ) = @_;
    return ( 
        [ "edit!"     => "Run editor after update is done" ],
        [ "backup:s"  => "Create a backup of configuration files before saving." ],
        [ "quiet!"    => "Suppress progress messages" ],
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

    my ( $inst) = $self->instance($opt,$args);

    say "updating data" unless $opt->{quiet};

    my @msgs = $inst->update(quiet => $opt->{quiet});

    if (@msgs and not $opt->{quiet}) {
        say "update done";
    }
    elsif (not $opt->{quiet}) {
        say "command done, but ".$opt->{_application}
            . " model has no provision for update";
    }

    if ($opt->{edit}) {
        say join("\n", grep {defined $_} @msgs );
        $self->run_tk_ui ( $inst->config_root, $opt);
    }
    else {
        $self->save($inst,$opt) ;
        say join("\n", grep {defined $_} @msgs );
    }

}

1;

__END__

=head1 SYNOPSIS

   cme update dpkg-copyright

=head1 DESCRIPTION

Update a configuration file. The update is done scanning external resource. For instance,
the update of dpkg-copyright is done by scanning the headers of source files. (Actually, only
dpkg-copyright model currently supports updates)

Example:

   cme update dpkg-copyright


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
