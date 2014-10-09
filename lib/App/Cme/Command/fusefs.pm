# ABSTRACT: Edit the configuration of an application with fuse

package App::Cme::Command::fusefs ;
use strict;
use warnings;
use 5.10.1;

use App::Cme -command ;

use base qw/App::Cme::Common/;

use Config::Model::ObjTreeScanner;

sub validate_args {
    my ($self, $opt, $args) = @_;
    $self->process_args($opt,$args);

    eval { require Config::Model::FuseUI; };
    my $has_fuse = $@ ? 0 : 1;

    die "could not load Config::Model::FuseUI. Is Fuse installed ?\n"
        unless $has_fuse;

    my $fd = $opt->{fuse_dir};
    die "Directory $fd does not exists\n" unless -d $fd;

}

sub opt_spec {
    my ( $class, $app ) = @_;
    return (
        [
            "fuse-dir=s" =>  "Directory where the virtual file system will be mounted",
            {required => 1}
        ],
        [ "dfuse!" => "debug fuse problems" ],
        [ "dir-char=s" => "string to replace '/' in configuration parameter names"],
        $class->global_options,
    );
}

sub usage_desc {
  my ($self) = @_;
  my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
  return "$desc [application] [file | ~~ ] -fuse-dir xxx [ -dir-char x ] ";
}

sub description {
    return << 'EOD'
Map the configuration file content to a FUSE virtual file system on a
directory specified with option "-fuse-dir". To stop (and write the
configuration data back to the configuration file), run 

 fusermount -u <mounted_fuse_dir>

Options:

-fuse-dir
    Mandatory. Directory where the virtual file system will be mounted.

-dfuse
    Use this option to debug fuse problems.

-dir-char
    Fuse will fail if an element name or key name contains '/'. You can
    specify a subsitution string to replace '/' in the fused dir.
    Default is "<slash>".
EOD

}

sub execute {
    my ($self, $opt, $args) = @_;

    my ($model, $inst, $root) = $self->init_cme($opt,$args);

    my @extra;
    if (my $dc = $opt->{dir_char}) {
        push @extra, dir_char_mockup => $dc;
    }

    my $fuse_dir = $opt->{fuse_dir};
    print "Mounting config on $fuse_dir in background.\n",
        "Use command 'fusermount -u $fuse_dir' to unmount\n";

    my $ui = Config::Model::FuseUI->new(
        root       => $root,
        mountpoint => $fuse_dir,
        @extra,
    );


    # now fork
    my $pid = fork;

    if ( defined $pid and $pid == 0 ) {
        # child process, just run fuse and wait for exit
        $ui->run_loop( debug => $opt->{fuse_debug} );
        $self->save($inst,$opt);
    }

    # parent process simply exits
}

1;

