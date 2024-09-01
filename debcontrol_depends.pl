#!/usr/bin/perl
use strict;
use warnings;

use Dpkg::Control::Info;
use Dpkg::Deps;

my $path=shift;
my $pkg=shift;
my $control = Dpkg::Control::Info->new("$path/debian/control");
my $fields = $control->get_pkg_by_name($pkg);
print join("\n", split(/\s*,\s*/,join(' ', $fields->{'Depends'}))), "\n";
