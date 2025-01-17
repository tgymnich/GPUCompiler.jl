using GPUCompiler, LLVM
GPUCompiler.reset_runtime()

using InteractiveUtils
@info "System information:\n" * sprint(io->versioninfo(io; verbose=true))

using ReTestItems
runtests(GPUCompiler; nworkers=min(Sys.CPU_THREADS,4), nworker_threads=1,
                      testitem_timeout=120) do ti
    if ti.name == "GCN" && LLVM.is_asserts()
        # XXX: GCN's non-0 stack address space triggers LLVM assertions due to Julia bugs
        return false
    end

    @dispose ctx=Context() begin
        # XXX: some back-ends do not support opaque pointers
        if ti.name in ["Metal"] && !supports_typed_pointers(ctx)
            return false
        end
    end

    if ti.name in ["PTX", "GCN"] && Sys.isapple() && VERSION >= v"1.10-"
        # support for AMDGPU and NVTX on macOS has been removed from Julia's LLVM build
        return false
    end

    true
end
