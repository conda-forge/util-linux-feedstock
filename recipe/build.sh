#!/usr/bin/env bash
set -ex

OSX_ARGS=""
if [[ $target_platform == "osx-"* ]]; then
  # the following do not build on macOS
  # wall is already on macOS
  OSX_ARGS="--disable-ipcs \
            --disable-ipcrm \
            --disable-wall \
            --disable-libmount \
            --disable-liblastlog2"
fi

# https://kernelnewbies.org/Linux_4.10
# https://elixir.bootlin.com/linux/v4.10.17/source/include/uapi/linux/sockios.h
export CPPFLAGS="${CPPFLAGS} -DSIOCGSKNS=0x894C"

# Regenerate the autotools build system so it picks up the conda-forge
# gettext/libtool macros. Run autotools manually to skip gtkdocize
# (gtk-doc is not available in conda-forge).
autopoint --force
aclocal --force -I m4
libtoolize --copy --force
autoconf
autoheader
automake --add-missing --copy

./configure --prefix="${PREFIX}" \
            --sbindir="${PREFIX}/bin" \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-static     \
            --enable-libuuid     \
            --without-systemd    \
            --disable-makeinstall-chown \
            --disable-makeinstall-setuid \
            --without-systemdsystemunitdir \
            $OSX_ARGS
make -j ${CPU_COUNT}

# The name of the flag is
# TS_OPT_<test_name>_known_fail
# where test_name
# libmount/update-py  --> libmount_update_py
known_fail=" TS_OPT_column_invalid_multibyte_known_fail=yes"
if [[ $target_platform == linux-aarch64 ]]; then
  known_fail+=" TS_OPT_kill_decode_known_fail=yes"
  known_fail+=" TS_OPT_misc_swaplabel_known_fail=yes"
  known_fail+=" TS_OPT_mkswap_mkswap_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_mkfds_ro_regular_file_known_fail=yes"  # can be flaky on this platform
  known_fail+=" TS_OPT_libmount_tabfiles_py_known_fail=yes"
  known_fail+=" TS_OPT_kill_name_to_number_known_fail=yes"
  known_fail+=" TS_OPT_kill_queue_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_mkfds_directory_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_mkfds_symlink_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_mkfds_tcp6_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_mkfds_udp6_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_option_inet_known_fail=yes"

  known_fail+=" TS_OPT_libmount_update_py_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_column_ainodeclass_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_column_type_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_column_xmode_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_mkfds_signalfd_known_fail=yes"
  known_fail+=" TS_OPT_lslocks_lslocks_known_fail=yes"
  # script_options fails on pypy + aarch64 under emulation
  known_fail+=" TS_OPT_script_options_known_fail=yes"
fi
if [[ $target_platform == linux-ppc64le ]]; then
  # These tests seem to fail under emulation
  known_fail+=" TS_OPT_kill_decode_known_fail=yes"
  known_fail+=" TS_OPT_fdisk_bsd_known_fail=yes"
  known_fail+=" TS_OPT_kill_name_to_number_known_fail=yes"
  known_fail+=" TS_OPT_kill_options_known_fail=yes"
  known_fail+=" TS_OPT_libmount_tabfiles_py_known_fail=yes"

  known_fail+=" TS_OPT_libmount_update_py_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_column_ainodeclass_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_column_type_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_column_xmode_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_mkfds_directory_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_mkfds_signalfd_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_mkfds_symlink_known_fail=yes"
  known_fail+=" TS_OPT_lslocks_lslocks_known_fail=yes"
  known_fail+=" TS_OPT_script_options_known_fail=yes"
fi
if [[ $target_platform == linux-riscv64 ]]; then
  # These tests seem to fail under emulation
  known_fail+=" TS_OPT_kill_decode_known_fail=yes"
  known_fail+=" TS_OPT_kill_name_to_number_known_fail=yes"
  known_fail+=" TS_OPT_libmount_tabfiles_py_known_fail=yes"
  known_fail+=" TS_OPT_libmount_update_py_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_column_ainodeclass_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_column_type_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_mkfds_directory_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_mkfds_signalfd_known_fail=yes"
fi
if [[ $target_platform == linux-64 ]]; then
  known_fail+=" TS_OPT_lsfd_column_ainodeclass_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_column_type_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_column_xmode_known_fail=yes"
  known_fail+=" TS_OPT_lslocks_lslocks_known_fail=yes"

  # Python 3.15 rewrote Lib/site.py: a .pth line naming a directory that does
  # not exist is now reported on stderr instead of being skipped silently.
  # conda ships conda-site.pth, whose lib/python/site-packages entry only
  # exists once a `noarch: python` package has been installed, so in this host
  # environment every interpreter start prints
  #
  #   In $PREFIX/lib/python3.15/site-packages/conda-site.pth: \
  #   $PREFIX/lib/python/site-packages does not exist; skipping sys.path append
  #
  # libmount/tabfiles-py diffs the interpreter's stderr against a recorded
  # fixture, so that single line fails all 11 sub-tests. This is noise from the
  # conda environment rather than a pylibmount regression: the bindings compile
  # and import fine, and libmount/update-py, which does not capture stderr,
  # still passes. The real fix belongs in conda-forge/python-feedstock, so
  # prefer marking the test known-fail over creating a directory inside
  # $PREFIX that we would otherwise never ship. linux-aarch64/ppc64le/riscv64
  # already mark this same test known-fail above.
  #
  # This is self-healing: tests/functions.sh only consults known-fail on the
  # failure path, so the test goes back to reporting OK on its own once the
  # warning is gone.
  py_major=${PY_VER:-0.0}; py_major=${py_major%%.*}
  py_minor=${PY_VER:-0.0}; py_minor=${py_minor#*.}
  if (( py_major > 3 || (py_major == 3 && py_minor >= 15) )); then
    known_fail+=" TS_OPT_libmount_tabfiles_py_known_fail=yes"
  fi
fi

which xargs || true
# hmaarrfk - 2025/12/23
# Tests are failing on osx with some strange error about xargs
# xargs: command line cannot be assembled, too long
if [[ $target_platform == linux-* ]]; then
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
make check $known_fail
fi
fi

make install
