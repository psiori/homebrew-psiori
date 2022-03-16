class ClangTidy < Formula
  desc "Clang-based C++ linter tool"
  homepage "https://clang.llvm.org/docs/ClangFormat.html"
  # The LLVM Project is under the Apache License v2.0 with LLVM Exceptions
  license "Apache-2.0"
  version_scheme 1
  head "https://github.com/llvm/llvm-project.git", branch: "main"

  stable do
    url "https://github.com/llvm/llvm-project/releases/download/llvmorg-13.0.1/llvm-13.0.1.src.tar.xz"
    sha256 "ec6b80d82c384acad2dc192903a6cf2cdbaffb889b84bfb98da9d71e630fc834"

    resource "clang" do
      url "https://github.com/llvm/llvm-project/releases/download/llvmorg-13.0.1/clang-13.0.1.src.tar.xz"
      sha256 "787a9e2d99f5c8720aa1773e4be009461cd30d3bd40fdd24591e473467c917c9"
    end

    resource "clang-tools-extra" do
      url "https://github.com/llvm/llvm-project/releases/download/llvmorg-13.0.1/clang-tools-extra-13.0.1.src.tar.xz"
      sha256 "cc2bc8598848513fa2257a270083e986fd61048347eccf1d801926ea709392d0"
    end
  end

  depends_on "cmake" => :build

  uses_from_macos "libxml2"
  uses_from_macos "ncurses"
  uses_from_macos "python", since: :catalina
  uses_from_macos "zlib"

  on_linux do
    keg_only "it conflicts with llvm"
  end

  def install
    if build.head?
      ln_s buildpath/"clang", buildpath/"llvm/tools/clang"
      ln_s buildpath/"clang-tools-extra", buildpath/"llvm/tools/clang-tools-extra"
    else
      (buildpath/"tools/clang").install resource("clang")
      (buildpath/"tools/clang/tools/extra").install resource("clang-tools-extra")
      # maybe use -DLLVM_EXTERNAL_CLANG_TOOLS_EXTRA_SOURCE_DIR instead of
      # abusing the directory hierachy like this?
    end

    llvmpath = build.head? ? buildpath/"llvm" : buildpath

    mkdir llvmpath/"build" do
      args = std_cmake_args
      args << "-DCMAKE_BUILD_TYPE=MinSizeRel"
      args << "-DLLVM_EXTERNAL_PROJECTS=\"clang;clang-tools-extra\""
      args << ".."
      system "cmake", *args
      system "make", "clang-tidy"
    end

    bin.install llvmpath/"build/bin/clang-tidy"
  end

  test do
    assert_equal "13.0.1",
      shell_output("#{bin}/clang-tidy --version | head -n2 | tail -n1 | cut -d" " -f5")
  end
end
