# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
class Libplcurve < Formula
  desc "plcurve is a library for polygonal curves"
  homepage "https://www.jasoncantarella.com/"
  url "https://github.com/designbynumbers/plcurve/releases/download/v11.1.1/libplcurve-11.0.0.tar.gz"
  sha256 "41a47ec7643c8feb4d324ce4f15a61f4695ee7c26a8060ef3f51f54c1dfb09a0"
  license "GPL-1.0-or-later"

  depends_on "gsl"

  def install
    # ENV.deparallelize  # if your formula fails when building in parallel
    # Remove unrecognized options if warned by configure
    # https://rubydoc.brew.sh/Formula.html#std_configure_args-instance_method
    system "./configure", *std_configure_args, "--disable-silent-rules"
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
    system "#{bin}/randompolygon","-n","6","-s","1"
  end
end
