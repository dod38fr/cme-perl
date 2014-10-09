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
    return << 'EOD'
Edit the configuration with a shell like interface.
This is a shortcut for "cme edit -ui shell" command.
EOD

}

sub execute {
    my ($self, $opt, $args) = @_;

    my ($model, $inst, $root) = $self->init_cme($opt,$args);

    $self->run_shell_ui($root, $inst->application) ;
}

1;

