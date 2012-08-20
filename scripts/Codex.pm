package Codex;

use strict;
use warnings;

our $configFile = $ENV{'HOME'}.'/.codex/config.pl';
our $charPathSeparator = '/';
our $login;
our $password;

$ENV{PHP_EXE} = '/sw/st/gnu_compil/gnu/Linux-RH-WS-3/bin/php';
$ENV{CODEX_SCRIPT} = '/sw/st/gnu_compil/comp/scripts/codex_cli/codendi.php';

our $phpEnvVar = 'PHP_EXE';
our $phpPath = $ENV{$phpEnvVar};
our $scriptEnvVar = 'CODEX_SCRIPT';
our $script = $ENV{$scriptEnvVar};

my $debugCodex = $ENV{'DEBUG_CODEX'};
our $g_project;

sub getInfo
{
  my $msg = shift;
  my $hideInput = shift;
  my $input;

  if($hideInput)
    {
      system("stty -echo");
    }
  print $msg;
  chomp($input = <STDIN>);

  if($hideInput)
    {
      system("stty echo");
    }
  return $input;
}

sub set_php
{
  my $result = '';
  if($phpPath)
    {
      if(-x $phpPath)
        {
          $result = "$phpPath -q";
        }
    }
  else
    {
      if(system("php -v 1> /dev/null 2>&1") == 0)
        {
          $result = 'php -q';
        }
      elsif(-x '/sw/st/gnu_compil/gnu/linux-rh-ws-3/bin/php')
        {
          $result = '/sw/st/gnu_compil/gnu/linux-rh-ws-3/bin/php -q';
        }
    }
  return $result;
}

sub execCli
{
  my $args = shift;
  my $refOutput = shift;
  my $result = 0;

  undef $$refOutput;

  my $php = set_php();
  if($php && -f $script)
    {
      $$refOutput = `$php $script $args 2>&1`;
      $result = $? == 0;
      if($debugCodex)
        {
          print "Codex cmd: '$php $script $args'\n";
        }
      if(!$result)
        {
          $$refOutput = "Executed command: '$php $script $args'\n$$refOutput";
        }
    }
  else
    {
      $$refOutput = "Unable to find php or codex script.\n".
        "You can specify these values with respectivly '$phpEnvVar' and ".
          "'$scriptEnvVar' environment variables";
    }
  return $result;
}

sub execCliFromHash
{
  my $refAction = shift;
  my $refHash = shift;
  my $refOutput = shift;
  my $cmd = '';
  # workaround for codex bug #28837
  $$refHash{'project'} = $g_project;

  foreach my $action (@$refAction)
    {
      $cmd .= "$action ";
    }

  foreach my $key (keys(%$refHash))
    {
      $cmd .= "--$key";
      # Note: to have this pattern (key defined and value not defined), one has
      # to specify the related map entry like: $$refHash{$key} = undef;
      if(defined $$refHash{$key})
        {
          $cmd .= "='$$refHash{$key}'";
        }
      $cmd .= ' ';
    }
  return execCli($cmd, $refOutput);
}

sub set_login
{
  $login = shift;
  $password = shift;
  my $interactive = shift;

  # information is missing and we cannot ask for it
  if((!$login || !$password) && ! -f $configFile && !$interactive)
    {
      return 0;
    }

  my $overrideValue = 0;
  # if one of this information is set, we assume we want to override config
  # file values
  if(!$login && ! -f $configFile)
    {
      $login = getInfo("Enter Login (LDAP login): ", 0);
      return 0 if !defined($login) or $login eq "";
      $overrideValue = 1;
    }
  if(!$password && ! -f $configFile)
    {
      $password = getInfo("Enter Password (LDAP password): ", 1);
      print "\n";
      return 0 if !defined($login) or $login eq "";
      $overrideValue = 1;
    }

  if((! -f $configFile) || $overrideValue)
    {
      my $dirname = $configFile;
      $dirname =~ s|[^$charPathSeparator]*$||;
      my $curPath = '';
      foreach my $dir (split($charPathSeparator, $dirname))
        {
          if($dir)
            {
              $curPath .= "/$dir";
              if(! -d $curPath)
                {
                  mkdir($curPath, 0700) or die("Unable to create '$curPath'");
                }
            }
        }
      open(CONFFILE, ">$configFile") or die("Unable to open '$configFile' for"
                                            ." writing");
      chmod(0600, $configFile);
      print CONFFILE "\$login='$login'\n";
      print CONFFILE "\$password='$password'\n";
      close(CONFFILE);
    }
  return 1;
}

sub login
{
  my $project = shift;
  my $refOutput = shift;
  my $line;
  $g_project = $project;
  open(CONFFILE, "<$configFile") or die("Unable to open '$configFile' for "
                                        ."input");
  while($line = <CONFFILE>)
    {
      eval $line;
      warn $@ if $@;
    }
  close(CONFFILE);

  my $result = execCli("login --username='$login' --password='$password' ".
                       "--project='$project'", $refOutput);

  $result = 0 if ($result && $$refOutput =~ /error/);

  if(!$result && -f $configFile)
    {
      # login failed, maybe config file is wrong (should check output, before
      # removing)
      unlink("$configFile");
    }
  return $result;
}

sub logout
{
  my $refOutput = shift;
  $g_project = undef;
  return execCli('logout', $refOutput);
}

sub update
{
  my $refHash = shift;
  my $refOutput = shift;
  my @actions = ('tracker', 'update', '--noask');
  return execCliFromHash(\@actions, $refHash, $refOutput);
}

sub add
{
  my $refHash = shift;
  my $refOutput = shift;
  my @actions = ('tracker', 'add', '--noask');
  return execCliFromHash(\@actions, $refHash, $refOutput);
}

sub list
{
  my $refHash = shift;
  my $refOutput = shift;
  my @actions = ('tracker', 'list');
  return execCliFromHash(\@actions, $refHash, $refOutput);
}

sub addcomment
{
  my $refHash = shift;
  my $refOutput = shift;
  my @actions = ('tracker', 'addComment');
  return execCliFromHash(\@actions, $refHash, $refOutput);
}

sub retrieve_extra_field_value
{
  my $fieldNumber = shift;
  my $artifactId = shift;
  my $output = shift;
  my $result = '';
  if($output =~ /\|\s+$fieldNumber\s+\|\s+$artifactId\s+/)
    {
      my @lines = split("\n", $output);
      my $takeNext = 0;
      my $isInteresting = 0;
      foreach my $line (@lines)
        {
          if($line =~ /\|\s+$fieldNumber\s+\|\s+$artifactId\s+/)
            {
              $line =~ s/\|\s+$fieldNumber\s+\|\s+$artifactId\s+\|\s+//;
              $isInteresting = 1;
            }
          if($isInteresting || $takeNext)
            {
              if($takeNext)
                {
                  $result .= "\n";
                }
              $takeNext = 0;
              if(!($line =~ /\|$/))
                {
                  $takeNext = 1;
                }
              else
                {
                  $line =~ s/\s*\|$//;
                }
              $line =~ s/\s*$//;
              if($line)
                {
                  $result .= "$line";
                }
              if(!$takeNext)
                {
                  last;
                }
            }
        }
    }
  return $result;
}

1;
