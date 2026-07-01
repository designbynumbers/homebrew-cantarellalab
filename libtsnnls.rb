class Libtsnnls < Formula
  desc "Fast solver for sparse non-negative least squares problems"
  homepage "https://www.jasoncantarella.com/wordpress/software/tsnnls/"
  url "https://github.com/designbynumbers/tsnnls/releases/download/v2.5.0/libtsnnls-2.5.0.tar.gz"
  sha256 "82d045fdd08a76bb1733813124f241f33bc04046b9586558987c8e48df404a15"
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
