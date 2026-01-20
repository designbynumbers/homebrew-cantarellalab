# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
require_relative "lib/custom_download_strategy"

class Knoodle < Formula
  desc "Computational knot theory library with PolyFold knot-tightening and KnoodleTool utilities"
  homepage "https://github.com/HenrikSchumacher/Knoodle"
  
  # Use git with submodules for the stable version
  url "https://github.com/HenrikSchumacher/Knoodle.git",
      tag: "v0.3.0-alpha",
      revision: "c2379d4fff74504b42492783bdcb45c6e0e7ea79",  # Replace with the actual commit SHA for this tag
      using: GitLFSDownloadStrategy
  version "0.3.0-alpha"
  license "MIT"
  
  # For head builds (brew install --HEAD knoodle)
  head "https://github.com/HenrikSchumacher/Knoodle.git", branch: "main"
  
  depends_on "boost"
  depends_on "metis"
  depends_on "clp" 
  depends_on "suite-sparse"  # Provides umfpack needed by knoodletool
  depends_on "git-lfs"  # Required for cloning repository with LFS files
  
  # Prevent bottle usage - require building from source for performance
  pour_bottle? do
    reason "This formula requires CPU-specific optimizations for maximum performance"
    satisfy { false }
  end
  
  def install
    # Handle submodules - required for KnoodleTool's include paths
    system "git", "submodule", "update", "--init", "--recursive", "--depth", "1"
    
    # Use standard environment to avoid superenv performance issues
    env :std
    
    # Pass version to the Makefiles
    ENV["KNOODLE_VERSION"] = version.to_s
    ENV["HOMEBREW_PREFIX"] = HOMEBREW_PREFIX
    
    # Build and install PolyFold
    cd "PolyFold" do
      system "make"
      system "make", "install", "PREFIX=#{prefix}"
    end
    
    # Build and install KnoodleTool
    cd "KnoodleTool" do
      system "make"
      system "make", "install", "PREFIX=#{prefix}"
    end
    
    # Install library headers
    include.install "Knoodle.hpp"
    (include/"knoodle").install Dir["src/*.hpp"]
    
    # Install documentation if it exists
    doc.install "README.md" if File.exist?("README.md")
  end
  
  test do
    # Test that both tools run and show help
    system "#{bin}/polyfold", "--help"
    system "#{bin}/knoodletool", "--help"
  end
  
  def caveats
    <<~EOS
      IMPORTANT: This formula requires Git LFS to clone the repository.
      
      If installation fails with "git-lfs: command not found", please run:
      
        brew install git-lfs
        git lfs install
        
      Then retry the installation with:
      
        brew install cantarellalab/cantarellalab/knoodle
      
      Knoodle has been installed with both tools:
      
      PolyFold (knot-tightening):
        #{bin}/polyfold
        
      KnoodleTool (knot theory utilities):
        #{bin}/knoodletool
      
      Note: Both tools are always compiled from source with CPU-specific 
      optimizations for maximum performance.
      
      Header files have been installed to:
        #{include}/knoodle/
    EOS
  end
end
