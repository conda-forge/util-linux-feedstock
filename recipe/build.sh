#!/usr/bin/env bash
set -ex

# TODO: Remove the following once we update to CentOS 7.
# These defines (extracted from Linux sources) are only needed for CentOS 6.
export CPPFLAGS="${CPPFLAGS} -DCLOCK_BOOTTIME=7 -DO_PATH=010000000"

if [[ $target_platform == "osx-"* ]]; then
  # the following do not build on macOS
  # wall is already on macOS
  # uuid conflicts with ossp-uuid
  OSX_ARGS="--disable-ipcs \
            --disable-ipcrm \
            --disable-wall \
            --disable-libmount \
            --enable-libuuid"

fi

autoreconf -vfi

./configure --prefix="${PREFIX}" \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-static     \
            --without-systemd    \
            --disable-makeinstall-chown \
            --disable-makeinstall-setuid \
            --without-systemdsystemunitdir \
            $OSX_ARGS

make -j ${CPU_COUNT}
make check \
  TS_OPT_misc_setarch_known_fail=yes \
  TS_OPT_column_invalid_multibyte_known_fail=yes
make install
