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
    $self->process_args($opt,$args);
    $self->usage_error("No modification instructions given on command line")
        unless @$args or $opt->{save};
}

sub opt_spec {
    my ( $class, $app ) = @_;
    return ( 
        [ "save!"     => "Force a save even if no change was done" ],
        $class->cme_global_options,
    );
}

sub usage_desc {
  my ($self) = @_;
  my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
  return "$desc [application] [file | ~~ ] instructions";
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

  # likewise with an application that accepts file override
  cme modify dpkg-copyright ~~ 'Comment="Modified with cme"'

=head1 DESCRIPTION

Modify a configuration file with the values passed on the command line.
These command must follow the syntax defined in L<Config::Model::Loader>
(which is similar to the output of L<cme dump|"/dump"> command)

Example:

   cme modify dpkg source format="(3.0) quilt"
   cme modify multistrap my_mstrap.conf sections:base source="http://ftp.fr.debian.org"

Some application like dpkg-copyright allows you to override the
configuration file name. The problem is to make the difference between
the overridden file name and the modification instruction you want to
apply.

Either you specify both overridden file name modifications:

   cme modify dpkg-copyright ubuntu/copyright 'Comment="Silly example"

Or you use C<~~> to use the default file name:

   cme modify dpkg-copyright ~~ 'Comment="Another silly example"

Another example which restores the default value of the text of all GPL like licenses :

   cme modify dpkg-copyright ~~ 'License=~/GPL/ text~'

Or update the copyright years of the package maintainer's file:

   cme modify dpkg-copyright ~~ 'File=debian/* Copyright=~s/2013/2014/'

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
