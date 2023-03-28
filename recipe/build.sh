#!/usr/bin/env bash
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* ./config
set -ex

# TODO: Remove the following once we update to CentOS 7.
# These defines (extracted from Linux sources) are only needed for CentOS 6.
export CPPFLAGS="${CPPFLAGS} -DCLOCK_BOOTTIME=7 -DO_PATH=010000000"

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
            --without-systemdsystemunitdir
make -j ${CPU_COUNT}
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
make check \
  TS_OPT_misc_setarch_known_fail=yes \
  TS_OPT_column_invalid_multibyte_known_fail=yes
fi
make install
