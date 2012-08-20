#!/usr/bin/env perl
use strict;

my $debug = 0;
my $login = 1;
my ($output);
my $orig_path ;

$ENV{PHP_EXE} = '/sw/st/gnu_compil/gnu/Linux-RH-WS-3/bin/php';
$ENV{CODEX_SCRIPT} = '/sw/st/gnu_compil/comp/scripts/codex_cli/codendi.php';

BEGIN {
  use File::Basename qw(dirname);
  use Cwd qw(abs_path);
  $orig_path = abs_path();
  my $path = dirname(abs_path($0));
  @INC = (@INC,$path);
}


# Import packages
use Codex;
use File::Basename;
use Getopt::Long;

Getopt::Long::config(qw(no_ignore_case));

my $opt_prj=undef;
my $opt_rel=undef;
my $opt_pkg=undef;
my $opt_file=undef;
my $opt_add=undef;
my $opt_get=undef;
my $opt_list=undef;
my $opt_binopt=undef;
my $opt_xp70=undef;
my $opt_dir=$orig_path;

usage() unless GetOptions(
			  'v|verbose'   => \$debug,
			  'prj|project=s' => \$opt_prj,
			  'rel|release=s' => \$opt_rel,
			  'pkg|package=s' => \$opt_pkg,
			  'f|file=s' => \$opt_file,
              'd|dir=s' => \$opt_dir,
			  'add'   => \$opt_add,
			  'get'   => \$opt_get,
			  'list'   => \$opt_list,
              'binopt' => \$opt_binopt,
              'xp70' => \$opt_xp70,
			  );

sub codex_login 
{
  my ($prj) = @_;
  my ($out);
  if(!(Codex::set_login(undef, undef, 1) && Codex::login($prj, \$out))) {
    die "Codex login failed:$out\n";
  }
}

sub list_files 
{
  my ($prj, $pkg, $rel) = @_;
  Codex::execCli("frs getFiles --package_id=$pkg --project=$prj --release_id=$rel ", \$output) 
  or die "cannot exec codex command";
  return $output;
}

sub list_rel 
{
  my ($prj, $pkg) = @_;
  Codex::execCli("frs getReleases --package_id=$pkg --project=$prj  ", \$output) 
  or die "cannot exec codex command";
  return $output;
}

sub list_pkg
{
  my ($prj) = @_;
  Codex::execCli("frs getPackages --project=$prj  ", \$output) 
  or die "cannot exec codex command";
  return $output;
}


sub add_file {
  my ($pkg, $rel, $file) = @_;
  Codex::execCli("frs addFile --package_id=$pkg --release_id=$rel --local_file=$file", \$output) 
  or die "cannot exec codex command";
  return $output;
}

sub get_file {
  my ($prj, $pkg, $rel, $id, $file, $dir) = @_;
  my $my_dir=$dir . "/" . $file ;
  Codex::execCli("frs getFile --project=$prj --package_id=$pkg --release_id=$rel --file_id=$id --output=$my_dir", \$output) 
  or die "cannot exec codex command";
  return $output;
}

sub usage {
  print "usage : " . basename($0) . "command...\n"
      .	" where:\n"
      .	" command...   :the command and arguments to execute. No shell interpretation is done in this form.\n"
      .	"\n" ;
  exit(1);
}

sub error {
  my ($msg) = @_;
  print "ERROR: $msg \n";
  exit(1);
}  

sub read_cli_line
{
  my ($line) = @_;
  return () if (!($line =~ /^\|/));
  $line =~ s/\s*\|\s*/\|/g;
  my @cells = split(/\|/, $line);
  # Remove leading empty cell
  shift @cells;
  # Some cells may be undefined
  return \@cells;
}

sub table_print
{
  my ($table) = @_;
  foreach my $line (@$table) {
    print join(" ", @$line) . "\n";
  }
}


sub find_row_id
{
  my ($table,$id) = @_;
  my $i=0;
  foreach my $line (@$table) {
    return $i if join(" ", @$line) =~ /$id/ ;
    $i++;
  }
  error ("File $id undifined");
}

sub find_col_id
{
  my ($table,$id) = @_;
  my $i=0;
  my ($line) = $table->[0];
  foreach my $cell (@$line) {
    return $i if $cell eq $id ;
    $i++
  }
  error("Do not find $id");
}


#######################################################
#
# Main Function
#
#######################################################

#Codex::execCli("frs addPackage --project=$this->{'project_name'} --name=\"Performance results\" ", \$output) 



my ($output);
my $this = { 'project_id'=> 827, 'project_name' => "stxp70valid", 'aci_dep' => 3723, 'binopt' => 13055, 'xp70' => 13035 };
my @table;
my $row_index=0;
my $col_index=0;
if (!defined($opt_prj)) {
    $opt_prj=$this->{'project_name'};
}

if (defined($opt_binopt)) {
  $opt_pkg=$this->{'aci_dep'};
  $opt_rel=$this->{'binopt'};
}

if (defined($opt_xp70)) {
  $opt_pkg=$this->{'aci_dep'};
  $opt_rel=$this->{'xp70'};
}


if ($login) {codex_login($this->{'project_name'});}


#### get files ####
if (defined($opt_get)) {
  if (defined($opt_list) || defined($opt_add)) {
    usage();
  }
  if (!defined($opt_rel)  || !defined($opt_pkg) || !defined($opt_file)) {
    error("Unable to proceed list file");
  }
  #get the file table
  $output = list_files($opt_prj,$opt_pkg,$opt_rel);
  print $output if ($debug > 1);
  my @lines = split(/\n/, $output);
  print @lines if ($debug > 1);
  my $i = 0;
  foreach my $line (@lines) {
    push @table, read_cli_line($line);
  }
  table_print(\@table) if ($debug > 1);
  #find the correct row  col
  my $row_index = find_row_id(\@table, $opt_file);
  my $col_index = find_col_id(\@table, "file_id");
  my $file_id=@table->[$row_index][$col_index] ;
  print "Row=$row_index Column=$col_index File ID=$file_id\n" if ($debug > 1);
  $output = get_file($opt_prj, $opt_pkg,$opt_rel,$file_id,$opt_file,$opt_dir);
  print $output;
 
}


#### Add files ####
if (defined($opt_add)) {
    if (defined($opt_list) || defined($opt_get)) {
        usage();
    }
    if (! -r $opt_file) {
       #if (-r $orig_path.'/'.$opt_file) {$opt_file = join}
       error("Bad file name: $orig_path  $opt_file") ;
    }
    print "File to add: $opt_file\n" if $debug;
    if (!defined($opt_rel) || !defined($opt_pkg)) {
        usage();
    }
    $output = add_file($opt_pkg,$opt_rel,$opt_file);
    print $output;
   
} 

#### List files ####
if (defined($opt_list)) {
    if (defined($opt_add) || defined($opt_get)) {
        usage();
    }
    if (!defined($opt_rel) && !defined($opt_pkg)) {
      $output = list_pkg($opt_prj);
      print $output;
    }
    if (!defined($opt_rel) && defined($opt_pkg))  {
      $output = list_rel($opt_prj,$opt_pkg);
      print $output;
    }
    if (defined($opt_rel) && defined($opt_pkg))   {
      $output = list_files($opt_prj,$opt_pkg,$opt_rel);
      print $output;
    }
} 

exit 0;
