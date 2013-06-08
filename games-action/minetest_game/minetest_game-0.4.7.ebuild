# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5
inherit games vcs-snapshot

DESCRIPTION="Official mod for minetest"
HOMEPAGE="http://c55.me/minetest/"
SRC_URI="http://github.com/minetest/minetest_game/tarball/${PV} -> ${P}.tar.gz"

LICENSE="GPL-2 CCPL-Attribution-ShareAlike-3.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="~games-action/minetest-${PV}[-dedicated]
	>=games-action/minetest_common-0.4.6"

src_install() {
	insinto "${GAMES_DATADIR}"/minetest/games/${PN}
	doins -r mods menu
	doins game.conf

	dodoc README.txt

	prepgamesdirs
}
