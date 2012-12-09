# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4
inherit eutils cmake-utils gnome2-utils vcs-snapshot user games

DESCRIPTION="An InfiniMiner/Minecraft inspired game"
HOMEPAGE="http://c55.me/minetest/"
SRC_URI="http://github.com/celeron55/minetest/tarball/${PV} -> ${P}.tar.gz"

LICENSE="LGPL-2.1+ CCPL-Attribution-ShareAlike-3.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="bundled-libs dedicated nls +server"

RDEPEND="dev-db/sqlite:3
	sys-libs/zlib
	!bundled-libs? (
		dev-lang/lua
		<dev-libs/jthread-1.3
	)
	!dedicated? (
		app-arch/bzip2
		media-libs/libogg
		media-libs/libpng:0
		media-libs/libvorbis
		media-libs/openal
		virtual/jpeg
		virtual/opengl
		x11-libs/libX11
		x11-libs/libXxf86vm
	)
	nls? ( virtual/libintl )"
# XXX: support shared lib for irrlicht
DEPEND="${RDEPEND}
	<dev-games/irrlicht-1.8
	nls? ( sys-devel/gettext )"

pkg_setup() {
	games_pkg_setup

	if use server || use dedicated ; then
		enewuser ${PN} -1 -1 /var/lib/${PN} ${GAMES_GROUP}
	fi
}

src_unpack() {
	vcs-snapshot_src_unpack
}

src_prepare() {
	if ! use bundled-libs ; then
		epatch \
			"${FILESDIR}"/${P}-jthread.patch \
			"${FILESDIR}"/${P}-lua.patch

		rm -r src/{jthread,lua,sqlite} || die
	fi

	# set paths
	sed \
		-e "s#@BINDIR@#${GAMES_BINDIR}#g" \
		-e "s#@GROUP@#${GAMES_GROUP}#g" \
		"${FILESDIR}"/minetestserver.confd > "${T}"/minetestserver.confd || die
}

src_configure() {
	local mycmakeargs=(
		-DRUN_IN_PLACE=0
		-DCUSTOM_SHAREDIR="${GAMES_DATADIR}/${PN}"
		-DCUSTOM_BINDIR="${GAMES_BINDIR}"
		-DCUSTOM_DOCDIR="/usr/share/doc/${PF}"
		$(usex dedicated "-DBUILD_SERVER=ON -DBUILD_CLIENT=OFF" "$(cmake-utils_use_build server SERVER) -DBUILD_CLIENT=ON")
		$(cmake-utils_use_enable nls GETTEXT)
		)

	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile
}

src_install() {
	cmake-utils_src_install

	if use server || use dedicated ; then
		newinitd "${FILESDIR}"/minetestserver.initd minetest-server
		newconfd "${T}"/minetestserver.confd minetest-server
	fi

	prepgamesdirs
}

pkg_preinst() {
	games_pkg_preinst
	gnome2_icon_savelist
}

pkg_postinst() {
	games_pkg_postinst
	gnome2_icon_cache_update

	if ! use dedicated ; then
		elog
		elog "optional dependencies:"
		elog "	games-action/minetest_game (official mod)"
		elog
	fi

	if use server || use dedicated ; then
		elog
		elog "Configure your server via /etc/conf.d/minetest-server"
		elog "The user \"minetest\" is created with /var/lib/${PN} homedir."
		elog "Default logfile is ~/minetest-server.log"
		elog
	fi
}

pkg_postrm() {
	gnome2_icon_cache_update
}
