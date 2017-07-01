import variables;
import llvm;
import parser;
import std.string;
import std.stdio;
import std.conv;
import pegged.grammar;

class CodeGen{
    LLVMModuleRef module_;
    LLVMValueRef mainFunc;
    LLVMBuilderRef builder;
    LLVMPassManagerRef pass;
    LLVMValueRef println;
    LLVMValueRef inputFn;
    LLVMBuilderRef allocB;
    LLVMValueRef[] args;
    void genWhile(ParseTree p, BScope b){
    	auto currBlock = builder.LLVMGetInsertBlock();
    	
        
        auto condBlk = mainFunc.LLVMAppendBasicBlock("condition");
        builder.LLVMPositionBuilderAtEnd(currBlock);
        builder.LLVMBuildBr(condBlk);
        builder.LLVMPositionBuilderAtEnd(condBlk);
        auto exp = genExpression(p.children[0], b);
        
        auto flExp = builder.LLVMBuildBitCast(exp[1], LLVMDoubleType(), "fCmpBitCast".toStringz());
        auto intExp = builder.LLVMBuildFCmp( LLVMRealONE, flExp, LLVMConstReal(LLVMDoubleType(), 0), "FCmp".toStringz());
        auto bodyBlk = mainFunc.LLVMAppendBasicBlock("body");
        auto continueBlk = mainFunc.LLVMAppendBasicBlock("continue");
        builder.LLVMBuildCondBr(intExp, bodyBlk, continueBlk);
        builder.LLVMPositionBuilderAtEnd(bodyBlk);
        
        genScopeBody(p.children[1], new BScope(b));
        writeln("HI");
        builder.LLVMBuildBr(condBlk);
        
        builder.LLVMPositionBuilderAtEnd(continueBlk);
        writeln("HI");
        
        
    }
    void genIf(ParseTree p, BScope b){
    	if(p.name=="BASIC.Else"){
    		genScopeBody(p, new BScope(b));
    	}
        
		auto currBlock = builder.LLVMGetInsertBlock();
        
        
        auto thenBlk = mainFunc.LLVMAppendBasicBlock("then");
        auto elseBlk = mainFunc.LLVMAppendBasicBlock("else");
        auto continueBlk = mainFunc.LLVMAppendBasicBlock("continue");
        
        builder.LLVMPositionBuilderAtEnd(currBlock);
	auto exp = genExpression(p.children[0], b);
		auto flExp = builder.LLVMBuildBitCast(exp[1], LLVMDoubleType(), "fCmpBitCast".toStringz());

        auto intExp = builder.LLVMBuildFCmp( LLVMRealONE, flExp, LLVMConstReal(LLVMDoubleType(), 0), "FCmp".toStringz());
		
        builder.LLVMBuildCondBr(intExp, thenBlk, elseBlk);
        
        builder.LLVMPositionBuilderAtEnd(thenBlk);

        if(p.children[1].name=="BASIC.Statement"){
        	genStatement(p.children[1], new BScope(b));

        }else{
        	genScopeBody(p.children[1], new BScope(b));
        }

        builder.LLVMBuildBr( continueBlk);

        builder.LLVMPositionBuilderAtEnd(elseBlk);
        for(auto i = 2;i<p.children.length;i++){
        	genIf(p.children[i], b);
        }

        builder.LLVMBuildBr( continueBlk);

        builder.LLVMPositionBuilderAtEnd(continueBlk);

        return;
    }
    this(){
        
        module_ = LLVMModuleCreateWithName("mainModule".toStringz());

        mainFunc = module_.LLVMAddFunction(
        "mainFunc",
        LLVMFunctionType(LLVMVoidType(),[LLVMVoidType()].ptr, 0, cast(LLVMBool) false));
        auto genAllocBlk = mainFunc.LLVMAppendBasicBlock( "entry".toStringz());
        auto genEntryBlk = mainFunc.LLVMAppendBasicBlock( "postAlloc".toStringz());
        allocB = LLVMCreateBuilder();
		allocB.LLVMPositionBuilderAtEnd( genAllocBlk);
        allocB.LLVMBuildBr(genEntryBlk);
        
        allocB.LLVMPositionBuilderBefore( genAllocBlk.LLVMGetLastInstruction());
        pass = LLVMCreatePassManager();
    	auto PMBuild = LLVMPassManagerBuilderCreate();
    	PMBuild.LLVMPassManagerBuilderSetOptLevel(3);
    	PMBuild.LLVMPassManagerBuilderPopulateModulePassManager( pass);
    	PMBuild.LLVMPassManagerBuilderDispose();
        builder = LLVMCreateBuilder();
        println = module_.LLVMAddFunction("println", LLVMFunctionType(LLVMVoidType(), [struct_t()].ptr, 1, cast(LLVMBool) false));
        println.LLVMSetLinkage(LLVMExternalLinkage);
        inputFn = module_.LLVMAddFunction("input", LLVMFunctionType(LLVMVoidType(), [struct_t()].ptr, 1, cast(LLVMBool) false));
        inputFn.LLVMSetLinkage(LLVMExternalLinkage);
        builder.LLVMPositionBuilderAtEnd( genEntryBlk);
        

    }
    LLVMTypeRef struct_t(){
        return LLVMStructType([LLVMInt8Type(),LLVMInt64Type()].ptr, 2,cast(LLVMBool) false );
    }
    class BScope{
        BScope parent = null;
        this(BScope parent){
            this.parent=parent;

        }
        LLVMValueRef[string] vars;
        bool hasVar(string var){
            auto temp = var in vars;
            if(parent !is null) return (temp !is null) || parent.hasVar(var);
            return (temp !is null) ;
        }
        void setMember(string var, LLVMValueRef[] val, LLVMBuilderRef builder){
            if(parent !is null){
                if(parent.hasVar(var)){
                    parent.setMember(var, val, builder);
                }
            }
            auto temp = var in vars;

            if(temp is null){
                vars[var] = allocB.LLVMBuildAlloca(struct_t(), "varptrptr".toStringz());
                
            }

			auto typ = builder.LLVMBuildStructGEP( vars[var], 0, ("typeof_"~var~"_ptr").toStringz());

        	auto act = builder.LLVMBuildStructGEP( vars[var], 1, ("valueof_"~var~"_ptr").toStringz());

            builder.LLVMBuildStore(val[0], typ);

            builder.LLVMBuildStore(val[1], act);
        }
        LLVMValueRef[] getMember(string var, LLVMBuilderRef builder){
        	if(parent !is null){
                if(parent.hasVar(var)){
                    return parent.getMember(var, builder);
                }
            }
        	auto typ = builder.LLVMBuildStructGEP( vars[var], 0, ("typeof_"~var~"_ptr").toStringz());
        	auto act = builder.LLVMBuildStructGEP( vars[var], 1, ("valueof_"~var~"_ptr").toStringz());
        	return [builder.LLVMBuildLoad( typ, ("typeof_"~var).toStringz()), builder.LLVMBuildLoad( act, ("valueof_"~var).toStringz())];
        }
        
        
    }

