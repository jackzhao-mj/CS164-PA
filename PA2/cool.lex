/*
 * CS164: Spring 2004
 * Programming Assignment 2
 *
 * The scanner definition for Cool.
 *
 */

import java_cup.runtime.Symbol;

%%

/* Code enclosed in %{ %} is copied verbatim to the lexer class definition.
 * All extra variables/methods you want to use in the lexer actions go
 * here.  Don't remove anything that was here initially.  */
%{
    // Max size of string constants
    static int MAX_STR_CONST = 1024;

    // For assembling string constants
    StringBuffer string_buf = new StringBuffer();
    boolean has_null = false;
    boolean has_EOF = true;

    // For line numbers
    private int curr_lineno = 1;
    int get_curr_lineno() {
	return curr_lineno;
    }

    //for nested comments
    private int comment_nest_depth = 0;

    private AbstractSymbol filename;

    void set_filename(String fname) {
	filename = AbstractTable.stringtable.addString(fname);
    }

    AbstractSymbol curr_filename() {
	return filename;
    }

    /*
     * Add extra field and methods here.
     */
%}


/*  Code enclosed in %init{ %init} is copied verbatim to the lexer
 *  class constructor, all the extra initialization you want to do should
 *  go here. */
%init{
    // empty for now
%init}

/*  Code enclosed in %eofval{ %eofval} specifies java code that is
 *  executed when end-of-file is reached.  If you use multiple lexical
 *  states and want to do something special if an EOF is encountered in
 *  one of those states, place your code in the switch statement.
 *  Ultimately, you should return the EOF symbol, or your lexer won't
 *  work. */
%eofval{
    switch(yystate()) {
    case YYINITIAL:
	/* nothing special to do in the initial state */
	break;

/* If necessary, add code for other states here, e.g:
    case LINE_COMMENT:
	   ...
	   break;
 */
    }
    return new Symbol(TokenConstants.EOF);
%eofval}

/* Do not modify the following two jlex directives */
%class CoolLexer
%cup


/* This defines a new start condition for line comments.
 * .
 * Hint: You might need additional start conditions. */
%state LINE_COMMENT
%state BLOCK_COMMENT
%state STRING
%state BACKSLASH_ESCAPE


/* Define lexical rules after the %% separator.  There is some code
 * provided for you that you may wish to use, but you may change it
 * if you like.
 * .
 * Some things you must fill-in (not necessarily a complete list):
 *   + Handle (* *) comments.  These comments should be properly nested.
 *   + Some additional multiple-character operators may be needed.  One
 *     (DARROW) is provided for you.
 *   + Handle strings.  String constants adhere to C syntax and may
 *     contain escape sequences: \c is accepted for all characters c
 *     (except for \n \t \b \f) in which case the result is c.
 * .
 * The complete Cool lexical specification is given in the Cool
 * Reference Manual (CoolAid).  Please be sure to look there. */
%%

<YYINITIAL>\n	 { curr_lineno++; }


<YYINITIAL>\s { /* Fill-in here. */ }


<YYINITIAL>"--"         { yybegin(LINE_COMMENT); }
<LINE_COMMENT>.        { /* Fill-in here. */ }
<LINE_COMMENT>\n        { curr_lineno++; yybegin(YYINITIAL); }


<YYINITIAL>"*)"     {return new Symbol(TokenConstants.ERROR, "Unmatched *)"); }
<YYINITIAL>"(*"     { comment_nest_depth = 1; yybegin(BLOCK_COMMENT); }
<BLOCK_COMMENT>\n   { curr_lineno++; }
<BLOCK_COMMENT>"(*" { comment_nest_depth++; }
<BLOCK_COMMENT>"*)" { if (--comment_nest_depth == 0) yybegin(YYINITIAL); }
<BLOCK_COMMENT><<EOF>> { yybegin(YYINITIAL);
                         return new Symbol(TokenConstants.ERROR,
                    "EOF in comment"); }
<BLOCK_COMMENT>.    {  /* ignore */ }



<YYINITIAL> \"            { has_EOF = false; has_null = false;
                            string_buf.setLength(0); yybegin(STRING); }
<STRING>    \\b           { string_buf.append('\b'); }
<STRING>    \\t           { string_buf.append('\t'); }
<STRING>    \\n           { string_buf.append('\n'); }
<STRING>    \\f           { string_buf.append('\f'); }
<STRING>    \n            { return new Symbol(TokenConstants.ERROR,
                    "Unterminated string constant"); }
<STRING>    \0           { has_null = true; }
<STRING>    <<EOF>>      { has_EOF = true; }
<STRING>    \\                { yybegin(BACKSLASH_ESCAPE); }
<BACKSLASH_ESCAPE>\n          { curr_lineno++;
                                string_buf.append('\n'); yybegin(STRING); }
<BACKSLASH_ESCAPE>\0          { has_null = true; yybegin(STRING); }
<BACKSLASH_ESCAPE><<EOF>>     { has_EOF = true; yybegin(STRING); }
<BACKSLASH_ESCAPE>[^\n\0]  { string_buf.append(yytext()); yybegin(STRING); }
<STRING>    [^\n\0\\\"]  { string_buf.append(yytext()); }
<STRING>    \"           { /* String Constant */
                         yybegin(YYINITIAL);
                         if (has_EOF){
                           return new Symbol(TokenConstants.ERROR,
                                   "EOF in string constant");
                         }else if(has_null){
                           return new Symbol(TokenConstants.ERROR,
                                   "String contains null character");
                         }else if (string_buf.length()-1 > MAX_STR_CONST){
                           return new Symbol(TokenConstants.ERROR,
                                   "String constant too long");
                         }else{
                           return new Symbol(TokenConstants.STR_CONST,
                                AbstractTable.stringtable.addString(string_buf.toString()));
                         }
                         }


