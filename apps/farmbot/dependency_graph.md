# How does Farmbot function?

## apps in the umbrella
* farmbot - The main application. This is the entry point.
  * starts filesystem
  * starts network
  * starts auth
  * starts configurator
  * relies on filesystem
  * relies on network
  * relies on auth
* farmbot_auth - the authorization services
  * relies on filesystem
* farmbot_configurator - Configuration services
  * configures auth
  * configures network
  * relies on filesystem
* farmbot_filesystem - filesystem services
* farmbot_network - network services
  * relies on filesystem
  * relies on auth
* nerves_system_* - Linux configs for various hardware profiles.
