#!/usr/bin/env bash

# used targets:
#   install-usrlib_execLTLIBRARIES: install libraries
#   install-data: install headers and pkgconfig
#     but exclude:
#       CATALOGS: language files
#       dist_man_MANS: man pages
#       man_MANS: man pages
#       dist_getoptexample_SCRIPTS: getopt examples
#       dist_bashcompletion_DATA: bashcompletion scripts
make \
  install-usrlib_execLTLIBRARIES\
  install-data \
  CATALOGS='' \
  dist_man_MANS='' man_MANS='' \
  dist_getoptexample_SCRIPTS='' dist_bashcompletion_DATA=''
