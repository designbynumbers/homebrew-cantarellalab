require_relative "lib/custom_download_strategy"

class Knoodle < Formula
  desc "Computational knot theory library with PolyFold and KnoodleTool"
  homepage "https://github.com/HenrikSchumacher/Knoodle"

  url "https://github.com/HenrikSchumacher/Knoodle.git",
      tag:      "v0.3.45-alpha",
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
    # Platform info
    if OS.linux?
      ohai "Linux detected: Building with system gcc for ecosystem compatibility"
      ohai "This installation may take 5-10 minutes (using standard packages)"
    end

    ohai "Cloning repository and initializing submodules..."

    # CRITICAL: Convert SSH submodule URLs to HTTPS before submodule init
    # This is essential for WSL2, Docker, Linux VMs without SSH keys
    if File.exist?(".gitmodules")
      ohai "Converting SSH submodule URLs to HTTPS for universal compatibility..."

      gitmodules_content = File.read(".gitmodules")

      # Show current URLs
      ohai "Current .gitmodules URLs:"
      gitmodules_content.lines.each do |line|
        puts "  #{line.strip}" if line.include?("url =")
      end

      original_content = gitmodules_content.dup

      # Convert SSH URLs to HTTPS
      # Pattern 1: git@github.com:user/repo.git or git@github.com:user/repo
      gitmodules_content.gsub!(%r{git@github\.com:([^/\s]+/[^/\s]+?)(\.git)?(\s*)$}m, 'https://github.com/\1\3')
      # Pattern 2: ssh://git@github.com/user/repo.git or ssh://git@github.com/user/repo
      gitmodules_content.gsub!(%r{ssh://git@github\.com/([^/\s]+/[^/\s]+?)(\.git)?(\s*)$}m, 'https://github.com/\1\3')

      if gitmodules_content == original_content
        ohai "No SSH URLs found - no conversion needed"
      else
        File.write(".gitmodules", gitmodules_content)
        ohai "Converted SSH URLs to HTTPS:"
        gitmodules_content.lines.each do |line|
          puts "  #{line.strip}" if line.include?("url =")
        end
        # Sync changes to .git/config
        system "git", "submodule", "sync"
      end
    else
      ohai "No .gitmodules file found"
    end

    system "git", "submodule", "update", "--init", "--recursive", "--depth", "1"

    env :std

    ENV["KNOODLE_VERSION"] = version.to_s
    ENV["HOMEBREW_PREFIX"] = HOMEBREW_PREFIX

    if OS.mac?
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