<YYINITIAL>"=>"		{ return new Symbol(TokenConstants.DARROW); }
<YYINITIAL>"<="		{ return new Symbol(TokenConstants.LE); }
<YYINITIAL>"<-"		{ return new Symbol(TokenConstants.ASSIGN); }





<YYINITIAL>[0-9][0-9]*  { /* Integers */
                          return new Symbol(TokenConstants.INT_CONST,
					    AbstractTable.inttable.addString(yytext())); }





<YYINITIAL>[Cc][Aa][Ss][Ee]	{ return new Symbol(TokenConstants.CASE); }
<YYINITIAL>[Cc][Ll][Aa][Ss][Ss] { return new Symbol(TokenConstants.CLASS); }
<YYINITIAL>[Ee][Ll][Ss][Ee]  	{ return new Symbol(TokenConstants.ELSE); }
<YYINITIAL>[Ee][Ss][Aa][Cc]	{ return new Symbol(TokenConstants.ESAC); }
<YYINITIAL>f[Aa][Ll][Ss][Ee]	{ return new Symbol(TokenConstants.BOOL_CONST, Boolean.FALSE); }
<YYINITIAL>[Ff][Ii]             { return new Symbol(TokenConstants.FI); }
<YYINITIAL>[Ii][Ff]  		{ return new Symbol(TokenConstants.IF); }
<YYINITIAL>[Ii][Nn]             { return new Symbol(TokenConstants.IN); }
<YYINITIAL>[Ii][Nn][Hh][Ee][Rr][Ii][Tt][Ss] { return new Symbol(TokenConstants.INHERITS); }
<YYINITIAL>[Ii][Ss][Vv][Oo][Ii][Dd] { return new Symbol(TokenConstants.ISVOID); }
<YYINITIAL>[Ll][Ee][Tt]         { return new Symbol(TokenConstants.LET); }
<YYINITIAL>[Ll][Oo][Oo][Pp]  	{ return new Symbol(TokenConstants.LOOP); }
<YYINITIAL>[Nn][Ee][Ww]		{ return new Symbol(TokenConstants.NEW); }
<YYINITIAL>[Nn][Oo][Tt] 	{ return new Symbol(TokenConstants.NOT); }
<YYINITIAL>[Oo][Ff]		{ return new Symbol(TokenConstants.OF); }
<YYINITIAL>[Pp][Oo][Oo][Ll]  	{ return new Symbol(TokenConstants.POOL); }
<YYINITIAL>[Tt][Hh][Ee][Nn]   	{ return new Symbol(TokenConstants.THEN); }
<YYINITIAL>t[Rr][Uu][Ee]	{ return new Symbol(TokenConstants.BOOL_CONST, Boolean.TRUE); }
<YYINITIAL>[Ww][Hh][Ii][Ll][Ee] { return new Symbol(TokenConstants.WHILE); }



<YYINITIAL>[A-Z][a-zA-Z0-9_]*  { /* Type Identier */
                          return new Symbol(TokenConstants.TYPEID,
					    AbstractTable.idtable.addString(yytext())); }


<YYINITIAL>[a-z][a-zA-Z0-9_]*  { /* Object Identier */
                          return new Symbol(TokenConstants.OBJECTID,
					    AbstractTable.idtable.addString(yytext())); }



<YYINITIAL>"+"			{ return new Symbol(TokenConstants.PLUS); }
<YYINITIAL>"-"			{ return new Symbol(TokenConstants.MINUS); }
<YYINITIAL>"/"			{ return new Symbol(TokenConstants.DIV); }
<YYINITIAL>"*"			{ return new Symbol(TokenConstants.MULT); }
<YYINITIAL>"="			{ return new Symbol(TokenConstants.EQ); }
<YYINITIAL>"<"			{ return new Symbol(TokenConstants.LT); }
<YYINITIAL>"."			{ return new Symbol(TokenConstants.DOT); }
<YYINITIAL>"~"			{ return new Symbol(TokenConstants.NEG); }
<YYINITIAL>","			{ return new Symbol(TokenConstants.COMMA); }
<YYINITIAL>";"			{ return new Symbol(TokenConstants.SEMI); }
<YYINITIAL>":"			{ return new Symbol(TokenConstants.COLON); }
<YYINITIAL>"("			{ return new Symbol(TokenConstants.LPAREN); }
<YYINITIAL>")"			{ return new Symbol(TokenConstants.RPAREN); }
<YYINITIAL>"@"			{ return new Symbol(TokenConstants.AT); }
<YYINITIAL>"}"			{ return new Symbol(TokenConstants.RBRACE); }
<YYINITIAL>"{"			{ return new Symbol(TokenConstants.LBRACE); }




.                { /*
                    *  This should be the very last rule and will match
                    *  everything not matched by other lexical rules.
                    */
                    return new Symbol(TokenConstants.ERROR, yytext()); }
