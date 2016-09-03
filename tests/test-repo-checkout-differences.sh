#!/bin/bash
#
# Copyright (C) 2016 Red Hat, Inc.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.

set -euo pipefail

umask 0002

. $(dirname $0)/libtest.sh

setup_test_repository "bare"

echo '1..8'

assert_directories_match() {
    (cd $1 && ls -l --time-style=+X) > contents1
    (cd $2 && ls -l --time-style=+X) > contents2

    cmp contents1 contents2 || (echo 1>&2 "Contents differ"; diff 1>&2 -u contents1 contents2; exit 1)
}

$OSTREE checkout test2^ foo
$OSTREE checkout --apply-differences-from=test2^ test2 foo
rm -rf bar && $OSTREE checkout test2 bar
assert_directories_match foo bar
echo "ok basic operation"

echo cheese > files/baz/moon
(cd files && $OSTREE commit -b test2 -s "Add file in subdir" -m "test commit 3 body")

$OSTREE checkout --apply-differences-from=test2^ test2 foo
rm -rf bar && $OSTREE checkout test2 bar
assert_directories_match foo bar
echo "ok add file in subdir"

rm files/firstfile
mkdir files/firstfile
echo stuff > files/firstfile/childfile
(cd files && $OSTREE commit -b test2 -s "Change file to directory" -m "test commit 4 body")

$OSTREE checkout --apply-differences-from=test2^ test2 foo
rm -rf bar && $OSTREE checkout test2 bar
assert_directories_match foo bar
echo "ok change file to directory"

rm -rf files/firstfile
echo "newstuff" > files/firstfile
(cd files && $OSTREE commit -b test2 -s "Change directory to file" -m "test commit 5 body")

$OSTREE checkout --apply-differences-from=test2^ test2 foo
rm -rf bar && $OSTREE checkout test2 bar
assert_directories_match foo bar
echo "ok change file to directory"

rm -rf files/firstfile
(cd files && $OSTREE commit -b test2 -s "Remove file" -m "test commit 6 body")

$OSTREE checkout --apply-differences-from=test2^ test2 foo
rm -rf bar && $OSTREE checkout test2 bar
assert_directories_match foo bar
echo "ok remove file"

rm -rf foo && $OSTREE checkout --subpath=baz/moon test2^ foo
$OSTREE checkout --subpath=baz/moon --apply-differences-from=test2^ test2 foo
rm -rf bar && $OSTREE checkout --subpath=baz/moon test2 bar
assert_directories_match foo bar
echo "ok checkout single file, no changes"

echo "blue cheese" > files/baz/moon
(cd files && $OSTREE commit -b test2 -s "Change a file" -m "test commit 7 body")

$OSTREE checkout --subpath=baz/moon --apply-differences-from=test2^ test2 foo
rm -rf bar && $OSTREE checkout --subpath=baz/moon test2 bar
assert_directories_match foo bar
echo "ok checkout single file, with changes"

chmod 0700 files/baz
chmod 0500 files/baz/moon
(cd files && $OSTREE commit -b test2 -s "Change permissions" -m "test commit 8 body")

$OSTREE checkout --subpath=baz/moon --apply-differences-from=test2^ test2 foo
rm -rf bar && $OSTREE checkout --subpath=baz/moon test2 bar
assert_directories_match foo bar
echo "ok change permissions"
