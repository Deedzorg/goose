// Goose compiler — `goose build` (docs/design/packages.md §6): the C the
// compiler wrote, the runtime object and the native modules' response files,
// compiled and linked into an executable by the toolchain of toolchain.h.
// Intermediates live under GOOSE_HOME; the executable lands beside the root
// source unless -o says otherwise.
#pragma once

namespace goose {

// In main.cpp: the runtime's text hash, the runtime object's C, and a path's directory.
string RuntimeVersion();
string RuntimeObjectSource();
string DirOf(const string &path);

struct BuildOptions {
    bool debug = false;       // --debug: GS_DEBUG=1, debug information, no C optimization
    bool verbose = false;     // -v: print every command and what it prints
    bool dryrun = false;      // --dry-run: print the commands and run nothing
    bool standalone = false;  // --standalone: no runtime object
    string exe;               // -o: the executable; "" puts it beside the root source
    bool noharden = false;    // --no-harden: none of Builder's hardening flags

    // Whether the C is built with the hardening flags: an optimized build,
    // unless --no-harden. A --debug build is for a debugger, and keeps its
    // flags as they were.
    bool Harden() const { return !debug && !noharden; }
};

inline string AbsolutePath(const string &path) {
    std::error_code ec;
    auto abs = filesystem::absolute(filesystem::path(path), ec);
    return ec ? path : abs.lexically_normal().string();
}

// GOOSE_HOME/build/prog/<stem>-<hash of the root's absolute path>/: where a
// program's C, objects and logs go.
inline string ProgramBuildDir(const string &rootfile) {
    auto abs = AbsolutePath(rootfile);
    #ifdef _WIN32
        for (auto &c : abs) c = (char)tolower((unsigned char)c);   // One directory per file, however spelled.
    #endif
    return cat(GooseHome(), "/build/prog/", PathStem(rootfile), "-", Hex8(abs));
}

// Runs the toolchain's commands, printing them as -v and --dry-run ask, and
// a failed one with what it printed.
struct Builder {
    const Toolchain &tc;
    const BuildOptions &opts;
    FILE *msgs;

    // The compile flags of both styles: optimization, or debug information
    // and none of it, then the hardening ones. Defines go into the C itself
    // (main.cpp), never here.
    vector<string> CFlags() const {
        vector<string> f;
        if (tc.style == "msvc") {
            f.push_back("/nologo");
            if (opts.debug) f.push_back("/Od"), f.push_back("/Zi");
            else f.push_back("/O2");
        } else if (opts.debug) {
            f = { "-O0", "-g" };
        } else {
            f = { "-O2" };
        }
        for (auto &h : HardenCFlags()) f.push_back(h);
        return f;
    }

    // Goose code needs none of these: its checks come before any C. They
    // guard the runtime and the C a program calls through extern fn
    // (docs/command_line.md, "Hardened builds"). MSVC already gives stack
    // cookies, ASLR and DEP by default; Control Flow Guard checks indirect
    // calls. On ELF the stack protector, checked libc calls and a
    // position-independent executable, so ASLR moves the program too. A
    // package's -fPIC, later on its command line, wins over -fPIE. Nothing
    // for a gcc-style compiler on Windows, where MinGW's stack protector
    // needs a library of its own.
    vector<string> HardenCFlags() const {
        if (!opts.Harden()) return {};
        if (tc.style == "msvc") return { "/guard:cf" };
        #ifdef _WIN32
            return {};
        #else
            // Level 3 checks more calls, from gcc 12 and clang 16 with
            // glibc; some distributions' compilers default to it, and a 2
            // would lower it. Apple's clang numbers its versions its own way.
            auto major = atoi(tc.version.c_str());
            auto fortify3 = (tc.name == "gcc" && major >= 12) || (tc.name == "clang" && major >= 16);
            #ifdef __APPLE__
                fortify3 = false;
            #endif
            vector<string> f = { "-fstack-protector-strong", "-U_FORTIFY_SOURCE",
                                 fortify3 ? "-D_FORTIFY_SOURCE=3" : "-D_FORTIFY_SOURCE=2" };
            #ifndef __APPLE__
                f.push_back("-fPIE");
                #if defined(__x86_64__) || defined(__i386__)
                    f.push_back("-fcf-protection");
                #endif
            #endif
            return f;
        #endif
    }

