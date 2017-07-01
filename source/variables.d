import llvm;
import std.string;
import std.algorithm;
import std.array;
import std.uni;
import std.stdio;
struct varMD{
    varType type;
    union{
    double fp;
    char* ptr;
    }
}
enum varType {
    Float,
    String
} 
class Variable(){
	alias dg =  LLVMValueRef[] delegate(varType);
	private static LLVMValueRef[] genCases(LLVMValueRef[] val1, LLVMValueRef[] val2, LLVMBuilderRef builder,dg runCode){
		LLVMValueRef[][] valsMat;
		LLVMBasicBlockRef[] blocks;
		auto currBlk = builder.LLVMGetInsertBlock();
		auto fn = currBlk.LLVMGetBasicBlockParent();
		
		auto elseBlk = LLVMAppendBasicBlock(fn, "elseSecond".toStringz());
		auto endBlk = LLVMAppendBasicBlock(fn, "endSecond".toStringz());
		builder.LLVMPositionBuilderAtEnd( elseBlk);
		builder.LLVMBuildBr(endBlk);
		builder.LLVMPositionBuilderAtEnd( currBlk);
		auto switchStmt = builder.LLVMBuildSwitch( val2[0], elseBlk, __traits(allMembers, varType).length);
		
		blocks=blocks~[elseBlk];
		valsMat=valsMat~[val1];
		foreach(type_;__traits(allMembers, varType)){
			enum varT = mixin("varType." ~ type_);
			auto newBlk = LLVMAppendBasicBlock(fn, ("typeBlkSecond"~varT).toStringz());
			
			switchStmt.LLVMAddCase( LLVMConstInt(LLVMInt8Type(), varT, cast(LLVMBool) false), newBlk);
			
			builder.LLVMPositionBuilderAtEnd( newBlk);
			LLVMValueRef[] vals=val1;
			vals = runCode(varT);
			
			valsMat~=vals;
			builder.LLVMBuildBr(endBlk);
			blocks = blocks~[builder.LLVMGetInsertBlock()];
			
			
		}
		builder.LLVMPositionBuilderAtEnd( endBlk);
		auto resType = builder.LLVMBuildPhi( LLVMInt8Type(), "typeres".toStringz());
		auto resVals = builder.LLVMBuildPhi( LLVMInt64Type(), "valsres".toStringz());
		auto tys = array(valsMat.map!(a=>a[0]));
		auto vals = array(valsMat.map!(a=>a[1]));
		resType.LLVMAddIncoming(tys.ptr, blocks.ptr, cast(uint)blocks.length);
		resVals.LLVMAddIncoming(vals.ptr, blocks.ptr, cast(uint)blocks.length);
		return [resType, resVals];
	}

