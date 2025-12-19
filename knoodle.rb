# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
class Knoodle < Formula
  desc "Computational knot theory library with PolyFold knot-tightening"
  homepage "https://github.com/HenrikSchumacher/Knoodle"

  url "https://github.com/HenrikSchumacher/Knoodle.git",
      tag: "v0.2.1-alpha",
      revision: "37b11b1e2f3cd9590100e20a3e1b8662ed0743d8"  
  version "0.2.1-alpha"
  
  #url "https://github.com/HenrikSchumacher/Knoodle/releases/download/v0.2.1-alpha/knoodle-0.2.1-alpha.tar.gz"
  #sha256 "fe8b3ba3231d4df6ee75c2cb1972646ce4795a87d16eff9bbe5d40d1f6ddd00e" # Replace with actual SHA256 from the script
  
  license "MIT"  # Verify the actual license

  bottle :unneeded

  depends_on "boost"
  depends_on "metis"
  depends_on "clp" 
  depends_on "suite-sparse"
  
  # Optional dependencies that might be needed
  #depends_on "gsl" => :recommended
  #depends_on "argtable" => :optional

  def pour_bottle?
    reason "This formula requires CPU-specific optimizations for performance"
    # Logic to determine if the bottle should be used (returns true or false)
    # e.g., return false if a specific condition is met that would break the bottle
    false # By default, Homebrew assumes bottles can be poured
  end
  
  def install

    # Handle submodules - Homebrew doesn't automatically fetch them
    system "git", "submodule", "update", "--init", "--recursive", "--depth", "1"

    ENV.O3  # Force -O3
    ENV.append_to_cflags "-march=native" if build.bottle?
    
    # Critical: Tell superenv not to sanitize these specific flags
    ENV.runtime_cpu_detection if build.bottle?
    
    # For non-bottled builds, force native optimization
    if !build.bottle?
      ENV.append "HOMEBREW_OPTFLAGS", "-march=native"
      ENV.append "HOMEBREW_OPTFLAGS", "-mtune=native"
    end

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