    // What the executable's link adds when hardened: Control Flow Guard's
    // tables and the CET shadow stack mark on Windows (cl passes what
    // follows /link to the linker, so these go last), a PIE whose
    // relocations are made read-only before main on ELF. macOS links PIE
    // already, and its linker has no -z.
    vector<string> HardenLinkFlags() const {
        if (!opts.Harden()) return {};
        if (tc.style == "msvc") {
            #if defined(_M_X64) || defined(_M_IX86)
                return { "/link", "/guard:cf", "/CETCOMPAT" };
            #else
                return { "/link", "/guard:cf" };
            #endif
        }
        #if defined(_WIN32) || defined(__APPLE__)
            return {};
        #else
            return { "-pie", "-Wl,-z,relro,-z,now" };
        #endif
    }

    // The system libraries a program links beyond the C library, in the cc
    // style: none on Windows, where they live in the C runtime.
    vector<string> SystemLibs() const {
        #ifdef _WIN32
            return {};
        #else
            if (tc.style == "msvc") return {};
            vector<string> libs = { "-lm", "-pthread" };
            #ifdef __linux__
                // dlopen, for the runtime's dynamic externs: in libdl before
                // glibc 2.34, and in libc since, where the archive left
                // behind is empty.
                libs.push_back("-ldl");
            #endif
            return libs;
        #endif
    }

    // Runs `argv`, `what` being what it does ("compiling the runtime"), with
    // its output kept in `logfile`. False when it failed, after saying so.
    bool Run(const vector<string> &argv, const string &what, const string &logfile) const {
        if (opts.dryrun || opts.verbose) fprintf(msgs, "%s\n", CommandLineText(argv).c_str());
        if (opts.dryrun) return true;
        fflush(msgs);
        ProcessResult r;
        {
            ProgressStep step(what);
            r = RunProcess(argv, "", opts.verbose);
        }
        if (!logfile.empty()) WriteFileMakingDirs(logfile, r.output);
        if (r.started && r.code == 0) return true;
        auto msg = cat(what, " failed", r.started ? cat(" (exit ", r.code, ")") : string(), ":\n    ",
                       CommandLineText(argv), "\n");
        if (!opts.verbose) msg += r.output;
        if (!logfile.empty())
            Append(msg, msg.back() == '\n' ? "" : "\n", "(the output is in ", logfile, ")");
        ProgressPrint(msg);
        return false;
    }

    // A system library by name, as the style's linker takes it.
    string LibFlag(const string &lib) const {
        return tc.style == "msvc" ? cat(lib, ".lib") : cat("-l", lib);
    }

    // Compiles the C file `src` to the object `obj`, with `extra` flags
    // (a package's includes and defines) after the usual ones.
    bool CompileObject(const string &src, const string &obj, const string &what,
                       const string &logfile, const vector<string> &extra = {}) const {
        vector<string> argv = { tc.cc };
        for (auto &f : CFlags()) argv.push_back(f);
        for (auto &f : extra) argv.push_back(f);
        if (tc.style == "msvc") {
            argv.push_back("/c");
            argv.push_back(src);
            argv.push_back(cat("/Fo:", obj));
            if (opts.debug) argv.push_back(cat("/Fd:", obj, ".pdb"));
        } else {
            argv.push_back("-c");
            argv.push_back(src);
            argv.push_back("-o");
            argv.push_back(obj);
        }
        return Run(argv, what, logfile);
    }

    // Links `objects` and the system libraries `libs` (LibFlag spellings)
    // into the shared library `out`, with `builddir` taking the
    // intermediates: a package's JIT library.
    bool LinkShared(const vector<string> &objects, const vector<string> &libs, const string &out,
                    const string &builddir, const string &logfile, const string &what) const {
        vector<string> argv = { tc.cc };
        if (tc.style == "msvc") {
            argv.push_back("/nologo");
            argv.push_back("/LD");
            argv.push_back(cat("/Fe:", out));
            argv.push_back(cat("/Fo:", builddir, "\\"));
            for (auto &o : objects) argv.push_back(o);
            for (auto &l : libs) argv.push_back(l);
        } else {
            argv.push_back("-shared");
            for (auto &o : objects) argv.push_back(o);
            argv.push_back("-o");
            argv.push_back(out);
            for (auto &l : libs) argv.push_back(l);
            for (auto &l : SystemLibs()) argv.push_back(l);
        }
        return Run(argv, what, logfile);
    }

