class Libplcurve < Formula
  desc "Library for polygonal curves (knots and links)"
  homepage "https://www.jasoncantarella.com/"
  url "https://github.com/designbynumbers/plcurve/releases/download/v11.2.0/libplcurve-11.2.0.tar.gz"
  sha256 "283bc64fb510677e9e46e2275f8cda3a6e15e38c00a4cc6a2403dcdb03fbbab5"
  license "GPL-1.0-or-later"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "gsl"

  def install
    # Source releases ship no generated files, so bootstrap the autotools build first.
    system "./autogen.sh"
    system "./configure", *std_configure_args, "--disable-silent-rules"
    system "make", "install"
  end

  test do
    system bin/"randompolygon", "-n", "6", "-s", "1"
  end
end