	LLVMValueRef[] wrapArgs(LLVMValueRef[][] val){
        for(auto i = args.length; i<val.length;i++){
            args ~= allocB.LLVMBuildAlloca(struct_t(), "wrapPtr".toStringz());
        }
		
        LLVMValueRef[] retval = [];
        for(auto i = 0; i<val.length;i++){
            auto typ = builder.LLVMBuildStructGEP( args[i], 0, ("wrap_typeof_tmpVar_ptr").toStringz());

            auto act = builder.LLVMBuildStructGEP( args[i], 1, ("wrap_valueof_tmpVar_ptr").toStringz());
            builder.LLVMBuildStore(val[i][0], typ);

            builder.LLVMBuildStore(val[i][1], act);
            retval ~=  builder.LLVMBuildLoad(args[i], "wrap_load".toStringz());
        }
		

        
        //builder.LLVMBuildFree(allocVar);
        return retval;
	}
    LLVMValueRef[] genExpression(ParseTree p,BScope b ){

            switch(p.name["BASIC.".length..$] ){
                case "Variable":
                    return b.getMember(p.matches[0], builder);
                case "Number":
                    auto tempDbl = builder.LLVMBuildBitCast(LLVMConstRealOfString(LLVMDoubleType(), p.matches[0].toStringz()),LLVMInt64Type(), "origVarFloat".toStringz() );
                    return [LLVMConstInt(LLVMInt8Type(), varType.Float, cast(LLVMBool) false), tempDbl];
                case "String":
	               /* auto constStr = LLVMConstString(p.matches[0].toStringz(), cast(uint)p.matches[0].length, cast(LLVMBool) false);
                    auto ptr = builder.LLVMBuildMalloc(constStr.LLVMTypeOf(),"str_ptr".toStringz());
                    builder.LLVMBuildStore(constStr, ptr);*/
		            auto ptr = builder.LLVMBuildGlobalStringPtr( p.matches[0].toStringz(), "strTemp".toStringz());
                    auto tempCast = builder.LLVMBuildBitCast(ptr,LLVMInt64Type(), "origVarStr".toStringz() );
                    return [LLVMConstInt(LLVMInt8Type(), varType.String, cast(LLVMBool) false), tempCast];
	                
                default:
                break;
            }
            auto res = genExpression(p.children[0],b);

            for(int i = 1; i < p.children.length;i+=2){
            	res=Variable!().opDispatch(p.children[i].matches[0],res,genExpression(p.children[i+1], b), builder);
            }
            return res;
    }
    void genStatement(ParseTree p,BScope b){
    	auto ch= p.children[0].children[0];
    	switch(ch.name["BASIC.".length..$] ){
    		case "Let":

	    		b.setMember(ch.matches[1], genExpression(ch.children[1], b), builder);
	    		break;
	    	case "Print":
                foreach(exp;ch.children){
                    builder.LLVMBuildCall(println, [wrapArgs([genExpression(exp, b)])[0]].ptr, 1, "");
                }
                break;
            case "Input":
                auto sb = ch.children[0];
                if(ch.children.length==2){
                    sb= ch.children[1];
                    builder.LLVMBuildCall(println, [wrapArgs([genExpression(ch.children[0], b)])[0]].ptr, 1, "");
                }
                auto exp = builder.LLVMBuildCall(inputFn, [LLVMConstReal(LLVMDoubleType(), 1.0)].ptr,0, "");
                break;
            case "If":
	            genIf(ch,b);
	            break;
	        case "While":
	        genWhile(ch, b);
	            break;
	        case "For":
	            break;        
    		default:
	    		break; 
    	}
    }
    void genScopeBody(ParseTree p,BScope b){
    	foreach (child; p.children) {
    		
    		genStatement(child, b);
    	}
    }
    void genRoot(ParseTree p){
    	genScopeBody(p.children[0], new BScope(null)); 
    	builder.LLVMBuildRetVoid();
	    LLVMRunPassManager(pass, module_);
    	LLVMDumpModule(module_);
    }
}
