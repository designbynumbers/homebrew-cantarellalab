# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
class Knoodle < Formula
  desc "Computational knot theory library with PolyFold knot-tightening"
  homepage "https://github.com/HenrikSchumacher/Knoodle"
  url "https://github.com/HenrikSchumacher/Knoodle/releases/download/v0.2.1-alpha/knoodle-0.2.1-alpha.tar.gz"
  sha256 "fe8b3ba3231d4df6ee75c2cb1972646ce4795a87d16eff9bbe5d40d1f6ddd00e" # Replace with actual SHA256 from the script
  license "MIT"  # Verify the actual license
  env :std
  
  bottle do
    # Bottle specs will be added here after first successful build
  end
  
  depends_on "boost"
  depends_on "metis"
  depends_on "clp" 
  depends_on "suite-sparse"
  
  # Optional dependencies that might be needed
  #depends_on "gsl" => :recommended
  #depends_on "argtable" => :optional
  
  def install
    # Pass version to the Makefile
    ENV["KNOODLE_VERSION"] = version.to_s
    
    # Ensure Homebrew paths are available
    ENV["HOMEBREW_PREFIX"] = HOMEBREW_PREFIX
    
    # Handle architecture-specific flags
    if Hardware::CPU.arm64?
      # For Apple Silicon
      ENV.append "CXXFLAGS", "-mcpu=apple-m1"
    end
    
    # Build and install PolyFold
    cd "PolyFold" do
      system "make"
      system "make", "install", "PREFIX=#{prefix}"
    end
    
    # Install library headers if needed
    include.install "Knoodle.hpp"
    (include/"knoodle").install Dir["src/*.hpp"]
    
    # Install any additional utilities or documentation
    doc.install "README.md" if File.exist?("README.md")
  end
  
  test do
    # Test that polyfold runs and shows help/version
    assert_match version.to_s, shell_output("#{bin}/polyfold --version 2>&1", 1)
    system "#{bin}/polyfold", "--help"
  end
  
  def caveats
    <<~EOS
      Knoodle's PolyFold has been installed.
      
      The main executable is:
        #{bin}/polyfold
      
      Header files have been installed to:
        #{include}/knoodle/
    EOS
  end
end
