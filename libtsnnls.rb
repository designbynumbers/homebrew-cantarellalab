# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class Libtsnnls < Formula
  desc "tsnnls is a fast solver for sparse non-negative least squares problems"
  homepage "https://www.jasoncantarella.com/wordpress/software/tsnnls/"
  url "https://github.com/designbynumbers/tsnnls/releases/download/v.2.4.5/libtsnnls-2.4.5.tar.gz"
  sha256 "e7428a63a1cafbbd94cf035aa35e7bcf65f8935547c12529f481222f3be76935"
  license "GPL-1.0-or-later"

  # depends_on "cmake" => :build

  depends_on "openblas"
  depends_on "argtable"

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
    system "#{bin}/tsnnls_test","--help"
  end
end