    // Compiles `src` and links it with `objects` and the response files
    // `rsps` into `exe`, with `builddir` taking the intermediates.
    bool Link(const string &src, const vector<string> &objects, const vector<string> &rsps,
              const string &exe, const string &builddir, const string &logfile) const {
        vector<string> argv = { tc.cc };
        for (auto &f : CFlags()) argv.push_back(f);
        if (tc.style == "msvc") {
            argv.push_back(cat("/Fe:", exe));
            argv.push_back(cat("/Fo:", builddir, "\\"));
            if (opts.debug) argv.push_back(cat("/Fd:", builddir, "\\", PathStem(exe), ".pdb"));
            argv.push_back(src);
            for (auto &o : objects) argv.push_back(o);
            for (auto &r : rsps) argv.push_back(cat("@", r));
        } else {
            argv.push_back(src);
            for (auto &o : objects) argv.push_back(o);
            argv.push_back("-o");
            argv.push_back(exe);
            for (auto &r : rsps) argv.push_back(cat("@", r));
            for (auto &l : SystemLibs()) argv.push_back(l);
        }
        for (auto &f : HardenLinkFlags()) argv.push_back(f);
        return Run(argv, cat("building ", exe), logfile);
    }
};

// The runtime object for this toolchain and configuration, compiled from
// `goose --emit-runtime`'s C on first use: GOOSE_HOME/build/runtime/<runtime
// hash>/<toolchain id>-<config>/goose_runtime.o, the config being debug,
// hardened, or release for --no-harden (what an optimized build was before
// hardening). "" when it could not be built, after the builder said why.
inline string RuntimeObject(const Builder &b) {
    auto dir = cat(GooseHome(), "/build/runtime/", RuntimeVersion(), "/", b.tc.id, "-",
                   b.opts.debug ? "debug" : b.opts.Harden() ? "hardened" : "release");
    auto obj = cat(dir, "/goose_runtime.", b.tc.style == "msvc" ? "obj" : "o");
    if (PathExists(obj) && !b.opts.dryrun) return obj;
    auto src = cat(dir, "/goose_runtime.c");
    auto log = cat(dir, "/cc.log");
    if (b.opts.dryrun) {
        b.CompileObject(src, obj, "compiling the runtime", log);
        return obj;
    }
    std::error_code ec;
    filesystem::create_directories(filesystem::path(dir), ec);
    if (ec) throw CompileError { cat("cannot create ", dir, ": ", ec.message()) };
    // Every first build shares these paths. Wait before writing the source
    // or invoking the compiler, then recheck what the previous builder left.
    FileLock lock(cat(dir, "/build.lock"), "waiting for another goose compiling the runtime");
    if (PathExists(obj)) return obj;
    ProgressStep step(cat("compiling the runtime for ", b.tc.desc), true);
    if (!WriteFileMakingDirs(src, RuntimeObjectSource()))
        throw CompileError { cat("cannot write ", src) };
    // A failed or interrupted compiler may leave a partial object. Only a
    // successful compile publishes the name readers use, by atomic rename.
    auto tmp = cat(dir, "/goose_runtime.tmp.", b.tc.style == "msvc" ? "obj" : "o");
    filesystem::remove(filesystem::path(tmp), ec);
    if (ec) throw CompileError { cat("cannot remove ", tmp, ": ", ec.message()) };
    if (!b.CompileObject(src, tmp, "compiling the runtime", log)) return "";
    ec = RenamePath(tmp, obj);
    if (ec) throw CompileError { cat("cannot publish ", obj, ": ", ec.message()) };
    return obj;
}

// What `goose build` does once the compiler has written the program's C to
// `cfile` in `builddir`: finds the runtime object for the toolchain `tc`,
// which built the native parts whose response files are `nativersps`
// (native.h and builtin.h, found by the caller) in link order, a package's
// before the packages it requires and the program's own C first of all, and
// links the executable, named by -o, the program's sidecar (`output`) or the
// root file. The exit code.
inline int BuildExecutable(const string &rootfile, const string &cfile, const string &builddir,
                           const Toolchain &tc, const BuildOptions &opts, FILE *msgs,
                           const vector<string> &nativersps, const string &output) {
    Builder b { tc, opts, msgs };
    vector<string> objects;
    if (!opts.standalone) {
        auto obj = RuntimeObject(b);
        if (obj.empty()) return 1;
        objects.push_back(obj);
    }
    auto exe = opts.exe;
    if (exe.empty()) {
        exe = cat(DirOf(rootfile), output.empty() ? PathStem(rootfile) : output);
        #ifdef _WIN32
            if (exe.size() < 4 || exe.compare(exe.size() - 4, 4, ".exe") != 0) exe += ".exe";
        #endif
    }
    if (!opts.dryrun) {
        std::error_code ec;
        auto exedirpath = filesystem::path(exe).parent_path();
        if (!exedirpath.empty()) filesystem::create_directories(exedirpath, ec);
    }
    if (!b.Link(cfile, objects, nativersps, exe, builddir, cat(builddir, "/cc.log"))) return 1;
    if (!opts.dryrun) fprintf(msgs, "built %s\n", exe.c_str());
    return 0;
}

}  // namespace goose
