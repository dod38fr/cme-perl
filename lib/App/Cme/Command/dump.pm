# ABSTRACT: Dump the configuration of an application

package App::Cme::Command::dump ;

use strict;
use warnings;
use 5.10.1;

use App::Cme -command ;

use base qw/App::Cme::Common/;

use Config::Model::ObjTreeScanner;
use YAML;
use JSON;
use Data::Dumper;

sub validate_args {
    shift->process_args(@_);
}

sub opt_spec {
    my ( $class, $app ) = @_;
    return ( 
        [
            "dumptype=s" => "Dump all values (full) or only preset values or customized values",
            {
                regex => qr/^(?:full|custom|preset)$/,
                default => 'custom'
            }
        ],
        [
            "format=s" => "dump using specified format",
            {
                regex => qr/^(?:json|yaml|perl|cml)$/,
                default => 'yaml'
            },
        ],
        $class->cme_global_options,
    );
}

sub usage_desc {
  my ($self) = @_;
  my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
  return "$desc [application]  [ config_file | ~~ ] [ -dumptype full|custom|preset ] [ path ]";
}

sub description {
    my ($self) = @_;
    return $self->get_documentation;
}

sub execute {
    my ($self, $opt, $args) = @_;

    my ($model, $inst, $root) = $self->init_cme($opt,$args);

    my $target_node = $root->grab(step => "@$args", type => 'node');

    my $dump_string;
    my $format = $opt->{format};
    if ($format eq 'cml') {
        $dump_string = $target_node->dump_tree( mode => $opt->{dumptype} );
    }
    else {
        my $perl_data = $target_node->dump_as_data( ordered_hash_as_list => 0);
        $dump_string = $format eq 'yaml' ? Dump($perl_data)
            : $format eq 'JSON' ? encode_json($perl_data)
            :                     Dumper($perl_data) ;
    }
    print $dump_string ;

}

1;

__END__

=head1 SYNOPSIS

  # dump ~/.ssh/config in cme syntax
  # (this example requires Config::Model::OpenSsh)
  $ cme dump -format cml ssh
  Host:"*" -
  Host:"*.debian.org"
    User=dod -


=head1 DESCRIPTION

Dump configuration content on STDOUT with YAML format.

By default, dump only custom values, i.e. different from application
built-in values or model default values. You can use the C<-dumptype> option for
other types of dump:

 -dumptype [ full | preset | custom ]

Choose to dump every values (full), only preset values or only
customized values (default)

By default, dump in yaml format. This can be changed in C<JSON>,
C<Perl>, C<cml> (aka L<Config::Model::Loader> format).

=head1 Common options

See L<cme/"Global Options">.

=head1 SEE ALSO

L<cme>

=cut
