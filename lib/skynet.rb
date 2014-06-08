

require_relative 'skynet/skynet'

# The unfortunate use of globals in this project: The SocketIO library we use to
# talk to skynet stores blocks as lambdas and calls them later under a different
# context than that which they were defined. This means that even though we
# define the .on() events within the `Device` class, self does NOT refer to the
# device, but rather the current socket connection. Using a global is a quick
# fix to ensure we always have easy access to the device. Pull requests welcome.

$skynet = Skynet.new
$skynet.start

#TODO: Daemonize this script:
#https://www.ruby-toolbox.com/categories/daemonizing
