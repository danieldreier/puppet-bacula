class bacula::client::monitor {
  include bacula::params

  icinga::service { "check_baculafd_${::fqdn}":
    check_command      => 'check_nrpe!check_proc!1:1 bacula-fd',
    escalate           => true,
    notification_delay => '120',
    first_escalation   => '3',
    require            => Service[$bacula::params::bacula_client_services],
    servicegroups      => hiera('location')
  }

}
