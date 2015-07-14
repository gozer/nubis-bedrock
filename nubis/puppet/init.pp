# Main entry for puppet
#
# import is deprecated and we should use another
# method for including these manifests
#

import 'bedrock.pp'
import 'apache.pp'
# import 'mysql.pp'
import 'fluentd.pp'
import 'varnish.pp'
