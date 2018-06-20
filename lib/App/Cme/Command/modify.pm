# ABSTRACT: Modify the configuration of an application

package App::Cme::Command::modify ;

use strict;
use warnings;
use 5.10.1;

use App::Cme -command ;

use base qw/App::Cme::Common/;

use Config::Model::ObjTreeScanner;

sub validate_args {
    my ($self, $opt, $args) = @_;
    $self->check_unknown_args($args);
    $self->process_args($opt,$args);
    $self->usage_error("No modification instructions given on command line")
        unless @$args or $opt->{save};
}

sub opt_spec {
    my ( $class, $app ) = @_;
    return ( 
        [ "backup:s"  => "Create a backup of configuration files before saving." ],
        $class->cme_global_options,
    );
}

sub usage_desc {
  my ($self) = @_;
  my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
  return "$desc [application] [file ] instructions";
}

sub description {
    my ($self) = @_;
    return $self->get_documentation;
}

sub execute {
    my ($self, $opt, $args) = @_;

    my ($model, $inst, $root) = $self->init_cme($opt,$args);

    # needed to create write_back subs
    $root->dump_tree() if $opt->{save} and not @$args;

    $root->load("@$args");

    $root->deep_check; # consistency check

    $self->save($inst,$opt) ;
}

1;

__END__

=head1 SYNOPSIS

  # modify configuration with command line
  cme modify dpkg source 'format="(3.0) quilt"'

=head1 DESCRIPTION

Modify a configuration file with the values passed on the command line.
These command must follow the syntax defined in L<Config::Model::Loader>
(which is similar to the output of L<cme dump|"/dump"> command)

Example:

   cme modify dpkg 'source format="(3.0) quilt"'
   cme modify multistrap my_mstrap.conf 'sections:base source="http://ftp.fr.debian.org"'

Some application like dpkg-copyright allows you to override the
configuration file name. You must then use C<-file> option:

   cme modify dpkg-copyright -file ubuntu/copyright 'Comment="Silly example"'

=head1 Common options

See L<cme/"Global Options">.

=head1 options

=over

=item -save

Force a save even if no change was done. Useful to reformat the configuration file.

=back

=head1 SEE ALSO

L<cme>

=cut
