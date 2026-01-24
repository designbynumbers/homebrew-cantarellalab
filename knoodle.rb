require_relative "lib/custom_download_strategy"

class Knoodle < Formula
  desc "Computational knot theory library with PolyFold and KnoodleTool"
  homepage "https://github.com/HenrikSchumacher/Knoodle"

  url "https://github.com/HenrikSchumacher/Knoodle.git",
      tag:      "v0.3.34-alpha",
      revision: "bf4dac3020ef49c536d728782e1c7a42cdbaf444",
      using:    KnoodleGitLFSDownloadStrategy
  license "MIT"

  head "https://github.com/HenrikSchumacher/Knoodle.git", branch: "main"

  pour_bottle? do
    reason "This formula requires CPU-specific optimizations for maximum performance"
    satisfy { false }
  end

  depends_on "boost"
  depends_on "clp"
  depends_on "git-lfs"
  depends_on "metis"
  depends_on "suite-sparse"

  def install
    # Warn users about potentially long compilation time
    if OS.linux?
      ohai "Linux detected: Building with system gcc for ecosystem compatibility"
      ohai "This installation may take 5-10 minutes (using standard packages)"
      puts ""
    end

    ohai "Cloning repository and initializing submodules..."
    system "git", "submodule", "update", "--init", "--recursive", "--depth", "1"

    env :std

    ENV["KNOODLE_VERSION"] = version.to_s
    ENV["HOMEBREW_PREFIX"] = HOMEBREW_PREFIX

    # Use system compilers (no special setup needed)
    if OS.mac?
      # On macOS, use system clang
      ENV["CXX"] = ENV.cxx
      ENV["CC"] = ENV.cc
    end
    # On Linux, just use default gcc (no special ENV setup needed)

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

  def caveats
    os_name = OS.mac? ? "macOS" : "Linux"
    compiler_info = if OS.linux?
      "system gcc for ecosystem compatibility"
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

      Note: On Linux, this formula uses system gcc for compatibility with standard
      Homebrew packages, providing fast installation with CPU-specific optimizations.

      Header files have been installed to:
        #{include}/knoodle/
    EOS
  end

  test do
    system "#{bin}/polyfold", "--help"
    system "#{bin}/knoodletool", "--help"
  end
end
