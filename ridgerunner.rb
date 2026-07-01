class Ridgerunner < Formula
  desc "Knot-tightening program using constrained gradient descent"
  homepage "https://www.jasoncantarella.com/wordpress/software/ridgerunner/"
  url "https://github.com/designbynumbers/ridgerunner/releases/download/v2.3.0/ridgerunner-2.3.0.tar.gz"
  sha256 "3ef31c4d7131da10eb747c6814f41b24b34f0d4ca0be715b20bf29acd84fa35c"
  license "GPL-1.0-or-later"

  depends_on "pkg-config" => :build
  depends_on "argtable"
  depends_on "gsl"
  depends_on "libplcurve"
  depends_on "libtsnnls"
  depends_on "openblas"
  uses_from_macos "ncurses"

  def install
    # OpenBLAS is keg-only but ships openblas.pc, and Homebrew adds keg-only pkgconfig dirs to
    # PKG_CONFIG_PATH, so configure's PKG_CHECK_MODULES([openblas]) finds it with no manual
    # LDFLAGS/CPPFLAGS. plCurve/tsnnls/gsl/argtable are on the normal prefix search path.
    system "./configure", *std_configure_args, "--disable-silent-rules"
    system "make"
    system "make", "check" # 4 fast self-tests; drop this line to keep installs lean
    system "make", "install"
  end

  test do
    # Autoscale and tighten a bundled example trefoil for two steps, then confirm output.
    cp pkgshare/"3.1.vect", testpath
    system bin/"ridgerunner", "-a", "-s", "2", "3.1.vect"
    assert_path_exists testpath/"3.1.rr/3.1.final.vect"
  end
end
