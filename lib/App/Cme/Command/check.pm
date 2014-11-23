# ABSTRACT: Check the configuration of an application

package App::Cme::Command::check ;

use strict;
use warnings;
use 5.10.1;

use App::Cme -command ;

use base qw/App::Cme::Common/;

use Config::Model::ObjTreeScanner;

sub validate_args {
    shift->process_args(@_);
}

sub opt_spec {
    my ( $class, $app ) = @_;
    return ( 
        [ "strict!" => "cme will exit 1 if warnings are found during check" ],
        $class->global_options,
    );
}

sub usage_desc {
  my ($self) = @_;
  my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
  return "$desc [application]  [ config_file | ~~ ]";
}

sub description {
    my ($self) = @_;
    return $self->get_documentation;
}

sub execute {
    my ($self, $opt, $args) = @_;

    my ($model, $inst, $root) = $self->init_cme($opt,$args);

    say "loading data" unless $opt->{quiet};
    Config::Model::ObjTreeScanner->new( leaf_cb => sub { } )->scan_node( undef, $root );
    say "checking data" unless $opt->{quiet};
    $root->dump_tree( mode => 'full' );
    say "check done" unless $opt->{quiet};

    my $ouch = $inst->has_warning;

    if ( $opt->{strict} and $ouch ) {
        die "Found $ouch warnings in strict mode\n";
    }
}

1;

__END__

=head1 SYNOPSIS

 # standard usage
 cme check popcon

 # read data from arbitrary file (with Config::Model::Dpkg)
 cme check dpkg-copyright path/to/file


=head1 DESCRIPTION

Checks the content of the configuration file of an application. Prints warnings
and errors on STDOUT.

Example:

 cme check fstab

Some applications will allow to override the default configuration file. For instance:

  curl http://metadata.ftp-master.debian.org/changelogs/main/f/frozen-bubble/unstable_copyright \
  | cme check dpkg-copyright -

=head1 Common options

See L<App::Cme::Common>.

=head1 options

=over

=item -strict

When set, cme will exit 1 if warnings are found during check (of left after fix)

=back

=head1 SEE ALSO

L<cme>

=cut
