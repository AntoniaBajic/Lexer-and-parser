/*
* The scanner definition for COOL.
*/

/*
* Stuff enclosed in %{ %} in the first section is copied verbatim to the
* output, so headers and global definitions are placed here to be visible
* to the code in the file. Don't remove anything that was here initially
*/
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;
int counterComment = 0;
extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

%}

/*
 * Define names for regular expressions here.
 */

SLOVO			[A-Za-z]
UPPER_LETTER	[A-Z]
LOWER_LETTER	[a-z]
SPACE	    [ \f\r\t\v]
BROJ		[0-9]+
TYPE		[A-Z][a-zA-Z0-9_]*
OBJEKT		[a-z][a-zA-Z0-9_]*
ZNAKOVI_ERROR		"`"|"!"|"#"|"$"|"%"|"^"|"&"|"_"|"["|"]"|"|"|[\\]|">"|"?"
DARROW          =>


%x KOMENTAR
%x STRING 
%x ERROR_WITH_STRING

%%


 /*
  *  Nested comments
  */


 /*
  *  The multiple-character operators.
  */

{DARROW}		return DARROW;
"<-"			return ASSIGN;
"<="			return LE;

(?i:class)		return CLASS;
(?i:inherits)	return INHERITS;
(?i:else)		return ELSE;
(?i:fi)			return FI;
(?i:if)			return IF;
(?i:not)		return NOT;
(?i:in)			return IN;
(?i:let)		return LET;
(?i:case)		return CASE;
(?i:esac)		return ESAC;
(?i:of)			return OF;
(?i:new)		return NEW;
(?i:isvoid)		return ISVOID;
(?i:loop)		return LOOP;
(?i:pool)		return POOL;
(?i:then)		return THEN;
(?i:while)		return WHILE;


t(?i:rue)		{ cool_yylval.boolean = true;
			  return BOOL_CONST;
			  }
			  
(f)(?i:alse) {
			    cool_yylval.boolean = false;
			    return BOOL_CONST;
}


"("			return int('('); 
")"			return int(')'); 
"{"			return int('{');
"}"			return int('}');
"+"			return int('+');
"-"			return int('-');
"*"			return int('*');
"/"			return int('/');
"="			return int('=');
"."			return int('.');
","			return int(',');
";"			return int(';');
":"			return int(':');
"@"			return int('@');
"<"			return int('<');
"~"			return int('~');

{ZNAKOVI_ERROR} {
				cool_yylval.error_msg = yytext;
				return ERROR;
}

{BROJ} {
		    cool_yylval.symbol = inttable.add_string(yytext);
			return INT_CONST;
}

{TYPE}	{
			cool_yylval.symbol = idtable.add_string(yytext);
			return TYPEID;
}

{OBJEKT} {
				    cool_yylval.symbol = idtable.add_string(yytext);
				    return OBJECTID;
}


{SPACE}+ {

}

\n {
        curr_lineno++;
}


"--"(.)* {

}

"(*" {
		++counterComment;
		BEGIN(KOMENTAR);				
}

"*)" {
		cool_yylval.error_msg = "Zatvara se zagrada a nema otvaranja zagrade";
		return ERROR;
}


<KOMENTAR>"(*" {
                    ++counterComment;
}

<KOMENTAR>\n {
                ++curr_lineno;
}

<KOMENTAR>({SPACE}+)|(.) {

}


<KOMENTAR>"*)" {
				    --counterComment;
				    if (counterComment == 0) {
					    BEGIN(INITIAL);
                    }
}

<KOMENTAR><<EOF>> {
				        BEGIN(INITIAL);
				        if (counterComment > 0) {
					        cool_yylval.error_msg = "End of file u komentaru";
					        counterComment = 0;
					        return ERROR;
				        }
}

"\"" {
		BEGIN(STRING);
		string_buf_ptr = string_buf;
}

<STRING>\"  {
				if (string_buf_ptr - string_buf > MAX_STR_CONST-1) {
					*string_buf = '\0';
					cool_yylval.error_msg = "String je duzi od dozvoljenoga";
					BEGIN(ERROR_WITH_STRING);
					return ERROR;
				}

				*string_buf_ptr = '\0';
				cool_yylval.symbol = stringtable.add_string(string_buf);
				BEGIN(INITIAL);
				return STR_CONST;
}


<STRING>\0 {
				*string_buf = '\0';
				cool_yylval.error_msg = "String sadrzi null";
				BEGIN(ERROR_WITH_STRING);
				return ERROR;
}

<STRING><<EOF>>	{
				cool_yylval.error_msg = "End of file in string";
				BEGIN(INITIAL);
				return ERROR;
}
<STRING>\n {
				*string_buf = '\0';
				BEGIN(INITIAL);
				cool_yylval.error_msg = "String unfinished";
				return ERROR;
}

<STRING>"\\n"	*string_buf_ptr++ = '\n';
<STRING>"\\t"	*string_buf_ptr++ = '\t';


<STRING>"\\b"	*string_buf_ptr++ = '\b';
<STRING>"\\f"	*string_buf_ptr++ = '\f';
<STRING>"\\"[^\0]	*string_buf_ptr++ = yytext[1];
<STRING>.	*string_buf_ptr++ = *yytext;

<ERROR_WITH_STRING>\n	{ curr_lineno++;
						BEGIN(INITIAL);
			}
			
<ERROR_WITH_STRING>\"	{	BEGIN(INITIAL);}


<ERROR_WITH_STRING>[^\n|"] {

}
<ERROR_WITH_STRING>\\\n		{ curr_lineno++;
			  BEGIN(INITIAL);
			}

<ERROR_WITH_STRING>.		;


.		{
			cool_yylval.error_msg = yytext;
			return ERROR;
		}
 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */


%%