# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class Libplcurve < Formula
  desc "plcurve is a library for polygonal curves"
  homepage "https://www.jasoncantarella.com/"
  url "https://github.com/designbynumbers/plcurve/raw/master/libplcurve-10.1.0.tar.gz"
  sha256 "4323c02705668639c9389f5f96dc8d31f97582e106814ce71d486688c1b4f092"
  license "GPL-1.0-or-later"

  # depends_on "cmake" => :build

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
