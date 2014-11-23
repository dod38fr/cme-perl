# ABSTRACT: Update the configuration of an application

package App::Cme::Command::update ;

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
        [ "save!"     => "Force a save even if no change was done" ],
        [ "backup:s"  => "Create a backup of configuration files before saving." ],
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

    say "update data" unless $opt->{quiet};
    my $hook = sub {
        my ($scanner, $data_ref,$node,@element_list) = @_;
        $node->update() if $node->can('update') ;
    };

    Config::Model::ObjTreeScanner->new(
        node_content_hook => $hook,
        leaf_cb => sub { }
    )->scan_node( undef, $root );

    say "update done" unless $opt->{quiet};

    $self->save($inst,$opt) ;
}

1;

__END__

=head1 SYNOPSIS

   cme update dpkg-copyright

=head1 DESCRIPTION

Update a configuration file. The update is done scanning external ressource. For instance,
the update of dpkg-copyright is done by scanning the headers of source files. (Actually, only
dpkg-copyright model currently supports updates)

Example:

   cme update dpkg-copyright


=head1 Common options

See L<App::Cme::Common>.

=head1 options

=over

=item -open-item

Open a specific item of the configuration when opening the editor

=back

=head1 SEE ALSO

L<cme>

=cut
