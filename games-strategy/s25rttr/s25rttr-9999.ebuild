# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3

EBZR_REPO_URI="lp:s25rttr"

inherit eutils cmake-utils bzr games

DESCRIPTION="Open Source remake of The Settlers II game"
HOMEPAGE="http://www.siedler25.org/"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS=""
IUSE=""

RDEPEND="app-arch/bzip2
	media-libs/libsamplerate
	media-libs/libsdl[X,sound,video]
	media-libs/libsndfile
	media-libs/sdl-mixer
	net-libs/miniupnpc
	virtual/opengl"
DEPEND="${RDEPEND}
	sys-devel/gettext"

src_prepare() {
	# date Sat Apr 7 2012
	epatch "${FILESDIR}"/${PV}-cmake.patch
	# date Mon Apr 30 2012
	epatch "${FILESDIR}"/${PV}-soundconverter.patch
}

src_configure() {
	sed \
		-e '/^TARGET_LINK_LIBRARIES/s#)# dl)#' \
		-i src/CMakeLists.txt || die "fixing underlinking failed"

	# build system does not set the version for us
	# will prevent us from connecting to other players
	local mydate
	mydate=$(bzr version-info "${EBZR_STORE_DIR}/${EBZR_PROJECT}" 2> /dev/null \
		| awk '{if ($1 == "date:") {gsub("-", "",$2); print $2}}')

	local arch
	case ${ARCH} in
		amd64)
			arch="x86_64" ;;
		x86)
			arch="i386" ;;
		*) die "Architecture ${ARCH} not yet supported" ;;
	esac

	local mycmakeargs=(
		-DCOMPILEFOR="linux"
		-DCOMPILEARCH="${arch}"
		-DCMAKE_SKIP_RPATH=YES
		-DPREFIX="${GAMES_PREFIX}"
		-DBINDIR="${GAMES_BINDIR}"
		-DDATADIR="${GAMES_DATADIR}"
		-DLIBDIR="$(games_get_libdir)/${PN}"
		-DDRIVERDIR="$(games_get_libdir)/${PN}"
		-DGAMEDIR="~/.${PN}/S2"
		-DWINDOW_VERSION="${mydate}"
		-DWINDOW_REVISION="${EBZR_REVNO}"
	)

	cmake-utils_src_configure
}

src_compile() {
	# build system uses some relative paths,
	# but CMAKE_IN_SOURCE_BUILD fails/unsupported
	ln -s "${CMAKE_USE_DIR}"/RTTR "${CMAKE_BUILD_DIR}"/RTTR || die

	cmake-utils_src_compile
}

src_install() {
	cd "${CMAKE_BUILD_DIR}" || die

	# libs, converter
	exeinto "$(games_get_libdir)"/${PN}
	doexe RTTR/{sound-convert,s-c_resample} || die
	exeinto "$(games_get_libdir)"/${PN}/video
	doexe driver/video/SDL/src/libvideoSDL.so || die
	exeinto "$(games_get_libdir)"/${PN}/audio
	doexe driver/audio/SDL/src/libaudioSDL.so || die

	# data
	insinto "${GAMES_DATADIR}"
	rm RTTR/{sound-convert,s-c_resample} || die
	doins -r RTTR || die

	# icon, bin, wrapper, docs
	doicon "${CMAKE_USE_DIR}"/debian/${PN}.png || die
	dogamesbin src/s25client || die
	make_desktop_entry "s25client" "Settlers RTTR" "${PN}"
	dodoc RTTR/texte/{keyboardlayout.txt,readme.txt} || die

	# permissions
	prepgamesdirs
}

pkg_postinst() {
	games_pkg_postinst
	elog "Copy your Settlers2 cdrom content into ~/.${PN}/S2"
}
