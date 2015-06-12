#      ______________
#    /.--------------.\
#   //                \\
#  //                  \\
# || .-..----. .-. .--. ||   HEY! KEEP THIS MODULE CLEAN!!
# ||( ( '-..-'|.-.||.-.|||   My plan is to eventually package the whole
# || \ \  ||  || ||||_||||   FbResource module into its own gem. Don't put RPi
# ||._) ) ||  \'-'/||-' ||   stuff in here, please.
#  \\'-'  `'   `-' `'  //    -- Rick Carlino
#   \\                //
#    \\______________//
#     '--------------'
require 'rest-client'
require 'json'

require_relative 'http'
require_relative 'schedules/index'
require_relative 'client'
