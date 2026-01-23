# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
require_relative "lib/custom_download_strategy"

class Knoodle < Formula
  desc "Computational knot theory library with PolyFold knot-tightening and KnoodleTool utilities"
  homepage "https://github.com/HenrikSchumacher/Knoodle"
  
  url "https://github.com/HenrikSchumacher/Knoodle.git",
      tag: "v0.3.2-alpha",
      revision: "0f84dbe533b1ad0666f4aafb0819f5c38b496dce",
      using: GitLFSDownloadStrategy
  version "0.3.2-alpha"
  license "MIT"
  
  head "https://github.com/HenrikSchumacher/Knoodle.git", branch: "main"
  
  depends_on "boost"
  depends_on "metis"
  depends_on "clp" 
  depends_on "suite-sparse"
  depends_on "git-lfs"
  
  # Use LLVM/clang consistently on Linux to avoid ABI issues with bottles
  depends_on "llvm" if OS.linux?
  
  pour_bottle? do
    reason "This formula requires CPU-specific optimizations for maximum performance"
    satisfy { false }
  end
  
  def install
    # Warn users about potentially long compilation time
    if OS.linux?
      ohai "Linux detected: This installation may take 20-30 minutes"
      ohai "Recompiling dependencies with LLVM/clang for ABI compatibility..."
      ohai "Please be patient - this ensures optimal performance and stability."
      puts ""
    end
    
    ohai "Cloning repository and initializing submodules..."
    system "git", "submodule", "update", "--init", "--recursive", "--depth", "1"
    
    env :std
    
    ENV["KNOODLE_VERSION"] = version.to_s
    ENV["HOMEBREW_PREFIX"] = HOMEBREW_PREFIX
    
    # Use consistent compiler approach based on OS
    if OS.linux?
      ohai "Setting up LLVM/clang toolchain for Linux build..."
      # On Linux, use brewed clang to match how we'll rebuild dependencies
      llvm_prefix = Formula["llvm"].opt_prefix
      ENV["CC"] = "#{llvm_prefix}/bin/clang"
      ENV["CXX"] = "#{llvm_prefix}/bin/clang++"
      ENV["LDFLAGS"] = "-L#{llvm_prefix}/lib -Wl,-rpath,#{llvm_prefix}/lib"
      ENV["CPPFLAGS"] = "-I#{llvm_prefix}/include"
      
      puts "Using compiler: #{ENV["CXX"]}"
      puts "LDFLAGS: #{ENV["LDFLAGS"]}"
      puts ""
    elsif OS.mac?
      # On macOS, use system clang
      ENV["CXX"] = "clang++"
      ENV["CC"] = "clang"
    end
    
    # Build and install PolyFold
    ohai "Building PolyFold (knot-tightening tool)..."
    cd "PolyFold" do
      system "make"
      system "make", "install", "PREFIX=#{prefix}"
    end
    
    # Build and install KnoodleTool
    ohai "Building KnoodleTool (knot theory utilities)..."
    cd "KnoodleTool" do
      system "make"
      system "make", "install", "PREFIX=#{prefix}"
    end
    
    ohai "Installing headers and documentation..."
    include.install "Knoodle.hpp"
    (include/"knoodle").install Dir["src/*.hpp"]
    doc.install "README.md" if File.exist?("README.md")
    
    ohai "Installation complete!"
    puts "Test with: #{bin}/polyfold --help"
    puts "           #{bin}/knoodletool --help"
  end
  
  test do
    system "#{bin}/polyfold", "--help"
    system "#{bin}/knoodletool", "--help"
  end
  
  def caveats
    os_name = OS.mac? ? "macOS" : "Linux"
    compiler_info = if OS.linux?
      "Homebrew LLVM/clang to ensure ABI compatibility with dependencies"
    else
      "system clang"
    end
    
    <<~EOS
      IMPORTANT: This formula requires Git LFS to clone the repository.
      
      If installation fails with Git LFS errors, please run:
      
        brew install git-lfs
        git lfs install
        
      Then retry the installation with:
      
        brew install knoodle
      
      Knoodle has been installed with both tools optimized for #{os_name} using #{compiler_info}:
      
      PolyFold (knot-tightening):
        #{bin}/polyfold
        
      KnoodleTool (knot theory utilities):
        #{bin}/knoodletool
      
      Note: On Linux, this formula uses Homebrew's LLVM to ensure ABI compatibility
      with dependencies like Boost. All components are compiled from source with
      CPU-specific optimizations for maximum performance.
      
      Header files have been installed to:
        #{include}/knoodle/
    EOS
  end
end
