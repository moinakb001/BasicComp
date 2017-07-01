import pegged.grammar;


import std.string;
import std.stdio;
mixin(grammar(`
BASIC:
    ScopeBody     < (Statement)*
    Statement   < ControlFlow / IO

    Let         < "LET " Variable "=" Expression
    For         < "FOR " Expression "=" Expression "TO " Expression ("STEP " Expression)? ScopeBody "NEXT"
    If          < "IF " Expression (("THEN" ScopeBody (ElseIf)* (Else)? "END") / Statement)
    ElseIf      < "ELSEIF " Expression ScopeBody
    Else        < "ELSE" ScopeBody
    Ret         < "RET" Expression
    Function    < identifier "(" Expression ("," Expression)* ")"
    While       < "WHILE " Expression ScopeBody "END"
    ControlFlow < While / Let / If  / For / Ret
    
     
    Print       < "PRINT " Expression ( "," Expression)*
    Input       < "INPUT " (Expression ";")? Variable
    IO          < Print / Input
    
    MaybeBinOp(Exp, Op) < Exp (^Op Exp)*
    Expression       < MaybeBinOp(OpPM, ">=" / "<=" / "==" / "!=" / "<" / ">")
    OpPM        < MaybeBinOp(OpDivMul,"+" / "-")
    OpDivMul    < MaybeBinOp(OpPow,"*" / "/")
    OpPow       < MaybeBinOp( Base , "^" )
    Base  <  "("Expression")" / Number/ String / Variable

    Variable    < identifier
    Number      < ~([0-9]+  ("." [0-9]*)?)
    String      < :doublequote ~((!doublequote Char)*) :doublequote
    Char        <~ (backslash ( doublequote  # '\' Escapes
                        / quote
                        / backslash
                        / [bfnrt]
                        / [0-2][0-7][0-7]
                        / [0-7][0-7]?
                        / 'x' Hex Hex
                        / 'u' Hex Hex Hex Hex
                        / 'U' Hex Hex Hex Hex Hex Hex Hex Hex
                        ))
                    / . # Or any char, really
    Hex         <- [0-9a-fA-F]

`));