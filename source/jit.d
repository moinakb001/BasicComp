import llvm;
import std.string;
import std.conv;
import core.memory;
import std.stdio;
import variables;
import core.stdc.stdlib;
//extern(C) __gshared string[] rt_options = [ "gcopt=initReserve:100 profile:1" ];
class JIT{
    /// The LLVM ORC JIT Stack
    LLVMOrcJITStackRef  jitStack;

    /// Initialize JIT Stack for Native Machine
    this(){
        LLVMInitializeAllTargetInfos();
        LLVMInitializeAllTargets();
        LLVMInitializeAllTargetMCs();
        LLVMInitializeAllAsmPrinters();
        LLVMInitializeAllAsmParsers();
        auto target = LLVMGetFirstTarget();
        auto mach = target.LLVMCreateTargetMachine("x86_64-unknown-linux-gnu".toStringz(),"".toStringz(),"".toStringz(), LLVMCodeGenLevelDefault , LLVMRelocDefault, LLVMCodeModelDefault  );
        jitStack = LLVMOrcCreateInstance(mach);
    };

    LLVMOrcModuleHandle  compileModule (LLVMModuleRef Mod ){
        return jitStack.LLVMOrcAddEagerlyCompiledIR(Mod, &symbolResolver, cast(void *)this);
    }
    void* getSymbolAddress(string str){
        return cast(void*)jitStack.LLVMOrcGetSymbolAddress(str.toStringz());
    }
    static void println(varMD num){
        if(num.type==varType.Float){
            writeln(num.fp);
        }
        else{
            writeln(to!string(num.ptr));
          

        }
    }
    extern (C) static ulong symbolResolver(const(char)* Name, void* LookupCtx){
        auto jit = cast(JIT*) LookupCtx;
        string name = to!string(Name);
        switch(name){
            case "println":
                return cast(ulong)&println;
            case "malloc":
                return cast(ulong)&malloc;
            case "free":
                return cast(ulong)&free;
            default:
                return 0;

        }
    }

}