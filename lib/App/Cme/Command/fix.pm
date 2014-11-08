# ABSTRACT: Fix the configuration of an application

package App::Cme::Command::fix ;

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
        [ "from=s@"  => "fix only a subset of a configuration tree" ],
        [ "filter=s" => "pattern to select the element name to be fixed"],
        $class->global_options,
    );
}

sub usage_desc {
  my ($self) = @_;
  my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
  return "$desc [application] [file | ~~ ]";
}

sub description {
    return << "EOD"
Checks the content of the configuration file of an application (and show
warnings if needed), update deprecated parameters (old value are saved
to new parameters), fix most warnings. The configuration is saved if
anything was changed. If no changes are done, the file is not saved.

Options are:

* from
    Use option "-from" to fix only a subset of a configuration tree.
    Example:

     cme fix dpkg -from 'control binary:foo Depends'

    This option can be repeated:

     cme fix dpkg -from 'control binary:foo Depends' -from 'control source Build-Depends'

* filter
    Filter the leaf according to a pattern. The pattern is applied to
    the element name to be fixed Example:

     # will fix all Build-Depends and Build-Depend-Indep
     cme fix dpkg -from control -filter Build 

    or

     cme fix dpkg -filter Depend

EOD

}

sub execute {
    my ($self, $opt, $args) = @_;

    my ($model, $inst, $root) = $self->init_cme($opt,$args);

    my @fix_from = $opt->{from} ? @{$opt->{from}} : ('') ;

    foreach my $path (@fix_from) {
        my $node_to_fix = $inst->config_root->grab($path);
        my $msg = "Fixing ".$inst->name." configuration";
        $msg .= "from node", $node_to_fix->name if $path;
        say $msg. "..." unless $opt->{quiet};
        $node_to_fix->apply_fixes($opt->{fix_filter});
    }

    $self->save($inst,$opt) ;
}

1;

