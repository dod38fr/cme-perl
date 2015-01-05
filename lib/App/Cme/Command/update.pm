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
        [ "edit!"     => "Run editor after update is done" ],
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

    my ( $inst) = $self->instance($opt,$args);

    say "updating data" unless $opt->{quiet};
    my @msg ;
    my $hook = sub {
        my ($scanner, $data_ref,$node,@element_list) = @_;
        if ($node->can('update')) {
            say "Calling update on ",$node->name, ' ',$node->config_class_name, " $node"
                unless $opt->{quiet};
            push (@msg, $node->update())
        } ;
    };

    my $root = $inst->config_root ;

    Config::Model::ObjTreeScanner->new(
        node_content_hook => $hook,
        leaf_cb => sub { }
    )->scan_node( \@msg, $root );

    if (@msg and not $opt->{quiet}) {
        say "update done";
        say join("\n", grep {defined $_} @msg );
    }
    elsif (not $opt->{quiet}) {
        say "command done, but model has no provision for update";
    }

    if ($opt->{edit}) {
        $self ->run_tk_ui ( $root, $opt);
    }
    $self->save($inst,$opt) ;
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
