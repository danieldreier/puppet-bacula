# Class: bacula
#
# This class installs a bacula job on the director.  This can be used for specific applications as well as general host backups
#
# Parameters:
#   * files - An array of files that you wish to get backed up on this job for this host.  ie: ["/etc","/usr/local"]
#   * excludes - An array of files to skip for the given job.  ie: ["/usr/local/src"]
#   * fileset - If set to true, a fileset will be genereated based on the files and exclides paramaters specified above.  Of set to anything but true, the job will attempt to use the fileset named "Common".  NOTE:  the fileset common must be declared elsewhere for this to work.  See Class::Bacula for details.
#
# Actions:
#   * Exports job fragment for consuption on the director
#   * Exports nagios service for consumption on nagios server
#
# Requires:
#   * Class::Bacula {}
#
# Sample Usage:
#  bacula::job {
#    "${fqdn}-common":
#      fileset => "Common",
#  }
#  bacula::job {
#    "${fqdn}-mywebapp":
#      files    => ["/var/www/mywebapp","/etc/mywebapp"],
#      excludes => ["/var/www/mywebapp/downloads"],
#  }
#
define bacula::job (
    $files    = '',
    $excludes = '',
    $jobtype  = 'Backup',
    $fileset  = true,
    $template = 'bacula/job.conf.erb',
    $pool     = 'Default'
  ) {

  include bacula
  include bacula::params

  # if the fileset is not defined, we fall back to one called "Common"
  if $fileset == true {
    if $files == '' { err('you tell me to create a fileset, but no files given') }
    $fileset_real = $name
    bacula::fileset {
      $name:
        files    => $files,
        excludes => $excludes
      }
  } else {
    $fileset_real = 'Common'
  }

  @@concat::fragment { "bacula-job-${name}":
    target  => '/etc/bacula/conf.d/job.conf',
    content => template($template),
    tag     => "bacula-${::bacula::params::bacula_director}";
  }

  if $bacula::monitor == true {
    if $jobtype == 'Backup' {
      icinga::service { "check_bacula_${name}":
        check_command         => "check_nrpe!check_bacula!72 2 1 ${name}",
        escalate              => true,
        first_escalation      => '3',
        dependency_service    => "check_env_${::fqdn}",
        dependency_host       => $::bacula::params::bacula_director,
        notification_delay    => '120',
        notification_options  => 'n',
        servicegroups         => 'world',
      }
    }
  }
}
