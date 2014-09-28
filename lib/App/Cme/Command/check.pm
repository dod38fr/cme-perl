# ABSTRACT: Check the configuration of an application

package App::Cme::Command::check ;
use strict;
use warnings;
use 5.10.1;

use App::Cme -command ;

use base qw/App::Cme::Common/;

use Config::Model::ObjTreeScanner;

sub usage_desc {
  my ($self) = @_;
  my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
  return "$desc [application]";
}

sub description {
    return << "EOD"
Checks the content of the configuration file of an application. Prints warnings and errors on STDOUT.

Example:

   cme check fstab

Some applications will allow to override the default configuration file. For instance:

curl http://metadata.ftp-master.debian.org/changelogs/main/f/frozen-bubble/unstable_copyright \
| cme check dpkg-copyright -";
EOD

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

