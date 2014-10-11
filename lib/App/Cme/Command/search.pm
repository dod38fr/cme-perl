# ABSTRACT: Search the configuration of an application

package App::Cme::Command::search ;

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
            "search=s"        => "string or pattern to search in configuration" ,
            { required => 1 }
        ],
        [
            "narrow-search=s" => "narrows down the search to element, value, key, summary, description or help",
            { regex => qr/^(?:element|value|key|summary|description|help|all)$/, default => 'all' }
        ],
        $class->global_options,
    );
}

sub usage_desc {
  my ($self) = @_;
  my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
  return "$desc [application]  [ config_file | ~~ ] -search xxx [ -narrow-search ... ] " ;
}

sub description {
    return << 'EOD'
Specifies a string or pattern to search. cme will a list of path pointing
to the matching tree element and their value.

The -narrow_search option narrows down the search to element,
value, key, summary, description or help text.

Example:

 $ cme search multistrap my_mstrap.conf -search http -narrow value
 sections:base source -> 'http://ftp.fr.debian.org'
 sections:debian source -> 'http://ftp.uk.debian.org/debian'
 sections:toolchains source -> 'http://www.emdebian.org/debian'

EOD

}

sub execute {
    my ($self, $opt, $args) = @_;

    my ($model, $inst, $root) = $self->init_cme($opt,$args);

    my @res = $root->tree_searcher( type => $opt->{narrow_search} )->search($opt->{search});
    foreach my $path (@res) {
        print "$path";
        my $obj = $root->grab($path);
        if ( $obj->get_type =~ /leaf|check_list/ ) {
            my $v = $obj->fetch;
            $v = defined $v ? $v : '<undef>';
            print " -> '$v'";
        }
        print "\n";
    }
}

1;

