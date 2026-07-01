class Libplcurve < Formula
  desc "Library for polygonal curves (knots and links)"
  homepage "https://www.jasoncantarella.com/"
  url "https://github.com/designbynumbers/plcurve/releases/download/v11.2.2/libplcurve-11.2.2.tar.gz"
  sha256 "bccb193f8b0ed5f087e02bbd0d83a4b7ca20a61a8a013ce9efb624f0eebca294"
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
