# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class Ridgerunner < Formula
  desc "ridgerunner is a knot-tightening program"
  homepage "https://www.jasoncantarella.com/wordpress/software/ridgerunner/"
  url "https://github.com/designbynumbers/ridgerunner/releases/download/v2.2.2/ridgerunner-2.2.2.tar.gz"

  sha256 "63a21dfe52ddaf58f698a80ef2776dccfbdfcf253e4702d95b9dd61a23def4b4"
  license "GPL-1.0-or-later"

  uses_from_macos "ncurses"
  depends_on "openblas"
  depends_on "argtable"
  depends_on "gsl"
  depends_on "libplcurve"
  depends_on "libtsnnls"

  def install
    # ENV.deparallelize  # if your formula fails when building in parallel
    # Remove unrecognized options if warned by configure
    # https://rubydoc.brew.sh/Formula.html#std_configure_args-instance_method
    system "./configure", *std_configure_args, "--disable-silent-rules","LDFLAGS=-L#{HOMEBREW_PREFIX}/opt/openblas/lib/","CPPFLAGS=-I#{HOMEBREW_PREFIX}/opt/openblas/include"
    
    system "make", "install"
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! For Homebrew/homebrew-core
    # this will need to be a test that verifies the functionality of the
    # software. Run the test with `brew test libplcurve`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "#{bin}/ridgerunner","--help"
  end
end
