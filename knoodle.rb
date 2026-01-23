require_relative "lib/custom_download_strategy"

class Knoodle < Formula
  desc "Computational knot theory library with PolyFold and KnoodleTool"
  homepage "https://github.com/HenrikSchumacher/Knoodle"

  url "https://github.com/HenrikSchumacher/Knoodle.git",
      tag:      "v0.3.4-alpha",
      revision: "c3a812751941d951e6ae02cafbf715df73c39a4c",
      using:    GitLFSDownloadStrategy
  license "MIT"

  head "https://github.com/HenrikSchumacher/Knoodle.git", branch: "main"

  pour_bottle? do
    reason "This formula requires CPU-specific optimizations for maximum performance"
    satisfy { false }
  end

  depends_on "boost"
  depends_on "clp"
  depends_on "git-lfs"
  depends_on "llvm" if OS.linux?
  depends_on "metis"
  depends_on "suite-sparse"

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
      ENV["CXX"] = ENV.cxx
      ENV["CC"] = ENV.cc
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
