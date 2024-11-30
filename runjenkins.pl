#!/usr/bin/perl

use strict;
use warnings;
use Regexp::Common;
#use Data::Dumper;

my $bp = $RE{balanced}{-parens=>"[]"};
my $be = $RE{quoted};

my @packages;

sub readjenkinsfile {
  open(my $fh, '<', 'Jenkinsfile') or die $!;
  my $jenkinsfile;
  while(<$fh>){
   $jenkinsfile .= $_;
  }
  close($fh);
 
  if ($jenkinsfile =~ m/pkgList\s*=\s*\[.*?(\[.+?\])\n/s) {
    my $pkglist = $1;
    foreach($pkglist =~ /$bp/g) {
      my $x = $_;
      foreach($x =~ /$bp/g) {
        my %pkg;
        my $p = $_;
        my $varname;
        foreach($p =~ /$be/g) {
          if ($_ eq "''") { next; }
          my $val = $_;
          $val =~ s/^'//;
          $val =~ s/'$//;
          if (defined $varname) {
            $pkg{$varname} = $val;
            $varname = undef;
          } else {
            $varname = $val;
          }
        }
        push(@packages,\%pkg);
      }
    }
  }
}

readjenkinsfile();

if (@packages < 1) { die; }

foreach (@packages) {
  #print Dumper $_;
  if (! defined $_->{'buildCmd'}) { die; }

  if (defined $_->{'scmUrl'}) {
    system('git','clone', $_->{'scmUrl'}, $_->{'name'});
    if ($? != 0) { die; }
    if (defined $_->{'scmCommit'}) {
      system('git', '-C', $_->{'name'},'checkout', $_->{'scmCommit'});
      if ($? != 0) { die; }
    }
  } else {
    if (! -e $_->{'name'} ) { mkdir($_->{'name'}); }
  }

  open(my $cmdfile, '>', "jenkinscmd_" . $_->{'name'} . ".sh") or die $!;
  print $cmdfile "#/bin/sh\nset -e\n\n";
  print $cmdfile "sudo apt-get update\n", '[ -e debian/control ] && sudo mk-build-deps --install --tool "apt-get --yes --no-install-recommends" || true', "\n\n";
  print $cmdfile $_->{'buildCmd'}, "\n";
  close($cmdfile);

  my $pid = fork;
  die "failed to fork: $!" unless defined $pid;

  if ($pid == 0) {
    chdir($_->{'name'}) or die;
    system('sh', '../jenkinscmd_' . $_->{'name'} . ".sh");
    if ($? != 0) { die; }
    exit 0;
  }

  waitpid $pid, 0;
  if ($? != 0) { die; }
}
