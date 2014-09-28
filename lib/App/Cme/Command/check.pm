package App::Cme::Command::check ;
use strict;
use warnings;
use 5.10.1;

use App::Cme -command ;

use base qw/App::Cme::Common/;

use Config::Model::ObjTreeScanner;

sub opt_spec {
  return ();
}

sub execute {
    my ($self, $opt, $args) = @_;

    my ($model, $inst) = $self->init_cme($opt,$args);
    my $root = $inst->config_root;

    say "loading data";
    Config::Model::ObjTreeScanner->new( leaf_cb => sub { } )->scan_node( undef, $root );
    say "checking data";
    $root->dump_tree( mode => 'full' );
    say "check done";
}

1;
