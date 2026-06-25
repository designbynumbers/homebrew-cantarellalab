require_relative "lib/custom_download_strategy"

class Knoodle < Formula
  desc "Computational knot theory library with PolyFold and the knoodle tools"
  homepage "https://github.com/HenrikSchumacher/Knoodle"

  url "https://github.com/HenrikSchumacher/Knoodle.git",
      tag:      "v1.0.1",
      revision: "8ed1c3fa3b8d59015053fb50d290a0f7343a2eb9",
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

  # Build with Homebrew's recent gcc on Linux instead of the system g++. The
  # system gcc on the runner (13/14) trips a function_traits<bool*> instantiation
  # in PolyFold that newer gcc (15/16, which builds fine on Henrik's machine)
  # may not. See HenrikSchumacher/Knoodle#15.
  on_linux do
    depends_on "gcc"
  end

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

    # The makefiles hardcode `CXX = g++` on Linux, so the compiler must be
    # overridden on the make command line (not via ENV). On Linux, point it at
    # Homebrew's gcc (g++-NN); on macOS keep the configured clang.
    make_args = []
    if OS.mac?
      ENV["CXX"] = ENV.cxx
      ENV["CC"] = ENV.cc
    else
      gcc = Formula["gcc"]
      ver = gcc.version.major
      # System gcc 13/14 on the runner hits a function_traits<bool*> error in
      # PolyFold that Homebrew gcc 16 doesn't. (Henrik fixed the separate gcc-16
      # -Wchanges-meaning issue in 8ed1c3f, so no suppression flag is needed.)
      make_args << "CXX=#{gcc.opt_bin}/g++-#{ver}"
      make_args << "CC=#{gcc.opt_bin}/gcc-#{ver}"
      ohai "Building with Homebrew gcc: #{make_args.join(" ")}"
    end

    # Build and install PolyFold
    ohai "Building PolyFold (knot-tightening tool)..."
    cd "PolyFold" do
      system "make", *make_args
      system "make", "install", "PREFIX=#{prefix}", *make_args
    end

    # Build and install the knoodle command-line tools
    # (knoodlesimplify, knoodledraw, knoodleidentify)
    ohai "Building knoodle tools (simplify / draw / identify)..."
    cd "tools" do
      system "make", *make_args
      system "make", "install", "PREFIX=#{prefix}", *make_args
    end

    ohai "Installing headers and documentation..."
    include.install "Knoodle.hpp"
    (include/"knoodle").install Dir["src/*.hpp"]
    doc.install "README.md" if File.exist?("README.md")

    ohai "Installation complete!"
    puts "Test with: #{bin}/polyfold --help"
    puts "           #{bin}/knoodlesimplify --help"
    puts "           #{bin}/knoodledraw --help"
    puts "           #{bin}/knoodleidentify --help"
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

      Knoodle has been installed with all tools optimized for #{os_name} using #{compiler_info}:

      PolyFold (knot-tightening):
        #{bin}/polyfold

      knoodle tools (knot theory utilities):
        #{bin}/knoodlesimplify   simplify knot/link diagrams to PD codes
        #{bin}/knoodledraw       render diagrams as ASCII/Unicode art
        #{bin}/knoodleidentify   identify knot types via the KLUT

      Note: On Linux, this formula uses system gcc for compatibility with standard
      Homebrew packages, providing fast installation with CPU-specific optimizations.

      Header files have been installed to:
        #{include}/knoodle/
    EOS
  end

  test do
    # polyfold returns non-zero after printing `--help` (a known issue), so we
    # exercise a real sampler run instead: generate a couple of 8-edge samples
    # with the squared-gyradius statistic and confirm it writes its report.
    system "#{bin}/polyfold", "-n", "8", "-N", "2", "-b", "2", "-s", "1", "-g", "-o", testpath
    assert_path_exists testpath/"Info.m"

    system "#{bin}/knoodlesimplify", "--help"
    system "#{bin}/knoodledraw", "--help"
    system "#{bin}/knoodleidentify", "--help"
  end
end
