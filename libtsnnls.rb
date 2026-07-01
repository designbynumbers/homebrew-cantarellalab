class Libtsnnls < Formula
  desc "Fast solver for sparse non-negative least squares problems"
  homepage "https://www.jasoncantarella.com/wordpress/software/tsnnls/"
  url "https://github.com/designbynumbers/tsnnls/releases/download/v2.5.1/libtsnnls-2.5.1.tar.gz"
  sha256 "bba757711d5b25ce67f1d49781ca3309d02b540e7b6907edc02f88bdff8e0b67"
  license "GPL-1.0-or-later"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build
  depends_on "argtable"
  depends_on "openblas"

  def install
    # Source releases ship no generated files, so bootstrap the autotools build first.
    # OpenBLAS is keg-only but located via pkg-config (Homebrew adds its pkgconfig dir to
    # PKG_CONFIG_PATH), so no manual LDFLAGS/CPPFLAGS are needed.
    system "./autogen.sh"
    system "./configure", *std_configure_args, "--disable-silent-rules"
    system "make", "install"
  end

  test do
    system bin/"tsnnls_test", "--help"
  end
end
