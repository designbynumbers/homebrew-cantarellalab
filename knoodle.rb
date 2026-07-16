class Knoodle < Formula
  desc "Command-line knot-theory tools: PolyFold and the knoodle utilities"
  homepage "https://github.com/HenrikSchumacher/Knoodle"

  # Self-contained vendored source tarball, built by scripts/make-source-tarball.sh
  # and attached to the GitHub release: submodules baked in, the pcg-cpp dep
  # vendored, the KLUT data included, and NO Git-LFS. This replaces the old
  # git+LFS+submodule clone -- so no git-lfs dependency, no SSH-submodule URL
  # rewriting, and no Git-LFS bandwidth billed to the source repo.
  url "https://github.com/HenrikSchumacher/Knoodle/releases/download/v1.0.6/knoodle-1.0.6-vendored.tar.gz"
  sha256 "0b8e97ecf68a6a4827fd700f1f1f7e3b5ada4d905de99923922aa0753fcfd5e9"
  license "MIT"

  pour_bottle? do
    reason "This formula requires CPU-specific optimizations for maximum performance"
    satisfy { false }
  end

  depends_on "boost"
  depends_on "clp"
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
    if OS.linux?
      ohai "Linux detected: building with Homebrew gcc for a recent C++ toolchain"
      ohai "This installation may take 5-10 minutes"
    end

    # The vendored tarball is already a complete source tree: submodules and the
    # pcg-cpp dep are baked in, the KLUT data is included, and there is no Git-LFS
    # or .gitmodules. So there is nothing to clone, init, or URL-rewrite here --
    # build directly from the extracted sources.

    env :std

    ENV["KNOODLE_VERSION"] = version.to_s
    ENV["HOMEBREW_PREFIX"] = HOMEBREW_PREFIX

    # The makefiles hardcode CXX with a plain `=` (PolyFold/makefile on macOS
    # pins an absolute, machine-specific llvm@18 path as of Knoodle 1.0.3 --
    # see HenrikSchumacher/Knoodle upstream handoff), so the compiler must be
    # overridden on the make command line, not via ENV: command-line make vars
    # beat a Makefile's own `=` assignment, but ENV vars don't. On Linux, point
    # it at Homebrew's gcc (g++-NN); on macOS, force the configured clang.
    make_args = []
    if OS.mac?
      ENV["CXX"] = ENV.cxx
      ENV["CC"] = ENV.cc
      make_args << "CXX=#{ENV.cxx}"
      make_args << "CC=#{ENV.cc}"
    else
      gcc = Formula["gcc"]
      ver = gcc.version.major
      # System gcc 13/14 on the runner hits a function_traits<bool*> error in
      # PolyFold that Homebrew gcc 16 doesn't. (The separate gcc-16 -Wchanges-meaning
      # issue is already fixed upstream, so no suppression flag is needed.)
      make_args << "CXX=#{gcc.opt_bin}/g++-#{ver}"
      make_args << "CC=#{gcc.opt_bin}/gcc-#{ver}"
      ohai "Building with Homebrew gcc: #{make_args.join(" ")}"
    end

    # Low-memory guard. Each binary is a single huge -O3 -march=native C++20
    # translation unit over heavily-templated headers (Tensors, MCFClass, Boost),
    # so one g++ process can need several GB of RAM. WSL2 defaults to ~50% of host
    # RAM, so a modest laptop can OOM-kill cc1plus mid-compile -- a failure CI's
    # 16 GB runners never see. Warn up front when available memory looks tight.
    if OS.linux? && (avail_gb = available_memory_gb) && avail_gb < 4.0
      opoo format("Only %.1f GB of RAM is available.", avail_gb)
      opoo "This build compiles each tool as one large g++ process and may be"
      opoo "OOM-killed. If it fails, see the memory guidance printed below."
    end

    # Build and install PolyFold, then the knoodle command-line tools
    # (knoodlesimplify, knoodledraw, knoodleidentify). On Linux a killed compiler
    # is almost always an out-of-memory kill, so add memory guidance to any build
    # failure before letting Homebrew's error propagate.
    begin
      ohai "Building PolyFold (knot-tightening tool)..."
      cd "PolyFold" do
        system "make", *make_args
        system "make", "install", "PREFIX=#{prefix}", *make_args
      end

      ohai "Building knoodle tools (simplify / draw / identify)..."
      cd "tools" do
        system "make", *make_args
        system "make", "install", "PREFIX=#{prefix}", *make_args
      end
    rescue
      opoo oom_guidance if OS.linux?
      raise
    end

    # NOTE: deliberately NO header installation. Knoodle's headers are not
    # self-contained -- compiling against them needs the full transitive tree of
    # vendored deps (Tensors, submodules, pcg-cpp, ...), which is out of scope for
    # a Homebrew formula. This formula ships only the command-line tools; users who
    # want to build their own Knoodle projects should clone the upstream repo (or
    # add it as a submodule). See the caveats below.
    ohai "Installing documentation..."
    doc.install "README.md" if File.exist?("README.md")

    # Install the KLUT (knot lookup table: Klut_Keys_NN.bin + Klut_Values_NN.tsv
    # pairs, ~23 MB, baked into the vendored tarball) into the standard Homebrew
    # package-data location -- pkgshare, i.e. share/knoodle -> /opt/homebrew/share/knoodle/Klut.
    #
    # As of knoodle 1.0.4+, knoodleidentify resolves its own executable via the OS
    # (macOS _NSGetExecutablePath, Linux /proc/self/exe) rather than trusting argv[0],
    # and its search order includes <exe>/../share/knoodle/Klut. For a keg whose bin/
    # is symlinked into the prefix, that dereferences to exactly this pkgshare dir, so
    # the tool finds the KLUT with no env var and no CWD/argv0 dependence. (Earlier
    # 1.0.x needed an env-script wrapper pinning $KNOODLE_KLUT_DIR because argv[0] was
    # resolved against the CWD; the 1.0.4 real-exe-path fix -- our upstream handoff --
    # makes the wrapper unnecessary, so it's gone.)
    ohai "Installing the KLUT (knot lookup table) for knoodleidentify..."
    pkgshare.install "data/Klut"

    ohai "Installation complete!"
    puts "Test with: #{bin}/polyfold --help"
    puts "           #{bin}/knoodlesimplify --help"
    puts "           #{bin}/knoodledraw --help"
    puts "           #{bin}/knoodleidentify --help"
  end

  def caveats
    os_name = OS.mac? ? "macOS" : "Linux"
    compiler_info = if OS.linux?
      "Homebrew gcc"
    else
      "the system clang"
    end
    linux_note =
      if wsl?
        "\n#{wsl_caveat}\n"
      elsif OS.linux?
        "\n#{memory_caveat}\n"
      else
        ""
      end

    <<~EOS
      Knoodle has been installed with all tools optimized for #{os_name} using #{compiler_info}:

      PolyFold (knot-tightening):
        #{bin}/polyfold

      knoodle tools (knot theory utilities):
        #{bin}/knoodlesimplify   simplify knot/link diagrams to PD codes
        #{bin}/knoodledraw       render diagrams as ASCII/Unicode art
        #{bin}/knoodleidentify   identify knot types via the KLUT

      Note: On Linux this formula builds with Homebrew's gcc (a recent C++ toolchain
      is required). On macOS a recent Apple Clang / libc++ is required: older macOS
      and Xcode (roughly macOS 15 / Clang 17 and earlier) are NOT supported, because
      the build needs the floating-point std::from_chars from a newer libc++.

      This formula installs the command-line tools only, not the C++ headers: the
      Knoodle headers are not self-contained and need the full source tree to compile
      against. To build your own Knoodle-based project, clone the upstream repository
      (or add it as a submodule):
        #{homepage}
      #{linux_note}
    EOS
  end

  # WSL2 defaults to ~50% of host RAM, which can be too little for this
  # template-heavy build. True when running under WSL (WSL2 or WSL1).
  def wsl?
    OS.linux? && (ENV["WSL_DISTRO_NAME"].to_s != "" ||
      (File.readable?("/proc/version") &&
       File.read("/proc/version").match?(/microsoft|WSL/i)))
  end

  # MemAvailable from /proc/meminfo, in GiB, or nil if it can't be read.
  def available_memory_gb
    return unless File.readable?("/proc/meminfo")

    kb = File.read("/proc/meminfo")[/^MemAvailable:\s+(\d+)/, 1].to_i
    kb.positive? ? kb / 1024.0 / 1024.0 : nil
  end

  # Shown after a successful non-WSL Linux install as a heads-up for rebuilds
  # (e.g. `brew install --HEAD`), where a low-RAM machine may OOM-kill the compiler.
  def memory_caveat
    "Building from source is memory-heavy; a low-RAM machine may need extra swap."
  end

  # WSL2-specific guidance, shown after a successful install when running under
  # WSL. Covers the environment quirks that differ from a plain Ubuntu box:
  # WSL version, distro, prefix/filesystem, SSH keys, and the ~50%-RAM OOM trap.
  def wsl_caveat
    <<~EOS.chomp
      Running under WSL:
        * Use WSL 2, not WSL 1 -- WSL 1 has known issues with Homebrew binaries.
        * Ubuntu 24.04 is recommended (Tier 1 Homebrew support); 22.04 also works.
        * Keep Homebrew at its default prefix (/home/linuxbrew/.linuxbrew) and build
          from your Linux home, not a Windows path under /mnt/c.
        * No GitHub SSH key or Git-LFS needed -- the source is a self-contained tarball.
        * Building is memory-heavy. WSL2 defaults to ~50% of host RAM; if a build is
          OOM-killed ("Killed (program cc1plus)"), set a higher limit in
          C:\\Users\\<you>\\.wslconfig under [wsl2] (e.g. "memory=8GB"), run
          "wsl --shutdown" in Windows, then reinstall.
    EOS
  end

  # Printed when a Linux build fails, since a killed compiler is almost always
  # an out-of-memory kill. Tailored for WSL2, where the fix is a host-side limit.
  def oom_guidance
    generic = <<~EOS
      The build may have run out of memory: each tool is one large, heavily
      templated g++ compile that can need several GB of RAM. A failure reading
      "internal compiler error: Killed (program cc1plus)" is an out-of-memory kill.
    EOS

    if wsl?
      generic + <<~EOS

        You appear to be on WSL2, which defaults to ~50% of host RAM. Raise the
        limit by creating C:\\Users\\<you>\\.wslconfig with:

          [wsl2]
          memory=8GB
          swap=8GB

        then run "wsl --shutdown" in Windows PowerShell and reopen your distro
        before retrying `brew install knoodle`.
      EOS
    else
      "#{generic}\nFree up memory (close other apps) or add swap space, then retry.\n"
    end
  end

  test do
    # polyfold returns non-zero after printing `--help` (a known issue), so we
    # exercise a real sampler run instead: generate a couple of 8-edge samples
    # with the squared-gyradius statistic and confirm it writes its report.
    system "#{bin}/polyfold", "-n", "8", "-N", "2", "-b", "2", "-s", "1", "-g", "-o", testpath
    assert_path_exists testpath/"Info.m"

    system "#{bin}/knoodlesimplify", "--help"
    system "#{bin}/knoodledraw", "--help"

    # `--help` does NOT touch the KLUT, so it can't catch a missing-data install.
    # Confirm the lookup table landed in pkgshare, then run knoodleidentify on an
    # empty input file: it resolves + fully loads the KLUT at startup (before reading
    # any diagram), so it exits 0 only if every Klut_*_NN file installed and loads.
    #
    # Run from a scratch CWD that has no data/Klut, with no $KNOODLE_KLUT_DIR set.
    # The KLUT now lives only in pkgshare (no keg-local data/Klut), so the sole
    # candidate that can satisfy the lookup is <exe>/../share/knoodle/Klut resolved
    # from the real executable path -- i.e. this test exercises the 1.0.4+ exe-relative
    # resolution directly, and would go red if that regressed (which is exactly the
    # from-PATH failure the old argv[0] heuristic hid). A broken install aborts with
    # "Could not find KLUT data directory" (non-zero -> this test fails).
    assert_path_exists pkgshare/"Klut/Klut_Values_03.tsv"
    testpath.cd do
      system bin/"knoodleidentify", File::NULL
    end
  end
end
