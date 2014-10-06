# ABSTRACT: Dump the configuration of an application

package App::Cme::Command::dump ;
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
        [
            "dumptype=s" => "Dump all values (full) or only preset values or customized values",
            {
                regex => qr/^(?:full|custom|preset)$/,
                required => 1,
                #default => 'custom'
            }
        ],
        $class->global_options,
    );
}

sub usage_desc {
  my ($self) = @_;
  my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
  return "$desc [application]  [ config_file | ~~ ] [ -dumptype full|custom|preset ]";
}

sub description {
    return << "EOD"
Dump configuration content on STDOUT with Config::Model syntax.

By default, dump only custom values, i.e. different from application
built-in values or model default values. You can use the C<-dumptype> option for
other types of dump.
EOD

}

sub execute {
    my ($self, $opt, $args) = @_;

    my ($model, $inst, $root) = $self->init_cme($opt,$args);

    my $dump_string = $root->dump_tree( mode => YYY $opt->{dumptype} );
    print $dump_string ;

}

1;
