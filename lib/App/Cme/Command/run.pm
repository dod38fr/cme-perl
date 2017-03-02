# ABSTRACT: Fix the configuration of an application

package App::Cme::Command::run ;

use strict;
use warnings;
use 5.10.1;
use File::HomeDir;
use Path::Tiny;

use Encode qw(decode_utf8);

use App::Cme -command ;

use base qw/App::Cme::Common/;

my $__test_home = '';
sub _set_test_home { $__test_home = shift; }

my $home = $__test_home || File::HomeDir->my_home;

my @script_locs = (
    "$home/.cme/scripts",
    "/etc/cme/scripts/",
);

sub opt_spec {
    my ( $class, $app ) = @_;
    return ( 
        [ "arg=s@"  => "fix only a subset of a configuration tree" ],
        [ "quiet!"   => "Suppress progress messages" ],
        $class->cme_global_options,
    );
}

sub usage_desc {
  my ($self) = @_;
  my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
  return "$desc [ script ] [ --args foo=12 [ --args bar=13 ]";
}

sub description {
    my ($self) = @_;
    return $self->get_documentation;
}

sub execute {
    my ($self, $opt, $args) = @_;

    # see Debian #839593 and perlunicook(1) section X 13
    @$args = map { decode_utf8($_, 1) } @$args;

    my $script_name = shift @$args;
    my $script;

    if ($script_name =~ m!/!) {
        $script = path($script_name);
    }
    else {
        # check script in known locations
        foreach my $loc ( @script_locs ) {
            my $path = path($loc);
            next unless $path->is_dir;
            $script = $path->child($script_name);
            last if $script->is_file;
        }
    }

    my $content = $script->slurp_utf8;

    # tweak variables
    my %fill_h = map { split '=',$_,2; } @{ $opt->{arg} };
    $content =~ s~ (?<!\\) \$(\w+) ~ $fill_h{$1} // '$'.$1 ~xeg;
    $content =~ s!\\\$!\$!g;

    my @load;
    my $commit_msg ;
    my $line_nb = 0;

    # check content, store app
    foreach my $line ( split /\n/,$content ) {
        $line_nb++;
        $line =~ s/#.*//; # remove comments
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        my ($key,$value) = split /[\s:]+/, $line, 2;

        next unless $key ; # empty line

        if ($key =~ /^app/) {
            unshift @$args, $value;
        }
        elsif ($key eq 'load') {
            push @load, $value;
        }
        elsif ($key eq 'commit') {
            $commit_msg = $value;
        }
        else {
            die "Error in file $script line $line_nb: unexpected '$key' instruction\n";
        }
    }

    $self->process_args($opt, $args);

    # check if workspace and index are clean
    if ($commit_msg) {
        my $r = `git status --porcelain`;
        die "Cannot run commit command in a non clean repo. Please commit or stash pending changes: $r"
            if $r;
    }

    # call loads
    my ($model, $inst, $root) = $self->init_cme($opt,$args);
    map { $root->load($_) } @load;

    $self->save($inst,$opt) ;

    # commit if needed
    if ($commit_msg) {
        system(qw/git commit -a -m/, $commit_msg);
    }

}

1;

__END__

=head1 SYNOPSIS

 $ cat ~/.cme/scripts/remove-mia
 # declare app to configure
 app: dpkg
 # specify one or more instructions
 load: ! control source Uploaders:-~/$mia$/
 # commit the modifications with a message (git only)
 commit: remove MIA dev $mia

 $ cme run remove-mia --arg mia=longgone@d3bian.org

=head1 DESCRIPTION

Run a script using cme DSL (Design specfic language).

When run, this script:

=over

=item *

Open the configuration file of C<app>

=item *

Apply the modifications specified with C<load> instructions

=item *

Save the configuration files.

=item *

Commit the result if C<commit> is specified.

=back

A script passed by name is searched in C<~/.cme/scripts> and in
C</etc/cme/scripts>. (e.g C<cme run foo>)

No search is done if the script is passed with a path 
(e.g. C<cme run ./foo>)

=head1 Syntax

The script accepts instructions in the form:

 key: value

The script accept 3 instructions:

=over

=item app

Specify the target application. Must be one of the application listed
by C<cme list> command. Mandatory. Only one C<app> instruction is
allowed.

=item load

Specify the modifications to apply using a string as specified in
L<Config::Model::Loader>

=item commit

Specify that the change must be commited with the passed commit
message. When this option is used, C<cme> raises an error if used on a
non-clean workspace. This option works only with L<git>.

=back

All instructions can use variables like C<$stuff> and specify
the value with C<cme> options

For instance:

  cme run --arg var1=foo --arg var2=bar

transforms the instruction:

  load: ! a=$var1 b=$var2

in

  load: ! a=foo b=bar

=head1 Options

=head2 arg

Arguments for the cme scripts which are used to substiture variables.

=head1 Common options

See L<cme/"Global Options">.

=head1 Examples

=head2 update copyright years in C<debian/copyright>

 $ cat ~/.cme/scripts/update-copyright
 app: dpkg-copyright
 load: Files:~ Copyright=~"s/2016,?\s+$name/2017, $name/g"
 commit: updated copyright year of $name
 $ cme run update-copyright --arg "name=Dominique Dumont"
 cme: using Dpkg::Copyright model
 Changes applied to dpkg-copyright configuration:
 - Files:"*" Copyright: '2005-2016, Dominique Dumont <dod@debian.org>' -> '2005-2017, Dominique Dumont <dod@debian.org>'
 - Files:"lib/Dpkg/Copyright/Scanner.pm" Copyright:
 @@ -1,2 +1,2 @@
 -2014-2016, Dominique Dumont <dod@debian.org>
 +2014-2017, Dominique Dumont <dod@debian.org>
   2005-2012, Jonas Smedegaard <dr@jones.dk>

 [master ac2e6410] updated copyright year of Dominique Dumont
  1 file changed, 2 insertions(+), 2 deletions(-)

=head1 SEE ALSO

L<cme>

=cut