	private static string genMethod(string name){

		string res = "static LLVMValueRef[] "~name~`(LLVMValueRef[] val1, LLVMValueRef[] val2, LLVMBuilderRef builder){
			return val1;
		
		}
		`;
		return res;
	}
	static LLVMValueRef[] opDispatch(string op, LLVMValueRef[] val1, LLVMValueRef[] val2, LLVMBuilderRef builder){
		LLVMValueRef[][] valsMat;
		LLVMBasicBlockRef[] blocks;
		auto currBlk = builder.LLVMGetInsertBlock();
		auto fn = currBlk.LLVMGetBasicBlockParent();
		
		auto elseBlk = LLVMAppendBasicBlock(fn, "else".toStringz());
		auto endBlk = LLVMAppendBasicBlock(fn, "end".toStringz());
		builder.LLVMPositionBuilderAtEnd( elseBlk);
		builder.LLVMBuildBr(endBlk);
		builder.LLVMPositionBuilderAtEnd( currBlk);
		auto switchStmt = builder.LLVMBuildSwitch( val1[0], elseBlk, __traits(allMembers, varType).length);
		
		blocks=blocks~[elseBlk];
		valsMat=valsMat~[[LLVMConstInt(LLVMInt8Type(), varType.Float, cast(LLVMBool) false), LLVMConstInt(LLVMInt64Type(), 0, cast(LLVMBool) false)]];
		foreach(type_;__traits(allMembers, varType)){
			 enum varT = mixin("varType." ~ type_);
			 alias varCl = Variable!varT ;
			 LLVMValueRef[] vals;
			 auto newBlk = LLVMAppendBasicBlock(fn, ("typeBlk"~varT).toStringz());
			 switchStmt.LLVMAddCase( LLVMConstInt(LLVMInt8Type(), varT, cast(LLVMBool) false), newBlk);
			 builder.LLVMPositionBuilderAtEnd( newBlk);
			 switch(op){
			 	case "+":
				 	vals = varCl.opAdd( val1,  val2,  builder);
				 	break;
			 	case "-":
				 	vals = varCl.opSub( val1,  val2,  builder);
				 	break;
			 	case "*":
				 	vals = varCl.opMul( val1,  val2,  builder);
				 	break;
			 	case "/":
				 	vals = varCl.opDiv( val1,  val2,  builder);
				 	break;
			 	case "^":
				 	vals = varCl.opPow( val1,  val2,  builder);
				 	break;
			 	case "==":
				 	vals = varCl.opEq( val1,  val2,  builder);
				 	break;
			 	case "!=":
				 	vals = varCl.opNe( val1,  val2,  builder);
				 	break;
			 	case ">=":
				 	vals = varCl.opGe( val1,  val2,  builder);
				 	break;
			 	case "<=":
				 	vals = varCl.opLe( val1,  val2,  builder);
				 	break;
			 	case "<":
				 	vals = varCl.opLt( val1,  val2,  builder);
				 	break;
			 	case ">":
				 	vals = varCl.opGt( val1,  val2,  builder);
				 	break;
			 	default:
				 	break;
			 }
			 builder.LLVMBuildBr(endBlk);
			 blocks = blocks~[builder.LLVMGetInsertBlock()];
			 valsMat = 	valsMat~[vals];
		}
		
		
		builder.LLVMPositionBuilderAtEnd( endBlk);
		auto resType = builder.LLVMBuildPhi( LLVMInt8Type(), "typeres".toStringz());
		auto resVals = builder.LLVMBuildPhi( LLVMInt64Type(), "valsres".toStringz());
		auto tys = array(valsMat.map!(a=>a[0]));
		auto vals = array(valsMat.map!(a=>a[1]));
		resType.LLVMAddIncoming(tys.ptr, blocks.ptr, cast(uint)blocks.length);
		resVals.LLVMAddIncoming(vals.ptr, blocks.ptr, cast(uint)blocks.length);
		return [resType, resVals];
	}
	mixin(genMethod("opAdd"));
	mixin(genMethod("opSub"));
	mixin(genMethod("opDiv"));
	mixin(genMethod("opMul"));
	mixin(genMethod("opPow"));
	mixin(genMethod("opEq"));
	mixin(genMethod("opNe"));
	mixin(genMethod("opGe"));
	mixin(genMethod("opLe"));
	mixin(genMethod("opGt"));
	mixin(genMethod("opLt"));
	
	
	
}
class Variable(varType type):Variable!() if(type==varType.String){
	
	
}
class Variable(varType type):Variable!() if(type==varType.Float){
	static string arithMixin(string op){
		return `static LLVMValueRef[] op`~op~`(LLVMValueRef[] val1, LLVMValueRef[] val2, LLVMBuilderRef builder){
		dg del = delegate( varT){
		switch(varT){
			case varType.Float:
				return [LLVMConstInt(LLVMInt8Type(), varType.Float, cast(LLVMBool) false), builder.LLVMBuildBitCast(builder.LLVMBuildF`~op~`(builder.LLVMBuildBitCast(val1[1], LLVMDoubleType(), "val1".toStringz()), builder.LLVMBuildBitCast(val2[1], LLVMDoubleType(), "val2".toStringz()), "`~op~`Stuff".toStringz()), LLVMInt64Type(), "`~op~`StuffCast".toStringz())];
			default:
				break;
			
		}
		return val1;
		
		};
		return genCases(val1, val2, builder, del );

				

	}`;
	}
	mixin(arithMixin("Add"));
	mixin(arithMixin("Sub"));
	mixin(arithMixin("Mul"));
	mixin(arithMixin("Div"));

	static LLVMValueRef[] opPow(LLVMValueRef[] val1, LLVMValueRef[] val2, LLVMBuilderRef builder){
		dg del = delegate( varT){
		switch(varT){
			case varType.Float:
				return [LLVMConstInt(LLVMInt8Type(), varType.Float, cast(LLVMBool) false), builder.LLVMBuildBitCast(builder.LLVMBuildXor(val1[1], val2[1], "xorStuff".toStringz()), LLVMInt64Type(), "xorStuffCast".toStringz())];
			default:
				break;
			
		}
		return val1;
		
		};
		return genCases(val1, val2, builder, del );

				

	}
	static string cmpMixin(string op){
		return `static LLVMValueRef[] op`~op~`(LLVMValueRef[] val1, LLVMValueRef[] val2, LLVMBuilderRef builder){
		dg del = delegate( varT){
		switch(varT){
			case varType.Float:
				auto cast1 = builder.LLVMBuildBitCast(val1[1], LLVMDoubleType(), "Flt`~op~`1".toStringz());
				auto cast2 = builder.LLVMBuildBitCast(val2[1], LLVMDoubleType(), "Flt`~op~`2".toStringz());
				auto intres = builder.LLVMBuildFCmp( LLVMRealO`~op.toUpper()~`, cast1, cast2,"`~op~`Test".toStringz());
				auto fltRes = builder.LLVMBuildUIToFP(intres,LLVMDoubleType(),"`~op~`fltRes".toStringz());
				return [LLVMConstInt(LLVMInt8Type(), varType.Float, cast(LLVMBool) false), builder.LLVMBuildBitCast(fltRes, LLVMInt64Type(), "`~op~`StuffCast".toStringz())];
			default:
				break;
			
		}
		return [LLVMConstInt(LLVMInt8Type(), varType.Float, cast(LLVMBool) false), LLVMConstInt(LLVMInt64Type(), 0, cast(LLVMBool) false)];
		
		};
		return genCases(val1, val2, builder, del );

				

	}`;
	}
	mixin(cmpMixin("Eq"));
	mixin(cmpMixin("Ne"));
	mixin(cmpMixin("Gt"));
	mixin(cmpMixin("Lt"));
	mixin(cmpMixin("Ge"));
	mixin(cmpMixin("Le"));
	

}