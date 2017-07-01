import std.stdio;
import std.file;
import pegged.grammar;
import parser;
import codegen;
import jit;
import pegged.tohtml;
alias void function() func;
void main(){
    auto f = File("test.BASIC","r");
    auto text =readText("test.BASIC");
    auto tree = BASIC(text);
    writeln(tree);
    auto gen = new CodeGen();
    gen.genRoot(tree);
    auto jit = new JIT();
    jit.compileModule(gen.module_);
    auto fn = cast(func) jit.getSymbolAddress("mainFunc");
    fn();


}