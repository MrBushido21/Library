
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <assert.h>
#include <tcl.h>
  
#ifdef DEBUG_TIME
#include "Clock.h"
#define Clock_report(A) Clock report(A);
#else
#define Clock_report(A) ((void)0)
#endif
#define Clock_report_OFF(A) ((void)0)
  
const char open_brace_CS='{';
const char close_brace_CS='}';
#define open_brace_CSS "{"
#define close_brace_CSS "}"
const char open_braquet_CS='[';
const char close_braquet_CS=']';
#define open_braquet_CSS "["
#define close_braquet_CSS "]"
  
#if(defined(_MSC_VER) && _MSC_VER >= 1400)
//1400==VS 2005, this secure functions are not defined in VS 2003
//this print functions accept a format with argument order,
//like "%2$d" instead "%d" to use the second integer argument
//Visual C standar fprintf and snprintf functions doesn't support this 2$ index
#define FPRINTF _fprintf_p
#define SNPRINTF _sprintf_p
#else
// WARNING: check equivalents in linux and other Visual Studio old versions
#define FPRINTF fprintf
#define SNPRINTF snprintf
#endif

enum P_or_R {P=0,R=1,PP=2};
enum Word_types { NONE_WT,W_WT,BRACE_WT,DQUOTE_WT,BRACKET_WT};
enum braces_history_types { open_BHT,close_BHT };

//################################################################################
//    regexp_string
//################################################################################

// length=-1 means to the end of the string
inline int string_regexp(char* buf,int pos,int length,const char* regexp)
{
  int result,has_saved_char=0;
  char save_char;
  
  if(length==-1) length=(int)strlen(buf);
  
  if(pos==length){
    return 0;
  } else if(buf[length]!='\0'){
    save_char=buf[length];
    buf[length]='\0';
    has_saved_char=1;
  }
  Tcl_RegExp rex=Tcl_RegExpCompile(NULL,regexp);
  if(!rex){
    if(has_saved_char) buf[length]=save_char;
    return -1;
  }
  result=Tcl_RegExpExec(NULL,rex,&buf[pos],&buf[pos]);
  if(has_saved_char) buf[length]=save_char;
  return result;
}

// length=-1 means to the end of the string
inline int string_regexp(char* buf,int pos,int length,
  const char* regexp,const char** match_start,int* match_length,int max_matches)
{
  int i,result,has_saved_char=0;
  char save_char;
  const char* endPtr;
  
  if(length==-1) length=(int)strlen(buf);
  
  if(pos==length){
    return 0;
  } else if(buf[length]!='\0'){
    save_char=buf[length];
    buf[length]='\0';
    has_saved_char=1;
  }
  Tcl_RegExp rex=Tcl_RegExpCompile(NULL,regexp);
  if(!rex){
    if(has_saved_char) buf[length]=save_char;
    return -1;
  }
  result=Tcl_RegExpExec(NULL,rex,&buf[pos],&buf[pos]);
  if(result!=1){
    if(has_saved_char) buf[length]=save_char;
    return result;
  }
  for(i=0;i<max_matches;i++){
    Tcl_RegExpRange(rex,i,&match_start[i],&endPtr);
    if(match_start[i]){
      match_length[i]=(int)(endPtr-match_start[i]);
    } else {
      match_length[i]=0;
    }
  }
  if(has_saved_char) buf[length]=save_char;
  return result;
}

//################################################################################
//    string_match_brace
//################################################################################

// return position of closing brace ({} or [] or "") or -1
inline int string_match_brace(const char* str,int length)
{
  int i=0;
  char open_c,close_c;
  
  if(str[i]=='{') { open_c='{'; close_c='}'; }
  else if(str[i]=='[') { open_c='['; close_c=']'; }
  else if(str[i]=='"') { open_c='\0'; close_c='"'; }
  else assert(0);

  int level=1,backslash=0;
  for(i++;str[i] && (length<0 || i<length);i++){
    if(!backslash){
      if(str[i]=='\\'){
        backslash=1;
      } else if(str[i]==open_c){
        level++;
      } else if(str[i]==close_c){
        level--;
        if(level==0) return i;
      }
    } else {
      backslash=0;
    }
  }
  return -1;
}

struct Braces_history
{
  braces_history_types type;
  int level;
  int line;
  int icharline;
  Braces_history* next;

  Braces_history(braces_history_types _type,int _level,int _line,int _icharline):type(_type),
        level(_level),line(_line),icharline(_icharline),next(NULL){}
  ~Braces_history();
};

Braces_history::~Braces_history()
{
  // changing from recursive to loop as recursive core dumped in debug version
  Braces_history* curr=next;
  while(curr){
    Braces_history* curr_next=curr->next;
    curr->next=NULL;
    delete curr;
    curr=curr_next;
  }
  curr=NULL;
}

struct InstrumenterState
{
  Tcl_Interp *ip;
  InstrumenterState* stack;
  Tcl_Obj *words;
  Tcl_Obj *currentword;
  Word_types wordtype;
  int wordtypeline;
  int wordtypepos;
  int DoInstrument;
  P_or_R OutputType;
  int NeedsNamespaceClose;
  int braceslevel;
  int snitpackageinserted;
  int level;
  Tcl_Obj *newblock[3];
  char **nonInstrumentingProcs;

  int line;
  Word_types type;

  int nextiscyan;
  Braces_history* braces_hist_1,* braces_hist_end;

  InstrumenterState() : braces_hist_1(NULL),braces_hist_end(NULL) {}
  ~InstrumenterState() {
    if(braces_hist_1) delete braces_hist_1;
  }
  int braces_history_error(int line);
};


int InstrumenterState::braces_history_error(int line)
{
  char buf[1024];
  const char* currentfile=Tcl_GetVar(ip,"RamDebugger::currentfile",TCL_GLOBAL_ONLY);
  if(!currentfile){
    Tcl_SetObjResult(ip,Tcl_NewStringObj("error in InstrumenterState::braces_history_error",-1));
    return TCL_ERROR;
  }
  Tcl_Obj *objPtr=Tcl_NewStringObj("BRACES POSITIONS\n",-1);
  Braces_history* bh=braces_hist_1;
  while(bh){
    if(bh->type==open_BHT)
      SNPRINTF(buf,1024,"%s:%d open brace pos=%d Level after=%d\n",
              currentfile,bh->line,bh->icharline,bh->level);
    else
      SNPRINTF(buf,1024,"%s:%d close brace pos=%d Level after=%d\n",
              currentfile,bh->line,bh->icharline,bh->level);
    Tcl_AppendToObj(objPtr,buf,-1);
    bh=bh->next;
  }
  //Tcl_EvalEx(ip,"RamDebugger::TextOutClear; RamDebugger::TextOutRaise",-1,TCL_EVAL_GLOBAL);
  Tcl_Obj *listPtr=Tcl_NewListObj(0,NULL);
  Tcl_ListObjAppendElement(ip,listPtr,Tcl_NewStringObj("RamDebugger::TextOutInsert",-1));
  Tcl_ListObjAppendElement(ip,listPtr,objPtr);
  Tcl_IncrRefCount(listPtr);
  Tcl_EvalObjEx(ip,listPtr,TCL_EVAL_GLOBAL);
  Tcl_DecrRefCount(listPtr);
  SNPRINTF(buf,1024,"error in line %d. There is one unmatched closing brace (})",line);
  Tcl_SetObjResult(ip,Tcl_NewStringObj(buf,-1));
  return TCL_ERROR;
}

inline Tcl_Obj *Tcl_CopyIfShared(Tcl_Obj *obj)
{
  Tcl_Obj *objnew=obj;
  if(Tcl_IsShared(obj)){
    objnew=Tcl_DuplicateObj(obj);
    Tcl_DecrRefCount(obj);
    Tcl_IncrRefCount(objnew);
  }
  return objnew;
}

inline Tcl_Obj *Tcl_ResetString(Tcl_Obj *obj)
{
  Tcl_Obj *objnew=obj;
  if(Tcl_IsShared(obj)){
    objnew=Tcl_NewStringObj("",-1);
    Tcl_DecrRefCount(obj);
    Tcl_IncrRefCount(objnew);
  } else {
    Tcl_SetStringObj(objnew,"",-1);
  }
  return objnew;
}

inline Tcl_Obj *Tcl_ResetList(Tcl_Obj *obj)
{
  Tcl_Obj *objnew=obj;
  if(Tcl_IsShared(obj)){
    objnew=Tcl_NewListObj(0,NULL);
    Tcl_DecrRefCount(obj);
    Tcl_IncrRefCount(objnew);
  } else {
    Tcl_SetListObj(objnew,0,NULL);
  }
  return objnew;
}


void RamDebuggerInstrumenterInitState(InstrumenterState* is)
{
  int i,result,len;
  is->stack=(InstrumenterState*) malloc(1000*sizeof(InstrumenterState));
  is->words=Tcl_NewListObj(0,NULL);
  Tcl_IncrRefCount(is->words);
  is->currentword=Tcl_NewStringObj("",-1);
  Tcl_IncrRefCount(is->currentword);
  is->wordtype=NONE_WT;
  is->wordtypeline=-1;
  is->wordtypepos=-1;
  /*   = 0 no instrument, consider data; =1 instrument; =2 special case: switch; */
  /*   = 3 do not instrument but go inside */
  is->DoInstrument=0;
  is->NeedsNamespaceClose=0;
  is->braceslevel=0;
  is->level=0;
  is->snitpackageinserted=0;

  Tcl_EvalEx(is->ip,""
    "foreach i [list return break while eval foreach for if else elseif error switch default continue] {\n"
             "set ::RamDebugger::Instrumenter::colors($i) magenta\n"
             "}\n"
             "foreach i [list variable set global incr lassign] {\n"
             "set ::RamDebugger::Instrumenter::colors($i) green\n"
             "}\n"
             "foreach i [list #include static const if else new delete for return sizeof while continue \
                 break class typedef struct #else #endif #if] {\n"
             "set ::RamDebugger::Instrumenter::colors_cpp($i) magenta\n"
             "}\n"
             "foreach i [list #ifdef #ifndef #define #undef] {\n"
             "set ::RamDebugger::Instrumenter::colors_cpp($i) magenta2\n"
             "}\n"
             "foreach i [list char int long double void] {\n"
             "set ::RamDebugger::Instrumenter::colors_cpp($i) green\n"
             "}",-1,0);

  result=Tcl_EvalEx(is->ip,"set RamDebugger::options(nonInstrumentingProcs)",-1,TCL_EVAL_GLOBAL);
  if(result==TCL_OK){
    int objc;
    Tcl_Obj** objv;
    result=Tcl_ListObjGetElements(is->ip,Tcl_GetObjResult(is->ip),&objc,&objv);
    if(result==TCL_OK){
      is->nonInstrumentingProcs=new char*[objc+1];
      for(i=0;i<objc;i++){
        char* str=Tcl_GetStringFromObj(objv[i],&len);
        is->nonInstrumentingProcs[i]=new char[len+1];
        strcpy(is->nonInstrumentingProcs[i],str);
      }
      is->nonInstrumentingProcs[i]=NULL;
    }
  }
  if(result!=TCL_OK){
    is->nonInstrumentingProcs=new char*[1];
    is->nonInstrumentingProcs[0]=NULL;
  }
}

int RamDebuggerInstrumenterEndState(InstrumenterState* is)
{
  int i;
  Tcl_Obj* result=NULL;
  char type,buf[1024];

  if(is->wordtype!=NONE_WT && is->wordtype!=W_WT){
    SNPRINTF(buf,1024,"There is a block of type (%c) beginning at line %d "
            "that is not closed at the end of the file\n",is->wordtype,is->wordtypeline);
    Tcl_SetObjResult(is->ip,Tcl_NewStringObj(buf,-1));
    return TCL_ERROR;
  }
  for(i=0;i<is->level;i++){
    switch(is->stack[i].type){
    case NONE_WT: assert(0); break;
    case W_WT: type='w'; break;
    case BRACE_WT: type='{'; break;
    case DQUOTE_WT: type='"'; break;
    case BRACKET_WT: type='['; break;
    }
    SNPRINTF(buf,1024,"There is a block of type (%c) beginning at line %d "
            "that is not closed at the end of the file\n",type,is->stack[i].wordtypeline);
    if(result==NULL) result=Tcl_NewStringObj("",-1);
    Tcl_AppendToObj(result,buf,-1);
  }

  Tcl_DecrRefCount(is->words);
  Tcl_DecrRefCount(is->currentword);

  if(result!=NULL){
    Tcl_SetObjResult(is->ip,result);
    return TCL_ERROR;
  }
  i=0;
  while(is->nonInstrumentingProcs[i]){
    delete [] is->nonInstrumentingProcs[i++];
  }
  delete [] is->nonInstrumentingProcs;
  return TCL_OK;
}

int RamDebuggerInstrumenterPushState(InstrumenterState* is,Word_types type,int line)
{
  int i,NewDoInstrument=0,PushState=0,wordslen,intbuf,index;
  P_or_R NewOutputType;
  Tcl_Obj *word0,*word1,*wordi,*tmpObj;
  char* pword0,*pword1,*pchar,buf[1024];

  if(is->OutputType==P){
    NewOutputType=PP;
  } else {
    NewOutputType=is->OutputType;
  }

  if(type==BRACKET_WT){
    PushState=1;
    if(is->DoInstrument == 1) NewDoInstrument=1;
    else NewDoInstrument=0;
  }
  else {
    Tcl_ListObjLength(is->ip,is->words,&wordslen);
    if(wordslen){
      Tcl_ListObjIndex(is->ip,is->words,0,&word0);
      pword0=Tcl_GetStringFromObj(word0,NULL);
      if(*pword0==':' && *(pword0+1)==':') pword0+=2;
      if(wordslen>1){
        Tcl_ListObjIndex(is->ip,is->words,1,&word1);
        pword1=Tcl_GetStringFromObj(word1,NULL);
      }
    }

    if(wordslen==2 && strcmp(pword0,"constructor")==0)
      NewDoInstrument=1;
    else if(wordslen==1 && strcmp(pword0,"destructor")==0)
      NewDoInstrument=1;
    else if(wordslen==2 && strcmp(pword0,"oncget")==0) {
      int result=Tcl_GetIndexFromObj(NULL,word1,(const char**) is->nonInstrumentingProcs,"",TCL_EXACT,&index);
      if(result!=TCL_OK){
        NewDoInstrument=1;
      }
    }
    else if(wordslen==3 && (strcmp(pword0,"proc")==0 || strcmp(pword0,"method")==0 || 
             strcmp(pword0,"typemethod")==0 || strcmp(pword0,"onconfigure")==0)){
      int result=Tcl_GetIndexFromObj(NULL,word1,(const char**) is->nonInstrumentingProcs,"",TCL_EXACT,&index);
      if(result!=TCL_OK){
        NewDoInstrument=1;
      }
    }
    else if(is->DoInstrument==0){
      if(wordslen==2 && (strcmp(pword0,"snit::type")==0 || strcmp(pword0,"snit::widget")==0 || 
                         strcmp(pword0,"snit::widgetadaptor")==0))
        PushState=1;
      else if(wordslen>=3 && strcmp(pword0,"namespace")==0 && strcmp(pword1,"eval")==0){
        PushState=1;
        /*                  if { $OutputType == "R" } { */
        /*                      upvar 2 $newblocknameP newblock */
        /*                  } else { upvar 2 $newblocknameR newblock } */
        /*                  append newblock "namespace eval [lindex $words 2] \{\n" */
        /*                  set NeedsNamespaceClose 1 */
      }
    }
    else if(is->DoInstrument==1){
      if(wordslen>0 && strcmp(pword0,"if")==0){
        if(wordslen==2) NewDoInstrument=1;
        else if(wordslen>2 && Tcl_ListObjIndex(is->ip,is->words,wordslen-1,&wordi)==TCL_OK &&
                (strcmp(Tcl_GetStringFromObj(wordi,NULL),"then")==0 ||
                 strcmp(Tcl_GetStringFromObj(wordi,NULL),"else")==0))
          NewDoInstrument=1;
        else if(wordslen>2 && Tcl_ListObjIndex(is->ip,is->words,wordslen-2,&wordi)==TCL_OK &&
                strcmp(Tcl_GetStringFromObj(wordi,NULL),"elseif")==0)
          NewDoInstrument=1;
      }
      else if(wordslen>0 && strcmp(pword0,"db")==0){
        if(wordslen>=3 && strcmp(pword1,"eval")==0){
          // this is not a very correct one. It assumes that db is a sqlite3 handle
          // can fail if db is an interp
          NewDoInstrument=1;
        }
      }
      else if(wordslen>0 && strcmp(pword0,"dict")==0){
        if(wordslen==4 && strcmp(pword1,"for")==0){
          NewDoInstrument=1;
        }
      }
      else if(wordslen>0 && strcmp(pword0,"namespace")==0){
        if(wordslen>=3 && strcmp(pword1,"eval")==0){
          NewDoInstrument=1;
          if(is->OutputType==R){
            Tcl_ListObjIndex(is->ip,is->words,2,&wordi);
            tmpObj=Tcl_NewListObj(1,&wordi);
            Tcl_IncrRefCount(tmpObj);
            SNPRINTF(buf,1024,"namespace eval %s {\n",Tcl_GetStringFromObj(tmpObj,NULL));
            Tcl_DecrRefCount(tmpObj);
            Tcl_AppendToObj(is->newblock[P],buf,-1);
            is->NeedsNamespaceClose=1;
          }
        }
      }
      else if(wordslen==2 && (strcmp(pword0,"snit::type")==0 || strcmp(pword0,"snit::widget")==0 || 
               strcmp(pword0,"snit::widgetadaptor")==0)){
        NewDoInstrument=3;
        if(is->OutputType==R){
          tmpObj=Tcl_NewListObj(0,NULL);
          Tcl_IncrRefCount(tmpObj);
          Tcl_ListObjAppendElement(is->ip,tmpObj,word0);
          Tcl_ListObjAppendElement(is->ip,tmpObj,word1);
          SNPRINTF(buf,1024,"%s {\n",Tcl_GetStringFromObj(tmpObj,NULL));
          Tcl_DecrRefCount(tmpObj);
          is->NeedsNamespaceClose=1;
        }
      }
      else if((wordslen==1 && strcmp(pword0,"catch")==0) ||
        (wordslen==2 && strcmp(pword0,"while")==0) ||
        (wordslen>=3 && strcmp(pword0,"foreach")==0) ||
        (wordslen>=3 && strcmp(pword0,"mk::loop")==0) ||
        (wordslen>=1 && wordslen<=4 && strcmp(pword0,"for")==0) ||
        (wordslen>1 && strcmp(pword0,"eval")==0) ||
        (wordslen>1 && strcmp(pword0,"html::eval")==0) ||
        (wordslen==3 && strcmp(pword0,"bind")==0) ||
        (wordslen==4 && strcmp(pword1,"sql")==0 &&
          Tcl_ListObjIndex(is->ip,is->words,2,&wordi)==TCL_OK &&
         strcmp(Tcl_GetStringFromObj(wordi,NULL),"maplist")==0)){
        NewDoInstrument=1;
      } else if(wordslen>1 && strcmp(pword0,"uplevel")==0){
        int len=wordslen;
        pchar=pword1;
        if(*pchar=='#') pchar++;
        if(Tcl_GetInt(is->ip,pchar,&intbuf)==TCL_OK) len--;
        if(len>0) NewDoInstrument=1;
      }
      else if(wordslen>0 && strcmp(pword0,"switch")==0){
        for(i=1;i<wordslen;i++){
          Tcl_ListObjIndex(is->ip,is->words,i,&wordi);
          if(strcmp(Tcl_GetStringFromObj(wordi,NULL),"--")==0){
            i++;
            break;
          } else if( *(Tcl_GetStringFromObj(wordi,NULL))!='-') break;
        }
        if(wordslen-i==1) NewDoInstrument=2;
      }
    } else if(is->DoInstrument == 2){
      if(wordslen%2) NewDoInstrument=1;
    }
  }
  if(!PushState && !NewDoInstrument) { return 1; }
  
  if(is->level>=0){
    is->stack[is->level].words=is->words;
    Tcl_IncrRefCount(is->stack[is->level].words);
    is->stack[is->level].currentword=is->currentword;
    Tcl_IncrRefCount(is->stack[is->level].currentword);
    is->stack[is->level].wordtype=is->wordtype;
    is->stack[is->level].wordtypeline=is->wordtypeline;
    is->stack[is->level].wordtypepos=is->wordtypepos;
    is->stack[is->level].DoInstrument=is->DoInstrument;
    is->stack[is->level].OutputType=is->OutputType;
    is->stack[is->level].NeedsNamespaceClose=is->NeedsNamespaceClose;
    is->stack[is->level].braceslevel=is->braceslevel;
    is->stack[is->level].line=line;
    is->stack[is->level].type=type;
  }
  is->level++;
    
  is->words=Tcl_ResetList(is->words);
  is->currentword=Tcl_ResetString(is->currentword);
  is->wordtype=NONE_WT;
  is->wordtypeline=-1;
  is->wordtypepos=-1;
  is->DoInstrument=NewDoInstrument;
  is->OutputType=NewOutputType;
  is->NeedsNamespaceClose=0;
  is->braceslevel=0;

  return 0;
}

int RamDebuggerInstrumenterPopState(InstrumenterState* is,Word_types type,int line) {
  
  char buf[1024];
  Word_types last_type;
  int i;

  if(is->level>0){
    last_type=is->stack[is->level-1].type;
    if(type==BRACKET_WT && last_type!=BRACKET_WT) return 1;
  } else {
    last_type=NONE_WT;
  }

  if(type==BRACE_WT){
    if(is->wordtype==W_WT){
      int numopen=0,len,i;
      len=Tcl_GetCharLength(is->currentword);
      for(i=0;i<len;i++){
        switch(Tcl_GetString(is->currentword)[i]){
        case '\\': i++; break;
        case '{': { numopen++; }
        case '}': { numopen--; }
        }
      }
      if(numopen) return 1;
    }
    if(last_type != BRACE_WT){
      for(i=0;i<is->level;i++){
        if(is->stack[i].type==BRACE_WT){
          SNPRINTF(buf,1024,"Using a close brace (}) in line %d when there is an open brace "
                  "in line %d and an open bracket ([) in line %d"
                  ,line,is->stack[i].line,is->stack[is->level-1].line);
          Tcl_SetObjResult(is->ip,Tcl_NewStringObj(buf,-1));
          return -1;
        }
        return 1;
      } 
    }
  }

  int wordslen,isexpand=0;
  Tcl_ListObjLength(is->ip,is->words,&wordslen);
  if(!wordslen && strcmp(Tcl_GetString(is->currentword),"*")==0) isexpand=1;

  is->level--;
  if(is->level<0) return 0;
  Tcl_DecrRefCount(is->words);
  is->words=is->stack[is->level].words;
  Tcl_DecrRefCount(is->currentword);
  is->currentword=is->stack[is->level].currentword;
  is->wordtype=is->stack[is->level].wordtype;
  is->wordtypeline=is->stack[is->level].wordtypeline;
  is->wordtypepos=is->stack[is->level].wordtypepos;
  is->DoInstrument=is->stack[is->level].DoInstrument;
  is->OutputType=is->stack[is->level].OutputType;
  is->NeedsNamespaceClose=is->stack[is->level].NeedsNamespaceClose;
  is->braceslevel=is->stack[is->level].braceslevel;

  is->words=Tcl_CopyIfShared(is->words);
  if(isexpand) Tcl_ListObjAppendElement(is->ip,is->words,Tcl_NewStringObj("*",-1));
//   else Tcl_ListObjAppendElement(is->ip,is->words,Tcl_NewStringObj("",-1));

  if(is->NeedsNamespaceClose){
    Tcl_AppendToObj(is->newblock[P],"}\n",-1);
    is->NeedsNamespaceClose=0;
  }
  return 0;
}

int RamDebuggerInstrumenterIsProc(InstrumenterState* is)
{
  int wordslen;
  Tcl_Obj *word0;
  char* pword0;
  Tcl_ListObjLength(is->ip,is->words,&wordslen);
  if(wordslen==0) return 0;
  Tcl_ListObjIndex(is->ip,is->words,0,&word0);
  pword0=Tcl_GetStringFromObj(word0,NULL);
  if(*pword0==':' && *(pword0+1)==':') pword0+=2;

  if(strcmp(pword0,"snit::type")==0 || strcmp(pword0,"snit::widget")==0 || 
     strcmp(pword0,"snit::widgetadaptor")==0 || strcmp(pword0,"proc")==0 || 
     strcmp(pword0,"method")==0 || strcmp(pword0,"typemethod")==0 || 
     strcmp(pword0,"constructor")==0 || strcmp(pword0,"destructor")==0)
    return 1;
  return 0;
}

int RamDebuggerInstrumenterIsProcUpLevel(InstrumenterState* is)
{
  int wordslen;
  Tcl_Obj *word0;
  char* pword0;
  if(is->level<=0)
    return 0;
  Tcl_ListObjLength(is->ip,is->stack[is->level-1].words,&wordslen);
  if(wordslen==0) return 0;
  Tcl_ListObjIndex(is->ip,is->stack[is->level-1].words,0,&word0);
  pword0=Tcl_GetStringFromObj(word0,NULL);
  if(*pword0==':' && *(pword0+1)==':') pword0+=2;

  if(strcmp(pword0,"snit::type")==0 || strcmp(pword0,"snit::widget")==0 || 
     strcmp(pword0,"snit::widgetadaptor")==0 || strcmp(pword0,"proc")==0 || 
     strcmp(pword0,"method")==0 || strcmp(pword0,"typemethod")==0 || 
     strcmp(pword0,"constructor")==0 || strcmp(pword0,"destructor")==0)
    return 1;
  return 0;
}

void RamDebuggerInstrumenterInsertSnitPackage_ifneeded(InstrumenterState* is)
{
  Tcl_Obj *word0;
  char* pword0;
  Tcl_ListObjIndex(is->ip,is->words,0,&word0);
  if(!word0) return;
  pword0=Tcl_GetStringFromObj(word0,NULL);
  if(*pword0==':' && *(pword0+1)==':') pword0+=2;

  if(!is->snitpackageinserted &&
     (strcmp(pword0,"snit::type")==0 || strcmp(pword0,"snit::widget")==0 || 
      strcmp(pword0,"snit::widgetadaptor")==0)){
    is->snitpackageinserted=1;
    Tcl_AppendToObj(is->newblock[P],"package require snit\n",-1);
  }
}


/*  newblocknameP is for procs */
/*  newblocknameR is for the rest */
int RamDebuggerInstrumenterDoWork_do(Tcl_Interp *ip,char* block,int filenum,char* newblocknameP,
                                   char* newblocknameR,char* blockinfoname,int progress) {

  int i,length,braceslevelNoEval,lastinstrumentedline,
    line,ichar,icharline,consumed,instrument_proc_last_line,wordslen=0,
    quoteintobraceline=-1,quoteintobracepos,fail,commentpos,result;
  Word_types checkExtraCharsAfterCQB;
  Tcl_Obj *blockinfo,*blockinfocurrent,*word0,*wordi,*tmpObj;
  char c,lastc,buf[1024],*pword0=NULL;

  length = ( int)strlen(block);
  if(length>1000 && progress){
/*     RamDebugger::ProgressVar 0 1 */
  }

  InstrumenterState instrumenterstate,*is;
  is=&instrumenterstate;
  is->ip=ip;

  is->newblock[P]=Tcl_NewStringObj("",-1);
  Tcl_IncrRefCount(is->newblock[P]);
  is->newblock[PP]=is->newblock[P];
  is->newblock[R]=Tcl_NewStringObj("",-1);
  Tcl_IncrRefCount(is->newblock[R]);
  blockinfo=Tcl_NewListObj(0,NULL);
  Tcl_IncrRefCount(blockinfo);
  blockinfocurrent=Tcl_NewListObj(0,NULL);
  Tcl_IncrRefCount(blockinfocurrent);
  Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(0));
  Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewStringObj("n",-1));
  RamDebuggerInstrumenterInitState(is);


  is->DoInstrument=1;
  is->OutputType=R;

  Tcl_AppendToObj(is->newblock[P],"# RamDebugger instrumented file. InstrumentProcs=1\n",-1);
  Tcl_AppendToObj(is->newblock[R],"# RamDebugger instrumented file. InstrumentProcs=0\n",-1);

  if(Tcl_ExprBoolean(is->ip,"$::RamDebugger::options(instrument_proc_last_line)",
                     &instrument_proc_last_line)!=TCL_OK) instrument_proc_last_line=0;

  braceslevelNoEval=0;
  checkExtraCharsAfterCQB=NONE_WT;
  lastc=0;
  lastinstrumentedline=-1;
  line=1;
  ichar=0;
  icharline=0;

  for(i=0;i<length;i++){
    c=block[i];

    if(ichar%1000 == 0 && progress){
/*       RamDebugger::ProgressVar [expr {$ichar*100/$length}] */
    }
    if(checkExtraCharsAfterCQB!=NONE_WT){
      if(!strchr(" \t\n}]\\;",c)){
        if(c=='"' && checkExtraCharsAfterCQB==BRACE_WT){
          /* # nothing */
        } else {
          char cblocktype;
          switch(checkExtraCharsAfterCQB){
          case BRACE_WT: cblocktype='}'; break;
          case DQUOTE_WT: cblocktype='"'; break;
          case NONE_WT: case W_WT: case BRACKET_WT: assert(0); break;
          }
          SNPRINTF(buf,1024,"There is a non valid character (%c) in line %d "
                  "after a closing block with (%c)",c,line,cblocktype);
          Tcl_SetObjResult(ip,Tcl_NewStringObj(buf,-1));
          Tcl_DecrRefCount(is->newblock[P]);
          Tcl_DecrRefCount(is->newblock[R]);
          Tcl_DecrRefCount(blockinfo);
          Tcl_DecrRefCount(blockinfocurrent);
          return TCL_ERROR;
        }
      }
      checkExtraCharsAfterCQB=NONE_WT;
    }
    if(is->DoInstrument==1 && lastinstrumentedline!=line && !strchr(" \t\n#",c) &&
       wordslen==0){
      if(c!='}' || !RamDebuggerInstrumenterIsProcUpLevel(is) || instrument_proc_last_line){
        SNPRINTF(buf,1024,"RDC::F %d %d ; ",filenum,line);
        Tcl_AppendToObj(is->newblock[is->OutputType],buf,-1);
        lastinstrumentedline=line;
      }
    }
    consumed=0;
    switch(c){
    case '"':
      if(lastc != '\\' && (wordslen==0 || *pword0!='#')) {
        switch(is->wordtype){
        case NONE_WT:
          is->wordtype=DQUOTE_WT;
          is->wordtypeline=line;
          is->wordtypepos=icharline;
          consumed=1;
          break;
        case DQUOTE_WT:
          is->wordtype=NONE_WT;
          is->words=Tcl_CopyIfShared(is->words);
          Tcl_ListObjAppendElement(is->ip,is->words,is->currentword);
          wordslen++;
          Tcl_ListObjIndex(is->ip,is->words,0,&word0);
          pword0=Tcl_GetStringFromObj(word0,NULL);
          if(*pword0==':' && *(pword0+1)==':') pword0+=2;
          is->currentword=Tcl_ResetString(is->currentword);
          consumed=1;
          checkExtraCharsAfterCQB=DQUOTE_WT;
          
          blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
          Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewStringObj("grey",-1));
          if(is->wordtypeline==line)
            Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewIntObj(is->wordtypepos));
          else Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewIntObj(0));
          Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewIntObj(icharline+1));
          is->wordtypeline=0;

          if(is->OutputType==R && RamDebuggerInstrumenterIsProc(is)){
            int len,newllen;
            Tcl_GetStringFromObj(is->newblock[R],&len);
            newllen=len;
            Tcl_GetStringFromObj(is->words,&len);
            newllen-=len;
            if(lastinstrumentedline==line){
              SNPRINTF(buf,1024,"RDC::F %d %d ; ",filenum,line);
              newllen -= ( int)strlen(buf);
            }
            Tcl_SetObjLength(is->newblock[R],newllen);
            RamDebuggerInstrumenterInsertSnitPackage_ifneeded(is);
            Tcl_AppendObjToObj(is->newblock[P],is->words);
            is->OutputType=P;
          }
          break;
        case BRACE_WT:
          if(quoteintobraceline==-1){
            quoteintobraceline=line;
            quoteintobracepos=icharline;
          } else {
            if(line==quoteintobraceline){
              blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
              Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewStringObj("grey",-1));
              Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewIntObj(quoteintobracepos));
              Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewIntObj(icharline+1));
            }
            quoteintobraceline=-1;
          }
          break;
        default:
          SNPRINTF(buf,1024,"Quoted text (\") in line %d contains and invalid brace text  icharline=%d",line, icharline);
            Tcl_SetObjResult(is->ip,Tcl_NewStringObj(buf,-1));
            Tcl_DecrRefCount(is->newblock[P]);
            Tcl_DecrRefCount(is->newblock[R]);
            Tcl_DecrRefCount(blockinfo);
            Tcl_DecrRefCount(blockinfocurrent);
            return TCL_ERROR;
        }
      }
      break;
      case '{':
        if(lastc != '\\'){
          switch(is->wordtype){
          case BRACE_WT:
            braceslevelNoEval++;
            break;
          case DQUOTE_WT: case W_WT:
            is->braceslevel++;
            break;
          default:
            consumed=1;
            fail=RamDebuggerInstrumenterPushState(is,BRACE_WT,line);
            if(fail){
              is->wordtype=BRACE_WT;
              is->wordtypeline=line;
              braceslevelNoEval=1;
            } else{
              lastinstrumentedline=line;
              Tcl_ListObjLength(is->ip,is->words,&wordslen);
              if(wordslen){
                Tcl_ListObjIndex(is->ip,is->words,0,&word0);
                pword0=Tcl_GetStringFromObj(word0,NULL);
                if(*pword0==':' && *(pword0+1)==':') pword0+=2;
              }
            }
            break;
          }
        }
        break;
      case '}':
        if(lastc != '\\'){
          if(is->wordtype==BRACE_WT){
            braceslevelNoEval--;
            if(braceslevelNoEval==0){
              is->wordtype=NONE_WT;
              is->words=Tcl_CopyIfShared(is->words);
              Tcl_ListObjAppendElement(is->ip,is->words,is->currentword);
              wordslen++;
              Tcl_ListObjIndex(is->ip,is->words,0,&word0);
              pword0=Tcl_GetStringFromObj(word0,NULL);
              if(*pword0==':' && *(pword0+1)==':') pword0+=2;
              if(*pword0!='#' && strcmp(Tcl_GetString(is->currentword),"*")!=0)
                checkExtraCharsAfterCQB=BRACE_WT;
              is->currentword=Tcl_ResetString(is->currentword);
              consumed=1;
              if(is->OutputType==R && RamDebuggerInstrumenterIsProc(is)){
                int len,newllen;
                Tcl_GetStringFromObj(is->newblock[R],&len);
                newllen=len;
                Tcl_GetStringFromObj(is->words,&len);
                newllen-=len;
                if(lastinstrumentedline==line){
                  SNPRINTF(buf,1024,"RDC::F %d %d ; ",filenum,line);
                  newllen -= ( int)strlen(buf);
                }
                Tcl_SetObjLength(is->newblock[R],newllen);
                RamDebuggerInstrumenterInsertSnitPackage_ifneeded(is);
                Tcl_AppendObjToObj(is->newblock[P],is->words);
                is->OutputType=P;
              }
            }
          } else if(is->braceslevel>0) is->braceslevel--;
          else {
            Word_types wordtype_before=is->wordtype;
            fail=RamDebuggerInstrumenterPopState(is,BRACE_WT,line);
            if(fail==-1){
              Tcl_DecrRefCount(is->newblock[P]);
              Tcl_DecrRefCount(is->newblock[R]);
              Tcl_DecrRefCount(blockinfo);
              Tcl_DecrRefCount(blockinfocurrent);
              return TCL_ERROR;
            }
            if(!fail){
              Tcl_ListObjLength(is->ip,is->words,&wordslen);
              if(wordslen){
                Tcl_ListObjIndex(is->ip,is->words,0,&word0);
                pword0=Tcl_GetStringFromObj(word0,NULL);
                if(*pword0==':' && *(pword0+1)==':') pword0+=2;
              }
              if(wordtype_before==DQUOTE_WT){
                SNPRINTF(buf,1024,"Quoted text (\") in line %d contains and invalid brace (})",line);
                Tcl_SetObjResult(is->ip,Tcl_NewStringObj(buf,-1));
                Tcl_DecrRefCount(is->newblock[P]);
                Tcl_DecrRefCount(is->newblock[R]);
                Tcl_DecrRefCount(blockinfo);
                Tcl_DecrRefCount(blockinfocurrent);
                return TCL_ERROR;
              }
              consumed=1;
              if(wordslen){
                Tcl_ListObjIndex(is->ip,is->words,wordslen-1,&wordi);
                if(*pword0!='#' && strcmp(Tcl_GetString(wordi),"*")!=0)
                  checkExtraCharsAfterCQB=BRACE_WT;
              }
            }
          }
        }
        break;
      case ' ': case '\t':
        if(lastc != '\\'){
          if(is->wordtype==W_WT){
            consumed=1;
            is->wordtype=NONE_WT;
            is->words=Tcl_CopyIfShared(is->words);
            Tcl_ListObjAppendElement(is->ip,is->words,is->currentword);
            wordslen++;
            Tcl_ListObjIndex(is->ip,is->words,0,&word0);
            pword0=Tcl_GetStringFromObj(word0,NULL);
            if(*pword0==':' && *(pword0+1)==':') pword0+=2;
            is->currentword=Tcl_ResetString(is->currentword);
            if(is->OutputType==R && RamDebuggerInstrumenterIsProc(is)){
              int len,newllen;
              Tcl_GetStringFromObj(is->newblock[R],&len);
              newllen=len;
              Tcl_GetStringFromObj(is->words,&len);
              newllen-=len;
              if(lastinstrumentedline==line){
                SNPRINTF(buf,1024,"RDC::F %d %d ; ",filenum,line);
                newllen -= ( int)strlen(buf);
              }
              Tcl_SetObjLength(is->newblock[R],newllen);
              RamDebuggerInstrumenterInsertSnitPackage_ifneeded(is);
              
              Tcl_AppendObjToObj(is->newblock[P],is->words);
              is->OutputType=P;
            }
            Tcl_ListObjIndex(is->ip,is->words,wordslen-1,&wordi);
            if(RamDebuggerInstrumenterIsProc(is)){
              int icharlineold=icharline-Tcl_GetCharLength(wordi);
              blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
              if(wordslen==1)
                Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewStringObj("magenta",-1));
              else
                Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewStringObj("blue",-1));
              Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewIntObj(icharlineold));
              Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewIntObj(icharline));
            } else{
              tmpObj=Tcl_GetVar2Ex(is->ip,"::RamDebugger::Instrumenter::colors",
                   Tcl_GetStringFromObj(wordi,NULL),TCL_GLOBAL_ONLY);
              if(tmpObj){
                int icharlineold=icharline-Tcl_GetCharLength(wordi);
                blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
                Tcl_ListObjAppendElement(is->ip,blockinfocurrent,tmpObj);
                Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewIntObj(icharlineold));
                Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewIntObj(icharline));
              }
            }
          } else if(is->wordtype==NONE_WT) consumed=1;
        }
        break;
      case '[':
        if(lastc != '\\' && is->wordtype!=BRACE_WT && (wordslen==0 || *pword0!='#')){
          if(is->wordtype==NONE_WT) is->wordtype=W_WT;
          consumed=1;
          RamDebuggerInstrumenterPushState(is,BRACKET_WT,line);
          Tcl_ListObjLength(is->ip,is->words,&wordslen);
          if(wordslen){
            Tcl_ListObjIndex(is->ip,is->words,0,&word0);
            pword0=Tcl_GetStringFromObj(word0,NULL);
            if(*pword0==':' && *(pword0+1)==':') pword0+=2;
          }
          lastinstrumentedline=line;
        }
        break;
      case ']':
        if(lastc != '\\' && is->wordtype!=BRACE_WT && is->wordtype!=DQUOTE_WT && 
           (wordslen==0 || *pword0!='#')){
          fail=RamDebuggerInstrumenterPopState(is,BRACKET_WT,line);
          if(fail==-1){
            Tcl_DecrRefCount(is->newblock[P]);
            Tcl_DecrRefCount(is->newblock[R]);
            Tcl_DecrRefCount(blockinfo);
            Tcl_DecrRefCount(blockinfocurrent);
            return TCL_ERROR;
          }
          if(!fail){
            consumed=1;
            Tcl_ListObjLength(is->ip,is->words,&wordslen);
            if(wordslen){
              Tcl_ListObjIndex(is->ip,is->words,0,&word0);
              pword0=Tcl_GetStringFromObj(word0,NULL);
              if(*pword0==':' && *(pword0+1)==':') pword0+=2;
            }
          }
          /*         note: the word inside words is not correct when using [] */
        }
        break;
      case '\n':
        if(wordslen> 0 && *pword0=='#'){
          blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
          Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewStringObj("red",-1));
          Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewIntObj(commentpos));
          Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewIntObj(icharline));
        } else if(is->wordtype==DQUOTE_WT){
          blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
          Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewStringObj("grey",-1));
          if(is->wordtypeline==line)
            Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewIntObj(is->wordtypepos));
          else
            Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewIntObj(0));
          Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewIntObj(icharline));
        } else if(is->wordtype==W_WT){
          tmpObj=Tcl_GetVar2Ex(is->ip,"::RamDebugger::Instrumenter::colors",
                               Tcl_GetStringFromObj(is->currentword,NULL),TCL_GLOBAL_ONLY);
          if(tmpObj){
            int icharlineold=icharline-Tcl_GetCharLength(is->currentword);
            blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
            Tcl_ListObjAppendElement(is->ip,blockinfocurrent,tmpObj);
            Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewIntObj(icharlineold));
            Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewIntObj(icharline));
          }
        }
        blockinfo=Tcl_CopyIfShared(blockinfo);
        Tcl_ListObjAppendElement(is->ip,blockinfo,blockinfocurrent);
        line++;
        tmpObj=Tcl_NewIntObj(is->level+braceslevelNoEval);
        Tcl_IncrRefCount(tmpObj);
        blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
        Tcl_SetListObj(blockinfocurrent,1,&tmpObj);
        Tcl_DecrRefCount(tmpObj);

        if((is->wordtype==W_WT || is->wordtype==DQUOTE_WT) && is->braceslevel>0){
          blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
          Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewStringObj("n",-1));
        }
        else if(is->wordtype!=BRACE_WT){
          consumed=1;
          if(lastc != '\\' && is->wordtype!=DQUOTE_WT){
            is->words=Tcl_ResetList(is->words);
            wordslen=0;
            is->currentword=Tcl_ResetString(is->currentword);
            is->wordtype=NONE_WT;

            if(is->OutputType==P){
              Tcl_AppendToObj(is->newblock[P],&c,1);
              is->OutputType=R;
            }
            blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
            Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewStringObj("n",-1));
          } else {
            if(is->wordtype==W_WT){
              is->currentword=Tcl_ResetString(is->currentword);
              is->wordtype=NONE_WT;
              if(strcmp(Tcl_GetStringFromObj(is->currentword,NULL),"\\")!=0) {
                is->words=Tcl_CopyIfShared(is->words);
                Tcl_ListObjAppendElement(is->ip,is->words,is->currentword);
                wordslen++;
                Tcl_ListObjIndex(is->ip,is->words,0,&word0);
                pword0=Tcl_GetStringFromObj(word0,NULL);
                if(*pword0==':' && *(pword0+1)==':') pword0+=2;
              }
            }
            blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
            Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewStringObj("c",-1));
          }
        } else{
          blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
          Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewStringObj("n",-1));
        }
        break;
      case '#':
        if(wordslen==0 && strcmp(Tcl_GetStringFromObj(is->currentword,NULL),"")==0 &&
           is->wordtype==NONE_WT){
          consumed=1;
          is->words=Tcl_CopyIfShared(is->words);
          Tcl_ListObjAppendElement(is->ip,is->words,Tcl_NewStringObj("#",-1));
          wordslen++;
          Tcl_ListObjIndex(is->ip,is->words,0,&word0);
          pword0=Tcl_GetStringFromObj(word0,NULL);
          if(*pword0==':' && *(pword0+1)==':') pword0+=2;
          commentpos=icharline;
        }
        break;
      case ';':
       if(lastc != '\\' && is->wordtype!=BRACE_WT && is->wordtype!=DQUOTE_WT &&
        wordslen> 0 && *pword0!='#'){
        consumed=1;
        is->words=Tcl_ResetList(is->words);
        wordslen=0;
        word0=NULL;
        //Tcl_ListObjIndex(is->ip,is->words,0,&word0);
        is->currentword=Tcl_ResetString(is->currentword);
        is->wordtype=NONE_WT;
        
        if(is->OutputType==P){
          Tcl_AppendToObj(is->newblock[P],&c,1);
          is->OutputType=R;
        }
      }
      break;
    }
    
    Tcl_AppendToObj(is->newblock[is->OutputType],&c,1);
    if(!consumed){
      if(is->wordtype==NONE_WT){
        is->wordtype=W_WT;
        is->wordtypeline=line;
      }
      is->currentword=Tcl_CopyIfShared(is->currentword);
      Tcl_AppendToObj(is->currentword,&c,1);
    }
    if(lastc == '\\' && c=='\\')
      lastc=0;
    else lastc=c;
    ichar++;

    if(c=='\t') icharline+=8;
    else if(c!='\n') icharline++;
    else icharline=0;
  }
  blockinfo=Tcl_CopyIfShared(blockinfo);
  Tcl_ListObjAppendElement(is->ip,blockinfo,blockinfocurrent);

  result=RamDebuggerInstrumenterEndState(is);

  Tcl_UpVar(ip,"1",newblocknameP,"newblockP",0);
  Tcl_SetVar2Ex(is->ip,"newblockP",NULL,is->newblock[P],0);
  Tcl_UpVar(ip,"1",newblocknameR,"newblockR",0);
  Tcl_SetVar2Ex(is->ip,"newblockR",NULL,is->newblock[R],0);
  Tcl_UpVar(ip,"1",blockinfoname,"blockinfo",0);
  Tcl_SetVar2Ex(is->ip,"blockinfo",NULL,blockinfo,0);

#ifdef _DEBUG
  char* tmpblockinfo=Tcl_GetString(blockinfo);
#endif
  if(length>1000 && progress){
    /*     RamDebugger::ProgressVar 100 */
  }
  Tcl_DecrRefCount(is->newblock[P]);
  Tcl_DecrRefCount(is->newblock[R]);
  Tcl_DecrRefCount(blockinfo);
  Tcl_DecrRefCount(blockinfocurrent);
  return result;
}


Tcl_Obj* append_block_info(InstrumenterState* is,Tcl_Obj *blockinfocurrent,Tcl_Obj* colorPtr,int p1,int p2)
{
  blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
  Tcl_ListObjAppendElement(is->ip,blockinfocurrent,colorPtr);
  Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewIntObj(p1));
  Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewIntObj(p2));
  
  return blockinfocurrent;
}

Tcl_Obj* append_block_infoS(InstrumenterState* is,Tcl_Obj *blockinfocurrent,const char* color,
                            int p1,int p2)
{
  return append_block_info(is,blockinfocurrent,Tcl_NewStringObj(color,-1),p1,p2);
}

Tcl_Obj* check_word_color_cpp(InstrumenterState* is,Tcl_Obj *blockinfocurrent,int icharline,
                              int also_magenta2)
{
  Tcl_Obj *tmpObj;
  if(is->wordtype==W_WT){
    tmpObj=Tcl_GetVar2Ex(is->ip,"::RamDebugger::Instrumenter::colors_cpp",
                         Tcl_GetStringFromObj(is->currentword,NULL),TCL_GLOBAL_ONLY);
    if(tmpObj){
      int icharlineold=icharline-Tcl_GetCharLength(is->currentword);
      blockinfocurrent=append_block_info(is,blockinfocurrent,tmpObj,icharlineold,icharline);
      if(strcmp(Tcl_GetStringFromObj(tmpObj,NULL),"green")==0){
        is->nextiscyan=1;
      } else if(also_magenta2 && strcmp(Tcl_GetStringFromObj(tmpObj,NULL),"also_magenta2")==0){
        is->nextiscyan=1;
      }
    } else if(is->nextiscyan){
      int icharlineold=icharline-Tcl_GetCharLength(is->currentword);
      blockinfocurrent=append_block_infoS(is,blockinfocurrent,"cyan",icharlineold,icharline);
      is->nextiscyan=0;
    }
    is->wordtype=NONE_WT;
  }
  return blockinfocurrent;
}

int RamDebuggerInstrumenterDoWorkForCpp_do(Tcl_Interp *ip,char* block,
  char* blockinfoname,int progress,int indentlevel_ini)
{

  int i,p1,length,
    line,ichar,icharline,simplechar_line,simplechar_pos,
    commentlevel,startofline,finishedline,result;
  Tcl_Obj *blockinfo,*blockinfocurrent,*tmpObj;
  char c,lastc,buf[1024];
  
  length = ( int)strlen(block);
  if(length>5000 && progress){
/*     RamDebugger::ProgressVar 0 1 */
  } else {
    progress=0;
  }

  InstrumenterState instrumenterstate,*is;
  is=&instrumenterstate;
  is->ip=ip;

  blockinfo=Tcl_NewListObj(0,NULL);
  Tcl_IncrRefCount(blockinfo);
  blockinfocurrent=Tcl_NewListObj(0,NULL);
  Tcl_IncrRefCount(blockinfocurrent);
  Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(indentlevel_ini));
  Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewStringObj("n",-1));
  RamDebuggerInstrumenterInitState(is);
  is->braceslevel=indentlevel_ini;

  commentlevel=0;
//   braceslevelNoEval=0;
//   checkExtraCharsAfterCQB=NONE_WT;
//   wordslen=0;
//   quoteintobraceline=-1;
//   pword0=NULL
  lastc=0;
//   lastinstrumentedline=-1;
  line=1;
  ichar=0;
  icharline=0;
  simplechar_line=0;
  simplechar_pos=0;
  finishedline=1;
  startofline=1;
  is->nextiscyan=0;

  for(i=0;i<length;i++){
    c=block[i];

    if(ichar%5000 == 0 && progress){
      /*       RamDebugger::ProgressVar [expr {$ichar*100/$length}] */
    }
    if(simplechar_line>0){
      if(line>simplechar_line){
        SNPRINTF(buf,1024,"error in line %d, position %d. There is no closing (')",simplechar_line,
                simplechar_pos);
        Tcl_SetObjResult(is->ip,Tcl_NewStringObj(buf,-1));
        Tcl_DecrRefCount(blockinfo);
        Tcl_DecrRefCount(blockinfocurrent);
        return TCL_ERROR;
      }
      if(c=='\'' && lastc != '\\'){
        simplechar_line=0;
      }
      if(lastc == '\\' && c=='\\')
        lastc=0;
      else lastc=c;
      ichar++;

      if(c=='\t') icharline+=8;
      else if(c!='\n'){
        Tcl_UniChar ccharU;
        int num=Tcl_UtfToUniChar(&block[i],&ccharU);
        icharline++;
        i+=num-1;
      } else {
        icharline=0;
      }
      continue;
    }
    switch(c){
    case '"':
      if(commentlevel){
        // nothing
      } else if(is->wordtype!=DQUOTE_WT){
        is->wordtype=DQUOTE_WT;
        is->wordtypeline=line;
        is->wordtypepos=icharline;
        finishedline=0;
        break;
      } else if(lastc != '\\'){
        is->wordtype=NONE_WT;
        if(is->wordtypeline==line) p1=is->wordtypepos;
        else p1=0;
        blockinfocurrent=append_block_infoS(is,blockinfocurrent,"grey",p1,icharline+1);
        is->wordtypeline=0;
      }
      startofline=0;
      break;
    case '\'':
      if(!commentlevel && is->wordtype!=DQUOTE_WT && lastc != '\\'){
        simplechar_line=line;
        simplechar_pos=icharline;
      }
      startofline=0;
      break;
    case '{':
      if(!commentlevel && is->wordtype!=DQUOTE_WT){
        blockinfocurrent=check_word_color_cpp(is,blockinfocurrent,icharline,0);
        is->braceslevel++;
        Braces_history* bh=new Braces_history(open_BHT,is->braceslevel,line,icharline);
        if(!is->braces_hist_1)  is->braces_hist_1=bh;
        else is->braces_hist_end->next=bh;
        is->braces_hist_end=bh;
        finishedline=1;
      }
      startofline=0;
      break;
    case '}':
      if(!commentlevel && is->wordtype!=DQUOTE_WT){
        blockinfocurrent=check_word_color_cpp(is,blockinfocurrent,icharline,1);
        is->braceslevel--;
        Braces_history* bh=new Braces_history(close_BHT,is->braceslevel,line,icharline);
        if(!is->braces_hist_1)  is->braces_hist_1=bh;
        else is->braces_hist_end->next=bh;
        is->braces_hist_end=bh;
        if(is->braceslevel<0){
          return is->braces_history_error(line);
        }
        finishedline=1;
      }
      startofline=0;
      break;
    case '*':
      if(commentlevel==-1 || is->wordtype==DQUOTE_WT){
        // nothing
      } else if(lastc=='/'){
        if(commentlevel==0){
          if(startofline){
            Tcl_Obj *objPtr;
            Tcl_ListObjIndex(is->ip,blockinfocurrent,0,&objPtr);
            Tcl_SetIntObj(objPtr,0);
          }
          is->wordtype=NONE_WT;
          is->wordtypepos=icharline-1;
        }
        commentlevel++;
      } else if(!commentlevel){
        blockinfocurrent=check_word_color_cpp(is,blockinfocurrent,icharline,1);
      }
      startofline=0;
      break;
    case '/':
      if(commentlevel==-1 || is->wordtype==DQUOTE_WT){
        // nothing
      } else if(!commentlevel && lastc=='/'){
        if(startofline){
          Tcl_Obj *objPtr;
          Tcl_ListObjIndex(is->ip,blockinfocurrent,0,&objPtr);
          Tcl_SetIntObj(objPtr,0);
        }
        is->wordtype=NONE_WT;
        is->wordtypepos=icharline-1;
        commentlevel=-1;
        startofline=0;
      } else if(lastc=='*'){
        is->wordtype=NONE_WT;
        if(commentlevel>=1){
          commentlevel--;
          if(commentlevel==0){
            blockinfocurrent=append_block_infoS(is,blockinfocurrent,"red",is->wordtypepos,icharline+1);
          }
        }
        startofline=0;
      } else if(!commentlevel){
        blockinfocurrent=check_word_color_cpp(is,blockinfocurrent,icharline,1);
      }
      break;
    case '(':
      if(!commentlevel && is->braceslevel==0 && is->wordtype!=DQUOTE_WT){
        char* cw=Tcl_GetString(is->currentword);
        char* cipos=strstr(cw,"::");
        if(!cipos){
          blockinfocurrent=append_block_infoS(is,blockinfocurrent,"blue",is->wordtypepos,icharline);
        } else {
          blockinfocurrent=append_block_infoS(is,blockinfocurrent,"green",is->wordtypepos,(int)(is->wordtypepos+cipos-cw+2));
          blockinfocurrent=append_block_infoS(is,blockinfocurrent,"blue",(int)(is->wordtypepos+cipos-cw+2),icharline);
        }
        is->nextiscyan=0;
      } else if(!commentlevel){
        blockinfocurrent=check_word_color_cpp(is,blockinfocurrent,icharline,1);
      }
      startofline=0;
      break;
      case ';':
      if(!commentlevel){
        blockinfocurrent=check_word_color_cpp(is,blockinfocurrent,icharline,1);
        if(is->wordtype!=DQUOTE_WT){
          finishedline=1;
        }
      }
      startofline=0;
      break;
    case '\n':
      if(commentlevel){
        blockinfocurrent=append_block_infoS(is,blockinfocurrent,"red",is->wordtypepos,icharline);
        is->wordtypepos=0;
        if(commentlevel==-1) commentlevel=0;
        finishedline=1;
      } else if(is->wordtype==DQUOTE_WT){
        blockinfocurrent=append_block_infoS(is,blockinfocurrent,"grey",is->wordtypepos,icharline);
        is->wordtypepos=0;
      } else {
        blockinfocurrent=check_word_color_cpp(is,blockinfocurrent,icharline,1);
      }
      blockinfo=Tcl_CopyIfShared(blockinfo);
      Tcl_ListObjAppendElement(is->ip,blockinfo,blockinfocurrent);
      line++;
      tmpObj=Tcl_NewIntObj(is->braceslevel);
      Tcl_IncrRefCount(tmpObj);
      blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
      Tcl_SetListObj(blockinfocurrent,1,&tmpObj);
      Tcl_DecrRefCount(tmpObj);
      
      blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
      if(finishedline){
        Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewStringObj("n",-1));
        startofline=1;
      } else {
        Tcl_ListObjAppendElement(is->ip,blockinfocurrent,Tcl_NewStringObj("c",-1));
        startofline=0;
      }
      break;
    default:
      if(commentlevel || is->wordtype==DQUOTE_WT){
        // nothing
      } else if(is->wordtype==NONE_WT){
        if(startofline && c=='#'){
          Tcl_Obj *objPtr;
          Tcl_ListObjIndex(is->ip,blockinfocurrent,0,&objPtr);
          Tcl_SetIntObj(objPtr,0);
        }
	if(isalnum(c) || c=='_' || c=='#' || c==':' || c==','){
          is->wordtype=W_WT;
          is->wordtypepos=icharline;
          is->currentword=Tcl_ResetString(is->currentword);
          is->currentword=Tcl_CopyIfShared(is->currentword);
          Tcl_AppendToObj(is->currentword,&c,1);
          //finishedline=0;
          startofline=0;
        }
      } else if(is->wordtype==W_WT){
	if(isalnum(c) || c=='_' || c=='#' || c==':' || c==','){
          is->currentword=Tcl_CopyIfShared(is->currentword);
          Tcl_AppendToObj(is->currentword,&c,1);
        } else {
          blockinfocurrent=check_word_color_cpp(is,blockinfocurrent,icharline,1);
          finishedline=0;
        }
      }
    }
    if(lastc == '\\' && c=='\\')
      lastc=0;
    else lastc=c;
    ichar++;

    if(c=='\t') icharline+=8;
    else if(c!='\n'){
      Tcl_UniChar ccharU;
      int num=Tcl_UtfToUniChar(&block[i],&ccharU);
      icharline++;
      i+=num-1;
    } else {
      icharline=0;
    }
  }
  blockinfo=Tcl_CopyIfShared(blockinfo);
  Tcl_ListObjAppendElement(is->ip,blockinfo,blockinfocurrent);

  if(commentlevel>0){
    SNPRINTF(buf,1024,"error: There is a non-closed comment beginning at line %d",is->wordtypeline);
    Tcl_SetObjResult(is->ip,Tcl_NewStringObj(buf,-1));
    Tcl_UpVar(ip,"1",blockinfoname,"blockinfo",0);
    Tcl_SetVar2Ex(is->ip,"blockinfo",NULL,blockinfo,0);
    Tcl_DecrRefCount(blockinfo);
    Tcl_DecrRefCount(blockinfocurrent);
    return TCL_ERROR;
  }
  if(is->braceslevel){
    Tcl_UpVar(ip,"1",blockinfoname,"blockinfo",0);
    Tcl_SetVar2Ex(is->ip,"blockinfo",NULL,blockinfo,0);
    return is->braces_history_error(line);
  }
  result=RamDebuggerInstrumenterEndState(is);

  Tcl_UpVar(ip,"1",blockinfoname,"blockinfo",0);
  Tcl_SetVar2Ex(is->ip,"blockinfo",NULL,blockinfo,0);

#ifdef _DEBUG
  char* tmpblockinfo=Tcl_GetString(blockinfo);
#endif
  if(progress){
    /*     RamDebugger::ProgressVar 100 */
  }
  Tcl_DecrRefCount(blockinfo);
  Tcl_DecrRefCount(blockinfocurrent);
  return result;
}

enum Xml_space_values {
  default_XSV,
  preserve_XSV
};

struct Xml_state_tag
{
  char* tag;
  int charlen;
  int line;
  Xml_space_values xml_space_value;
};

enum Xml_states_names {
  NONE_XS,
  doctype_XS,
  doctypeM_XS,
  pi_XS,
  comment_XS,
  cdata_XS,
  tag_XS,
  tag_end_XS,
  enter_tagtext_XS,
  entered_tagtext_XS,
  text_XS,
  att_text_XS,
  att_after_equal_XS,
  att_quote_XS,
  att_dquote_XS,
  att_after_name_XS,
  att_entername_XS
};

static const char* xml_states_namesC[]={
  "NONE",
  "doctype",
  "doctypeM",
  "pi",
  "comment",
  "cdata",
  "tag",
  "tag_end",
  "enter_tagtext",
  "entered_tagtext",
  "text",
  "att_text",
  "att_after_equal",
  "att_quote",
  "att_dquote",
  "att_after_name",
  "att_entername",
};

const int MaxStackLen=1000;

struct Xml_state
{
  Tcl_Interp *ip;
  int indentlevel;
  int xml_state_tag_listNum;
  Xml_state_tag xml_state_tag_list[MaxStackLen];
  int xml_states_names_listNum;
  Xml_states_names xml_states_names_list[MaxStackLen];
  int iline,icharline;

  Xml_state(Tcl_Interp *_ip,int _indentlevel): ip(_ip),indentlevel(_indentlevel),
    xml_state_tag_listNum(0),xml_states_names_listNum(0),
    iline(0),icharline(0) {}
  void enter_line_icharline(int _iline,int _icharline) { iline=_iline ; icharline=_icharline; }

  void push_state(Xml_states_names state);
  void pop_state();
  int state_is(Xml_states_names state,int idx=-1);
  const char* give_state_name() {
    return xml_states_namesC[xml_states_names_list[xml_states_names_listNum-1]]; }

  void push_tag(char* tag,int len);
  void pop_tag(char* tag,int raiseerror,int len);
  void add_xml_space_value(Xml_space_values xml_space_value);
  Xml_space_values give_xml_space_value();
  void raise_error_if_tag_stack();

  void raise_error(const char* txt,int raiseerror);
};

void Xml_state::push_state(Xml_states_names state)
{
  if(xml_states_names_listNum>=MaxStackLen){
    Tcl_SetObjResult(ip,Tcl_NewStringObj("error in push_state. Stack full",-1));
    throw 1;
  }
  xml_states_names_list[xml_states_names_listNum++]=state;
}

void Xml_state::pop_state()
{
  xml_states_names_listNum--;
  if(xml_states_names_listNum<0){
    Tcl_SetObjResult(ip,Tcl_NewStringObj("error in pop_state. Stack empty",-1));
    throw 1;
  }
}

int Xml_state::state_is(Xml_states_names state,int idx)
{
  if(idx<0) idx=xml_states_names_listNum+idx;
  if(idx<0 || idx>=xml_states_names_listNum){
    return state==NONE_XS;
  }
  return state==xml_states_names_list[idx];
}

void Xml_state::push_tag(char* tag,int charlen)
{
  if(xml_state_tag_listNum>=MaxStackLen){
    Tcl_SetObjResult(ip,Tcl_NewStringObj("error in push_tag. Stack full",-1));
    throw 1;
  }
  xml_state_tag_list[xml_state_tag_listNum].tag=tag;
  xml_state_tag_list[xml_state_tag_listNum].charlen=charlen;
  xml_state_tag_list[xml_state_tag_listNum].line=iline;

  if(xml_state_tag_listNum>0){
    xml_state_tag_list[xml_state_tag_listNum].xml_space_value=
      xml_state_tag_list[xml_state_tag_listNum-1].xml_space_value;
  } else {
    xml_state_tag_list[xml_state_tag_listNum].xml_space_value=default_XSV;
  }
  xml_state_tag_listNum++;
  indentlevel++;
}

void Xml_state::pop_tag(char* tag,int raiseerror,int charlen)
{
  int idx=xml_state_tag_listNum-1;
  if(tag && (charlen!=xml_state_tag_list[idx].charlen ||
    strncmp(tag,xml_state_tag_list[idx].tag,charlen)!=0)){
    if(!raiseerror) return;
    char buf[1024];
    if(charlen>800) charlen=800;
    SNPRINTF(buf,1024,"closing tag '%.*s' is not correct. line=%d position=%d. tags stack=\n",charlen,tag,
            iline,icharline+1);
    Tcl_Obj *resPtr=Tcl_NewStringObj(buf,-1);
    for(int i=0;i<xml_state_tag_listNum;i++){
      SNPRINTF(buf,1024,"\t%.*s\tLine: %d\n",xml_state_tag_list[i].charlen,
              xml_state_tag_list[i].tag,xml_state_tag_list[i].line);
      Tcl_AppendToObj(resPtr,buf,-1);
    }
    Tcl_SetObjResult(ip,resPtr);
    throw 1;
  }
  xml_state_tag_listNum--;
  indentlevel--;
  if(xml_state_tag_listNum<0){
    char buf[1024];
    SNPRINTF(buf,1024,"error in pop_tag. Stack empty. line=%d position=%d",iline,icharline+1);
    Tcl_SetObjResult(ip,Tcl_NewStringObj(buf,-1));
    printf("pop_tag error\n"); // without it, program crashes on MacOS
    throw 1;
  }
}

void Xml_state::add_xml_space_value(Xml_space_values xml_space_value)
{
  assert(xml_state_tag_listNum>0);
  xml_state_tag_list[xml_state_tag_listNum-1].xml_space_value=xml_space_value;
}

Xml_space_values Xml_state::give_xml_space_value()
{
  if(xml_state_tag_listNum==0) return default_XSV;
  return xml_state_tag_list[xml_state_tag_listNum-1].xml_space_value;
}

void Xml_state::raise_error_if_tag_stack()
{
  if(xml_state_tag_listNum){
    char buf[1024];
    Tcl_Obj *resPtr=Tcl_NewStringObj("There are non-closed tags. tags stack=\n",-1);
    for(int i=0;i<xml_state_tag_listNum;i++){
      SNPRINTF(buf,1024,"\t%.*s\tLine: %d\n",xml_state_tag_list[i].charlen,
        xml_state_tag_list[i].tag,xml_state_tag_list[i].line);
      Tcl_AppendToObj(resPtr,buf,-1);
    }
    Tcl_SetObjResult(ip,resPtr);
    printf("raise_error_if_tag_stack error\n"); // without it, program crashes on MacOS
    throw 1;
  }
}

void Xml_state::raise_error(const char* txt,int raiseerror)
{
  if(!raiseerror) return;
  char buf[1024];
  int charlen=(int)strlen(txt);
  if(charlen>800) charlen=800;
  SNPRINTF(buf,1024,"error in line=%d position=%d. %.*s",iline,icharline+1,charlen,txt);
  Tcl_SetObjResult(ip,Tcl_NewStringObj(buf,-1));
  throw 1;
}

static char* insert_new_line(Tcl_Obj* blockPtr,int ipos,int* length)
{
  char *block;
  
  Tcl_SetObjLength(blockPtr,*length+1);
  block=Tcl_GetString(blockPtr);
  memmove(&block[ipos+1],&block[ipos],(*length-ipos)*sizeof(char));
  block[ipos]='\n';
  *length+=1;
  return block;
}

static char* insert_new_line_if_blanks(Tcl_Obj* blockPtr,int ipos,int* length)
{
  int i;
  char *block;
  
  block=Tcl_GetString(blockPtr);

  for(i=ipos;i<*length;i++){
    if(block[i]==' ' || block[i]=='\t');
    else break;
  }
  if(i==*length || block[i]!='<') return block;
  return insert_new_line(blockPtr,ipos,length);
}

static char* insert_new_line_if_not_close_tag(Tcl_Obj* blockPtr,int ipos,int* length)
{
  int i;
  char *block;
  
  block=Tcl_GetString(blockPtr);

  for(i=ipos;i<*length;i++){
    if(block[i]==' ' || block[i]=='\t');
    else break;
  }
  if(i<*length && (block[i]=='>' || block[i]=='/' || block[i]=='\n')) return block;
  return insert_new_line(blockPtr,ipos,length);
}

static char* insert_remove_spaces(Tcl_Obj* blockPtr,int ipos,int num_spaces,int* length)
{
  int i,num_spacesL,delta;
  char *block;
  
  block=Tcl_GetString(blockPtr);

  num_spacesL=0;
  for(i=ipos;i<*length;i++){
    if(block[i]==' ') num_spacesL++;
    else if(block[i]=='\t') num_spacesL+=8;
    else break;
  }
  delta=num_spaces-num_spacesL;
  if(delta==0) return block;

  if(delta>0){
    Tcl_SetObjLength(blockPtr,*length+delta);
    block=Tcl_GetString(blockPtr);
    memmove(&block[ipos+delta],&block[ipos],(*length-ipos)*sizeof(char));
    memset(&block[ipos],' ',delta);
    *length+=delta;
  } else {
    delta*=-1;
    for(i=ipos;i<ipos+delta;i++){
      if(block[i]=='\t'){
        Tcl_SetObjLength(blockPtr,*length+7);
        block=Tcl_GetString(blockPtr);
        memmove(&block[i+8],&block[i+1],(*length-(i+1))*sizeof(char));
        memset(&block[i],' ',8);
        *length+=7;
      }
    }
    memmove(&block[ipos],&block[ipos+delta],(*length-(ipos+delta))*sizeof(char));
    *length-=delta;
    Tcl_SetObjLength(blockPtr,*length);
    block=Tcl_GetString(blockPtr);
  }
  return block;
}

int RamDebuggerInstrumenterDoWorkForXML_do(Tcl_Interp *ip,Tcl_Obj* blockPtr,char* blockinfoname,
  int progress,int indentlevel_ini,int indent_spaces,int raiseerror) {

  int i,length,state_start,state_start_global,i_start_line,last_att_is_xml_space;
  char c,buf[1024],*block;
  Tcl_Obj *blockinfo,*blockinfocurrent;
  
  block=Tcl_GetString(blockPtr);
  length = ( int)strlen(block);
  if(length>1000 && progress){
    /*     RamDebugger::ProgressVar 0 1 */
  }
  blockinfo=Tcl_NewListObj(0,NULL);
  Tcl_IncrRefCount(blockinfo);
  blockinfocurrent=Tcl_NewListObj(0,NULL);
  Tcl_IncrRefCount(blockinfocurrent);
  Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(indentlevel_ini));
  Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewStringObj("n",-1));
  int indentLevel0=indentlevel_ini;
  if(indent_spaces){
    block=insert_remove_spaces(blockPtr,0,indentlevel_ini*indent_spaces,&length);
  }

  // colors: magenta magenta2 green red
  
  Xml_state xml_state(ip,indentlevel_ini);
  int icharline=0;
  int iline=1;
  i_start_line=0;
  last_att_is_xml_space=0;
  xml_state.enter_line_icharline(iline,icharline);
  try {
    for(i=0;i<length;i++){
      c=block[i];

      if(i%5000 == 0 && progress){
        /* RamDebugger::ProgressVar [expr {$ichar*100/$length}] */
      }
      if(xml_state.state_is(cdata_XS)){
        if(strncmp(&block[i-2],close_braquet_CSS close_braquet_CSS ">",3)==0){
          xml_state.pop_state();
          blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
          Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewStringObj("green",-1));
          Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(icharline-2));
          Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(icharline+1));
        }
      } else if(xml_state.state_is(comment_XS)){
        if(strncmp(&block[i-2],"-->",3)==0){
          xml_state.pop_state();
          blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
          Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewStringObj("red",-1));
          Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(state_start));
          Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(icharline+1));
        } else if(c=='\n'){
          blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
          Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewStringObj("red",-1));
          Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(state_start));
          Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(icharline));
          state_start=0;
        }
      } else if(xml_state.state_is(doctype_XS)){
        if(c==open_braquet_CS){
          xml_state.pop_state();
          xml_state.push_state(doctypeM_XS);
        } else if(c=='>'){
          xml_state.pop_state();
        }
      } else if(xml_state.state_is(doctypeM_XS)){
        if(strncmp(&block[i-1],close_braquet_CSS ">",2)==0){
          xml_state.pop_state();
        }
      } else {
        switch(c){
        case '<':
          if(xml_state.state_is(att_dquote_XS) || xml_state.state_is(att_quote_XS)){
            //nothing
          } else if(!xml_state.state_is(NONE_XS) && !xml_state.state_is(text_XS)){
            Tcl_SetObjResult(ip,Tcl_NewStringObj("Not valid <",-1));
          } else if(strncmp(&block[i],"<?",2)==0){
            xml_state.push_state(pi_XS);
          } else if(strncmp(&block[i],"<!DOCTYPE",9)==0){
            xml_state.push_state(doctype_XS);
          } else if(strncmp(&block[i],"<!--",4)==0){
            xml_state.push_state(comment_XS);
            state_start=icharline;
            state_start_global=i;
          } else if(strncmp(&block[i],"<!" open_braquet_CSS "CDATA" open_braquet_CSS,9)==0){
            xml_state.push_state(cdata_XS);
            blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
            Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewStringObj("green",-1));
            Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(icharline));
            Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(icharline+9));
          } else {
            if(xml_state.state_is(text_XS)) { xml_state.pop_state(); }
            xml_state.push_state(tag_XS);
            blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
            Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewStringObj("magenta",-1));
            Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(icharline));
            Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(icharline));
          }
          break;
        case '>':
          if(xml_state.state_is(enter_tagtext_XS)){
            xml_state.pop_state();
            int isend;
            if(xml_state.state_is(tag_end_XS)){
              isend=1;
              xml_state.pop_state();
            } else {
              isend=0;
            }
            if(xml_state.state_is(tag_XS)){
              if(isend){
                xml_state.pop_tag(&block[state_start_global],raiseerror,i-state_start_global);
              } else {
                xml_state.push_tag(&block[state_start_global],i-state_start_global);
              }
              blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
              Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewStringObj("magenta",-1));
              Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(state_start));
              Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(icharline));
            } else {
              blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
              Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewStringObj("green",-1));
              Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(state_start));
              Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(icharline));
            }
            xml_state.push_state(entered_tagtext_XS);
          }
          if(xml_state.state_is(att_dquote_XS) || xml_state.state_is(att_quote_XS)){
            // nothing
          } else {
            if(!xml_state.state_is(entered_tagtext_XS)){
              xml_state.raise_error("Not valid >",raiseerror);
            }
            xml_state.pop_state();
            if(xml_state.state_is(pi_XS) && strncmp(&block[i-1],"?>",2)==0){
              xml_state.pop_state();
            } else if(xml_state.state_is(tag_XS)){
              xml_state.pop_state();
              xml_state.push_state(text_XS);
            } else {
              xml_state.raise_error("Not valid > (2)",raiseerror);
            }
          }
          if(indent_spaces && xml_state.give_xml_space_value()==default_XSV){
            block=insert_new_line_if_blanks(blockPtr,i+1,&length);
          }
          break;
        case '/':
          if(xml_state.state_is(tag_XS) || xml_state.state_is(pi_XS)){
            xml_state.push_state(tag_end_XS);
            blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
            Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewStringObj("red",-1));
            Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(icharline));
            Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(icharline+1));
          } else if(xml_state.state_is(enter_tagtext_XS)){
            xml_state.pop_state();
            if(xml_state.state_is(tag_XS)){
              xml_state.push_tag(&block[state_start_global],i-state_start_global);
              xml_state.pop_tag(&block[state_start_global],raiseerror,i-state_start_global);
            }
            blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
            Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewStringObj("magenta",-1));
            Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(state_start));
            Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(icharline));
            xml_state.push_state(entered_tagtext_XS);
          } else if(xml_state.state_is(entered_tagtext_XS)){
             xml_state.pop_tag(NULL,raiseerror,0);
          } else if(!xml_state.state_is(text_XS) && !xml_state.state_is(att_text_XS) &&
             !xml_state.state_is(att_quote_XS) && !xml_state.state_is(att_dquote_XS)){
               xml_state.raise_error("Not valid /",raiseerror);
          }
          break;
          case '=':
          if(xml_state.state_is(att_entername_XS) || xml_state.state_is(att_after_name_XS)){
            if(xml_state.state_is(att_entername_XS)){
              if(strncmp(&block[state_start_global],"xml:space",9)==0){
                last_att_is_xml_space=1;
              } else {
                last_att_is_xml_space=0;
              }
            }
            xml_state.pop_state();
            xml_state.push_state(att_after_equal_XS);
          } else if(!xml_state.state_is(text_XS) &&
            !xml_state.state_is(att_quote_XS) && !xml_state.state_is(att_dquote_XS)){
            xml_state.raise_error("Not valid =",raiseerror);
          }
          break;
          case '\'':
          if(xml_state.state_is(att_after_equal_XS)){
            xml_state.pop_state();
            xml_state.push_state(att_quote_XS);
            state_start=icharline;
            state_start_global=i;
          } else if(xml_state.state_is(att_quote_XS)){
            char cm1=block[i+1];
            if(cm1!=' ' && cm1!='\t' && cm1!='\n' && cm1!='?' && cm1!='/' && cm1!='>'){
              xml_state.raise_error("Not valid close '",raiseerror);
            }
            if(last_att_is_xml_space){
              if(strncmp(&block[state_start_global+1],"default",7)==0){
                xml_state.add_xml_space_value(default_XSV);
              } else if(strncmp(&block[state_start_global+1],"preserve",8)==0){
                xml_state.add_xml_space_value(preserve_XSV);
              }
              last_att_is_xml_space=0;
            }
            xml_state.pop_state();
            blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
            Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewStringObj("grey",-1));
            Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(state_start));
            Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(icharline+1));
            
            if(indent_spaces && icharline>=75){
              block=insert_new_line_if_not_close_tag(blockPtr,i+1,&length);
            }            
          } else if(!xml_state.state_is(text_XS) && !xml_state.state_is(att_dquote_XS)){
            xml_state.raise_error("Not valid '",raiseerror);
          }
          break;
          case '"':
          if(xml_state.state_is(att_after_equal_XS)){
            xml_state.pop_state();
            xml_state.push_state(att_dquote_XS);
            state_start=icharline;
            state_start_global=i;
          } else if(xml_state.state_is(att_dquote_XS)){
            char cm1=block[i+1];
            if(cm1!=' ' && cm1!='\t' && cm1!='\n' && cm1!='?' && cm1!='/' && cm1!='>'){
              xml_state.raise_error("Not valid close \"",raiseerror);
            }
            if(last_att_is_xml_space){
              if(strncmp(&block[state_start_global+1],"default",7)==0){
                xml_state.add_xml_space_value(default_XSV);
              } else if(strncmp(&block[state_start_global+1],"preserve",8)==0){
                xml_state.add_xml_space_value(preserve_XSV);
              }
              last_att_is_xml_space=0;
            }
            xml_state.pop_state();
            blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
            Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewStringObj("grey",-1));
            Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(state_start));
            Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(icharline+1));
            
            if(indent_spaces && icharline>=75){
              block=insert_new_line_if_not_close_tag(blockPtr,i+1,&length);
            }            
          } else if(!xml_state.state_is(text_XS) && !xml_state.state_is(att_quote_XS)){
            xml_state.raise_error("Not valid \"",raiseerror);
          }
          break;
        case ' ': case '\t': case '\n':
          if(xml_state.state_is(enter_tagtext_XS)){
            xml_state.pop_state();
            int isend;
            if(xml_state.state_is(tag_end_XS)){
              isend=1;
              xml_state.pop_state();
            } else {
              isend=0;
            }
            if(xml_state.state_is(tag_XS)){
              if(isend){
                xml_state.pop_tag(&block[state_start_global],raiseerror,i-state_start_global);
              } else {
                xml_state.push_tag(&block[state_start_global],i-state_start_global);
              }
              blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
              Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewStringObj("magenta",-1));
              Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(state_start));
              Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(icharline));
            } else {
              blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
              Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewStringObj("green",-1));
              Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(state_start));
              Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(icharline));
            }
            xml_state.push_state(entered_tagtext_XS);
          } else if(xml_state.state_is(att_entername_XS)){
            if(xml_state.state_is(att_entername_XS)){
              if(strncmp(&block[state_start_global],"xml:space",9)==0){
                last_att_is_xml_space=1;
              } else {
                last_att_is_xml_space=0;
              }
            }
            xml_state.pop_state();
            xml_state.push_state(att_after_name_XS);
          }
          break;
          default:
            if(xml_state.state_is(tag_XS) || xml_state.state_is(pi_XS) ||
              xml_state.state_is(tag_end_XS)){
                xml_state.push_state(enter_tagtext_XS);
                state_start=icharline;
                state_start_global=i;
            } else if(xml_state.state_is(entered_tagtext_XS)){
              if(c!='?'){
                xml_state.push_state(att_entername_XS);
                state_start=icharline;
                state_start_global=i;
              }
            } else if(!xml_state.state_is(text_XS) && !xml_state.state_is(att_quote_XS) &&
              !xml_state.state_is(att_dquote_XS) && !xml_state.state_is(enter_tagtext_XS) &&
              !xml_state.state_is(att_entername_XS)){
                SNPRINTF(buf,1024,"Not valid character '%c'",c);
                xml_state.raise_error(buf,raiseerror);
            }
            break;
         }
       }
      if(c=='\t'){
        icharline+=8;
      } else if(c=='\n'){
        iline++;
        icharline=0;
        if(xml_state.indentlevel<indentLevel0){
          if(iline==2){
            xml_state.indentlevel++;
          } else {
            Tcl_Obj *objPtr;
            Tcl_ListObjIndex(ip,blockinfocurrent,0,&objPtr);
            Tcl_SetIntObj(objPtr,xml_state.indentlevel);
            if(indent_spaces){
              int length_before=length;
              block=insert_remove_spaces(blockPtr,i_start_line,xml_state.indentlevel*indent_spaces,&length);
              int delta=length-length_before;
              int bi_len,bi_i,bi_val;
              Tcl_ListObjLength(ip,blockinfocurrent,&bi_len);
              for(bi_i=3;bi_len<bi_len;bi_len+=3){
                Tcl_ListObjIndex(ip,blockinfocurrent,bi_i,&objPtr);
                Tcl_GetIntFromObj(ip,objPtr,&bi_val);
                Tcl_SetIntObj(objPtr,bi_val+delta);
                Tcl_ListObjIndex(ip,blockinfocurrent,bi_i+1,&objPtr);
                Tcl_GetIntFromObj(ip,objPtr,&bi_val);
                Tcl_SetIntObj(objPtr,bi_val+delta);
              }
              i+=delta;
            }
          }
        }
        i_start_line=i+1;
        blockinfo=Tcl_CopyIfShared(blockinfo);
        Tcl_ListObjAppendElement(ip,blockinfo,blockinfocurrent);
        blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
        Tcl_SetListObj(blockinfocurrent,0,NULL);
        
        int indentlevel;
        if(xml_state.state_is(tag_XS) || xml_state.state_is(tag_end_XS) || 
          xml_state.state_is(entered_tagtext_XS)){
          indentlevel=xml_state.indentlevel+1;
          indentLevel0=0;
        } else {
          indentlevel=xml_state.indentlevel;
          indentLevel0=xml_state.indentlevel;
        }
        Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(indentlevel));
        Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewStringObj("n",-1));
        if(indent_spaces && i_start_line<length){
          block=insert_remove_spaces(blockPtr,i_start_line,indentlevel*indent_spaces,&length);
        }
      } else {
        Tcl_UniChar ccharU;
        int num=Tcl_UtfToUniChar(&block[i],&ccharU);
        i+=num-1;
        icharline++;
      }
      xml_state.enter_line_icharline(iline,icharline);
    }
    if(xml_state.indentlevel<indentLevel0){
       if(iline==2){
         xml_state.indentlevel++;
       } else {
         Tcl_Obj *objPtr;
         Tcl_ListObjIndex(ip,blockinfocurrent,0,&objPtr);
         Tcl_SetIntObj(objPtr,xml_state.indentlevel);
       }
     }
     blockinfo=Tcl_CopyIfShared(blockinfo);
     Tcl_ListObjAppendElement(ip,blockinfo,blockinfocurrent);
     blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);

     xml_state.raise_error_if_tag_stack();

     Tcl_UpVar(ip,"1",blockinfoname,"blockinfo",0);
     Tcl_SetVar2Ex(ip,"blockinfo",NULL,blockinfo,0);

#ifdef _DEBUG
     char* tmpblockinfo=Tcl_GetString(blockinfo);
#endif
     if(length>1000 && progress){
       /*     RamDebugger::ProgressVar 100 */
     }
     Tcl_DecrRefCount(blockinfo);
     Tcl_DecrRefCount(blockinfocurrent);
     if(indent_spaces){
       Tcl_SetObjResult(ip,blockPtr);
     }
     return TCL_OK;
   }   
   catch(...){
     Tcl_UpVar(ip,"1",blockinfoname,"blockinfo",0);
     Tcl_SetVar2Ex(ip,"blockinfo",NULL,blockinfo,0);

     Tcl_DecrRefCount(blockinfo);
     Tcl_DecrRefCount(blockinfocurrent);
     return TCL_ERROR;
   }
}


void add_new_line(Tcl_Interp *ip,Tcl_Obj*& blockinfo,Tcl_Obj*& blockinfocurrent,
  int indentlevel)
{
  blockinfo=Tcl_CopyIfShared(blockinfo);
  Tcl_ListObjAppendElement(ip,blockinfo,blockinfocurrent);
  blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
  Tcl_SetListObj(blockinfocurrent,0,NULL);
  
  Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(indentlevel));
  Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewStringObj("n",-1));
}

void add_new_color(Tcl_Interp *ip,Tcl_Obj*& blockinfocurrent,const char* color,
  int c_ini,int c_end)
{
  blockinfocurrent=Tcl_CopyIfShared(blockinfocurrent);
  Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewStringObj(color,-1));
  Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(c_ini));
  Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(c_end));
}

int RamDebuggerInstrumenterDoWorkForLatex_do(Tcl_Interp *ip,Tcl_Obj* blockPtr,char* blockinfoname,
  int progress,int indentlevel_ini,int indent_spaces,int raiseerror)
{

  int i,length,lengthL,lengthC;
  char c,*block;
  Tcl_Obj *blockinfo,*blockinfocurrent;
  const char* ms[5]; int mL[5];
  
  block=Tcl_GetString(blockPtr);
  length = ( int)strlen(block);
  if(length>1000 && progress){
    /*     RamDebugger::ProgressVar 0 1 */
  }
  blockinfo=Tcl_NewListObj(0,NULL);
  Tcl_IncrRefCount(blockinfo);
  blockinfocurrent=Tcl_NewListObj(0,NULL);
  Tcl_IncrRefCount(blockinfocurrent);
  Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(indentlevel_ini));
  Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewStringObj("n",-1));
  int indentLevel=indentlevel_ini;
  if(indent_spaces){
    block=insert_remove_spaces(blockPtr,0,indentlevel_ini*indent_spaces,&length);
  }

  // colors: magenta magenta2 green red blue orange
  
  try {
    int i_line=0;
    int line_num=1;
    i=0;
    while(i<length){
      lengthL=i+200;
      if(lengthL>length) lengthL=length;
      
      c=block[i];
      switch(c){
        case '\n':
        {
          add_new_line(ip,blockinfo,blockinfocurrent,indentLevel);
          line_num++;
          i_line=0;
          i++;
          continue;
        }
        break;
        case '\\':
        {
          if(string_regexp(block,i+1,lengthL,"^[a-zA-Z]+",ms,mL,1)==1){
            mL[0]++;
          } else if(block[i+1]=='\n'){
            mL[0]=1;
          } else {
            mL[0]=2;
          }
          lengthC=Tcl_NumUtfChars(&block[i],mL[0]);
          add_new_color(ip,blockinfocurrent,"magenta",i_line,i_line+lengthC);
          i+=mL[0];
          i_line+=lengthC;
          continue;
        }
        break;
        case '%':
        {
          if(string_regexp(block,i+1,lengthL,"^[^\n]*",ms,mL,1)==1){
            mL[0]++;
          } else {
            mL[0]=1;
          }
          lengthC=Tcl_NumUtfChars(&block[i],mL[0]);
          add_new_color(ip,blockinfocurrent,"red",i_line,i_line+lengthC);
          i+=mL[0];
          i_line+=lengthC;
          continue;
        }
        break;
        case open_brace_CS:
        {
          int len=string_match_brace(&block[i],length-i)+1;
          if(len>0){
            while(string_regexp(&block[i],0,len,"\n",ms,mL,1)==1){
              mL[0]=(int)(ms[0]-&block[i]);
              lengthC=Tcl_NumUtfChars(&block[i],mL[0]);
              add_new_color(ip,blockinfocurrent,"blue",i_line,i_line+lengthC);
              add_new_line(ip,blockinfo,blockinfocurrent,indentLevel);
              i+=mL[0]+1;
              len-=mL[0]+1;
              i_line=0;
              line_num++;
            }
            lengthC=Tcl_NumUtfChars(&block[i],len);
            add_new_color(ip,blockinfocurrent,"blue",i_line,i_line+lengthC);
            i+=len;
            i_line+=lengthC;
            continue;
          }
        }
        break;
        case '$':
        {
          const char* xp="^[^\\$\n]+[\\$]";
          if(string_regexp(block,i+1,lengthL,xp,ms,mL,1)==1){
            mL[0]++;
            lengthC=Tcl_NumUtfChars(&block[i],mL[0]);
            add_new_color(ip,blockinfocurrent,"cyan",i_line,i_line+lengthC);
            i+=mL[0];
            i_line+=lengthC;
            continue;
          }
        }
        break;
        case '\t':
        {
          i_line+=7; // total=8
        }
        break;
        default:
        {
          Tcl_UniChar ccharU;
          int num=Tcl_UtfToUniChar(&block[i],&ccharU);
          i+=num-1; // total=num
        }
        break;
      }
      i++;
      i_line++;
    }
    
    Tcl_UpVar(ip,"1",blockinfoname,"blockinfo",0);
    Tcl_SetVar2Ex(ip,"blockinfo",NULL,blockinfo,0);
    
#ifdef _DEBUG
      char* tmpblockinfo=Tcl_GetString(blockinfo);
#endif
    if(length>1000 && progress){
/*     RamDebugger::ProgressVar 100 */
    }
    Tcl_DecrRefCount(blockinfo);
    Tcl_DecrRefCount(blockinfocurrent);
    if(indent_spaces){
      Tcl_SetObjResult(ip,blockPtr);
    }
    return TCL_OK;
  }   
  catch(...){
    Tcl_UpVar(ip,"1",blockinfoname,"blockinfo",0);
    Tcl_SetVar2Ex(ip,"blockinfo",NULL,blockinfo,0);
    
    Tcl_DecrRefCount(blockinfo);
    Tcl_DecrRefCount(blockinfocurrent);
    return TCL_ERROR;
  }
}

int RamDebuggerInstrumenterDoWorkForWiki_do(Tcl_Interp *ip,Tcl_Obj* blockPtr,char* blockinfoname,
  int progress,int indentlevel_ini,int indent_spaces,int raiseerror)
{

  int i,length,lengthL,lengthC;
  char c,*block;
  Tcl_Obj *blockinfo,*blockinfocurrent;
  const char* ms[5]; int mL[5];
  
  block=Tcl_GetString(blockPtr);
  length = ( int)strlen(block);
  if(length>1000 && progress){
    /*     RamDebugger::ProgressVar 0 1 */
  }
  blockinfo=Tcl_NewListObj(0,NULL);
  Tcl_IncrRefCount(blockinfo);
  blockinfocurrent=Tcl_NewListObj(0,NULL);
  Tcl_IncrRefCount(blockinfocurrent);
  Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewIntObj(indentlevel_ini));
  Tcl_ListObjAppendElement(ip,blockinfocurrent,Tcl_NewStringObj("n",-1));
  int indentLevel=indentlevel_ini;
  if(indent_spaces){
    block=insert_remove_spaces(blockPtr,0,indentlevel_ini*indent_spaces,&length);
  }

  // colors: magenta magenta2 green red blue orange
  
  try {
    int i_line=0;
    int i_no_space=-1;
    int line_num=1;
    i=0;
    while(i<length){
      lengthL=i+200;
      if(lengthL>length) lengthL=length;
      
      c=block[i];
      switch(c){
        case '\n':
        {
          add_new_line(ip,blockinfo,blockinfocurrent,indentLevel);
          line_num++;
          i_line=0;
          i_no_space=-1;
          i++;
          continue;
        }
        break;
        case '=': case '#':
        {
          const char* rex="^[=#]*[^#=\n]+[=#]*";
          if(i_no_space==-1 && string_regexp(block,i+1,lengthL,rex,ms,mL,1)==1){
            mL[0]++;
            lengthC=Tcl_NumUtfChars(&block[i],mL[0]);
            add_new_color(ip,blockinfocurrent,"blue",i_line,i_line+lengthC);
            i+=mL[0];
            i_line+=lengthC;
            i_no_space=i;
            continue;
          }
          i_no_space=i;
        }
        break;
        case '\'':
        {
          if(string_regexp(block,i,lengthL,"^'''?[^'\n]+'''?",ms,mL,1)==1){
            lengthC=Tcl_NumUtfChars(&block[i],mL[0]);
            add_new_color(ip,blockinfocurrent,"blue",i_line,i_line+lengthC);
            i+=mL[0];
            i_line+=lengthC;
            i_no_space=i;
            continue;
          }
          i_no_space=i;
        }
        break;
        case '*':
        {
          const char* rex="^([*]+)\\s+";
          if(i_no_space==-1 && string_regexp(block,i,lengthL,rex,ms,mL,2)==1){
            lengthC=Tcl_NumUtfChars(ms[1],mL[1]);
            add_new_color(ip,blockinfocurrent,"blue",i_line,i_line+lengthC);
            i+=mL[0];
            i_line+=lengthC;
            i_no_space=i;
            continue;
          }
          if(i>0 && string_regexp(block,i-1,lengthL,"^\\s\\*\\*?[^*\n]+\\*\\*?",ms,mL,1)==1){
            lengthC=Tcl_NumUtfChars(ms[0],mL[0]);
            add_new_color(ip,blockinfocurrent,"blue",i_line,i_line+lengthC);
            i+=mL[0]-1;
            i_line+=lengthC;
            i_no_space=i;
            continue;
          }
          i_no_space=i;
        }
        break;
        case '<':
        {
          if(string_regexp(block,i,lengthL,"^<[^\n>]+>",ms,mL,1)==1){
            lengthC=Tcl_NumUtfChars(&block[i],mL[0]);
            add_new_color(ip,blockinfocurrent,"green",i_line,i_line+lengthC);
            i+=mL[0];
            i_line+=lengthC;
            i_no_space=i;
            continue;
          }
          i_no_space=i;
        }
        break;
        case '\\':
        {
          if(string_regexp(block,i+1,lengthL,"^[a-zA-Z]+",ms,mL,1)==1){
            mL[0]++;
          } else if(block[i+1]=='\n'){
            mL[0]=1;
          } else {
            mL[0]=2;
          }
          lengthC=Tcl_NumUtfChars(&block[i],mL[0]);
          add_new_color(ip,blockinfocurrent,"magenta",i_line,i_line+lengthC);
          i+=mL[0];
          i_line+=lengthC;
          i_no_space=i;
          continue;
        }
        break;
        case open_brace_CS:
        {
          if(string_regexp(block,i+1,lengthL,"^\\|",ms,mL,1)==1){
            mL[0]++;
            lengthC=Tcl_NumUtfChars(&block[i],mL[0]);
            add_new_color(ip,blockinfocurrent,"magenta2",i_line,i_line+lengthC);
            i+=mL[0];
            i_line+=lengthC;
            i_no_space=i;
            continue;
          }
          i_no_space=i;
        }
        break;
        case '|':
        {
          const char* xp="^\\|[-\\" close_brace_CSS "]*";
          if(string_regexp(block,i,lengthL,xp,ms,mL,1)==1){
            lengthC=Tcl_NumUtfChars(&block[i],mL[0]);
            add_new_color(ip,blockinfocurrent,"magenta2",i_line,i_line+lengthC);
            i+=mL[0];
            i_line+=lengthC;
            i_no_space=i;
            continue;
          }
          i_no_space=i;
        }
        break;
        case open_braquet_CS:
        {
          const char* xp="^\\[\\[[^\n\\" close_braquet_CSS "]+\\]\\]";
          if(string_regexp(block,i,lengthL,xp,ms,mL,1)==1){
            lengthC=Tcl_NumUtfChars(&block[i],mL[0]);
            add_new_color(ip,blockinfocurrent,"green",i_line,i_line+lengthC);
            i+=mL[0];
            i_line+=lengthC;
            i_no_space=i;
            continue;
          }
          xp="^\\[[^\n\\" close_braquet_CSS "]+\\]\\([^()]*\\)";
          if(string_regexp(block,i,lengthL,xp,ms,mL,1)==1){
            if(i>0 && block[i-1]=='!'){
              ms[0]--;
              mL[0]++;
              i_line--;
            }
            lengthC=Tcl_NumUtfChars(ms[0],mL[0]);
            add_new_color(ip,blockinfocurrent,"green",i_line,i_line+lengthC);
            i+=mL[0];
            i_line+=lengthC;
            i_no_space=i;
            continue;
          }
          i_no_space=i;
        }
        break;
        case ' ':
        {
          // nothing
        }
        break;
        case '\t':
        {
          i_line+=7; // total=8
        }
        break;
        default:
        {
          Tcl_UniChar ccharU;
          int num=Tcl_UtfToUniChar(&block[i],&ccharU);
          i+=num-1; // total=num
          i_no_space=i;
        }
        break;
      }
      i++;
      i_line++;
    }
    
    Tcl_UpVar(ip,"1",blockinfoname,"blockinfo",0);
    Tcl_SetVar2Ex(ip,"blockinfo",NULL,blockinfo,0);
    
#ifdef _DEBUG
      char* tmpblockinfo=Tcl_GetString(blockinfo);
#endif
    if(length>1000 && progress){
/*     RamDebugger::ProgressVar 100 */
    }
    Tcl_DecrRefCount(blockinfo);
    Tcl_DecrRefCount(blockinfocurrent);
    if(indent_spaces){
      Tcl_SetObjResult(ip,blockPtr);
    }
    return TCL_OK;
  }   
  catch(...){
    Tcl_UpVar(ip,"1",blockinfoname,"blockinfo",0);
    Tcl_SetVar2Ex(ip,"blockinfo",NULL,blockinfo,0);
    
    Tcl_DecrRefCount(blockinfo);
    Tcl_DecrRefCount(blockinfocurrent);
    return TCL_ERROR;
  }
}

int RamDebuggerInstrumenterDoWork(ClientData clientData, Tcl_Interp *ip, int objc,
                                  Tcl_Obj *CONST objv[])
{
  int result,filenum,progress=1;
  if (objc<6) {
    Tcl_WrongNumArgs(ip, 1, objv,
      "block filenum newblocknameP newblocknameR blockinfoname ?progress?");
    return TCL_ERROR;
  }
  result=Tcl_GetIntFromObj(ip,objv[2],&filenum);
  if(result) return TCL_ERROR;
  if (objc==7){
    result=Tcl_GetIntFromObj(ip,objv[6],&progress);
    if(result) return TCL_ERROR;
  }
  result=RamDebuggerInstrumenterDoWork_do(ip,Tcl_GetString(objv[1]),filenum,Tcl_GetString(objv[3]),
                                        Tcl_GetString(objv[4]),Tcl_GetString(objv[5]),progress);
  return result;
}

int RamDebuggerInstrumenterDoWorkForCpp(ClientData clientData, Tcl_Interp *ip, int objc,
                                  Tcl_Obj *CONST objv[])
{
  int result,progress=1,indentlevel_ini=0,raiseerror=1;
  if (objc<3) {
    Tcl_WrongNumArgs(ip, 1, objv,
                     "block blockinfoname ?progress? ?indent_level_ini?");
    return TCL_ERROR;
  }
  if (objc>=4){
    result=Tcl_GetIntFromObj(ip,objv[3],&progress);
    if(result) return TCL_ERROR;
  }
  if (objc>=5){
    result=Tcl_GetIntFromObj(ip,objv[4],&indentlevel_ini);
    if(result) return TCL_ERROR;
  }
  if (objc==6){
    result=Tcl_GetBooleanFromObj(ip,objv[5],&raiseerror);
    if(result) return TCL_ERROR;
  }
  result=RamDebuggerInstrumenterDoWorkForCpp_do(ip,Tcl_GetString(objv[1]),Tcl_GetString(objv[2]),
    progress,indentlevel_ini);
  return result;
}

int RamDebuggerInstrumenterDoWorkForXML(ClientData clientData, Tcl_Interp *ip, int objc,
                                  Tcl_Obj *CONST objv[])
{
  int result,progress=1,indentlevel_ini=0,raiseerror=1,indent_spaces;
  Tcl_Obj* blockPtr;
  if (objc<3) {
    Tcl_WrongNumArgs(ip, 1, objv,
      "block blockinfoname ?progress? ?indentlevel_ini? ?raiseerror? ?indent_spaces?");
    return TCL_ERROR;
  }
  if (objc>=4){
    result=Tcl_GetIntFromObj(ip,objv[3],&progress);
    if(result) return TCL_ERROR;
  }
  if (objc>=5){
    result=Tcl_GetIntFromObj(ip,objv[4],&indentlevel_ini);
    if(result) return TCL_ERROR;
  }
  if (objc>=6){
    result=Tcl_GetBooleanFromObj(ip,objv[5],&raiseerror);
    if(result) return TCL_ERROR;
  }
  
  indent_spaces=0;
  if (objc==7){
    result=Tcl_GetIntFromObj(ip,objv[6],&indent_spaces);
    if(result) return TCL_ERROR;
  }

  if(indent_spaces){
    blockPtr=Tcl_DuplicateObj(objv[1]);
    Tcl_IncrRefCount(blockPtr);
  } else {
    blockPtr=objv[1];
  }
  result=RamDebuggerInstrumenterDoWorkForXML_do(ip,blockPtr,Tcl_GetString(objv[2]),
    progress,indentlevel_ini,indent_spaces,raiseerror);
  if(indent_spaces){
    Tcl_DecrRefCount(blockPtr);
  }
  return result;
}

int RamDebuggerInstrumenterDoWorkForLatex(ClientData clientData, Tcl_Interp *ip, int objc,
                                  Tcl_Obj *CONST objv[])
{
  int result,progress=1,indentlevel_ini=0,raiseerror=1,indent_spaces;
  Tcl_Obj* blockPtr;
  if (objc<3) {
    Tcl_WrongNumArgs(ip, 1, objv,
      "block blockinfoname ?progress? ?indentlevel_ini? ?raiseerror? ?indent_spaces?");
    return TCL_ERROR;
  }
  if (objc>=4){
    result=Tcl_GetIntFromObj(ip,objv[3],&progress);
    if(result) return TCL_ERROR;
  }
  if (objc>=5){
    result=Tcl_GetIntFromObj(ip,objv[4],&indentlevel_ini);
    if(result) return TCL_ERROR;
  }
  if (objc>=6){
    result=Tcl_GetBooleanFromObj(ip,objv[5],&raiseerror);
    if(result) return TCL_ERROR;
  }
  
  indent_spaces=0;
  if (objc==7){
    result=Tcl_GetIntFromObj(ip,objv[6],&indent_spaces);
    if(result) return TCL_ERROR;
  }

  if(indent_spaces){
    blockPtr=Tcl_DuplicateObj(objv[1]);
    Tcl_IncrRefCount(blockPtr);
  } else {
    blockPtr=objv[1];
  }
  result=RamDebuggerInstrumenterDoWorkForLatex_do(ip,blockPtr,Tcl_GetString(objv[2]),
    progress,indentlevel_ini,indent_spaces,raiseerror);
  if(indent_spaces){
    Tcl_DecrRefCount(blockPtr);
  }
  return result;
}

int RamDebuggerInstrumenterDoWorkForWiki(ClientData clientData, Tcl_Interp *ip, int objc,
                                  Tcl_Obj *CONST objv[])
{
  int result,progress=1,indentlevel_ini=0,raiseerror=1,indent_spaces;
  Tcl_Obj* blockPtr;
  if (objc<3) {
    Tcl_WrongNumArgs(ip, 1, objv,
      "block blockinfoname ?progress? ?indentlevel_ini? ?raiseerror? ?indent_spaces?");
    return TCL_ERROR;
  }
  if (objc>=4){
    result=Tcl_GetIntFromObj(ip,objv[3],&progress);
    if(result) return TCL_ERROR;
  }
  if (objc>=5){
    result=Tcl_GetIntFromObj(ip,objv[4],&indentlevel_ini);
    if(result) return TCL_ERROR;
  }
  if (objc>=6){
    result=Tcl_GetBooleanFromObj(ip,objv[5],&raiseerror);
    if(result) return TCL_ERROR;
  }
  
  indent_spaces=0;
  if (objc==7){
    result=Tcl_GetIntFromObj(ip,objv[6],&indent_spaces);
    if(result) return TCL_ERROR;
  }

  if(indent_spaces){
    blockPtr=Tcl_DuplicateObj(objv[1]);
    Tcl_IncrRefCount(blockPtr);
  } else {
    blockPtr=objv[1];
  }
  result=RamDebuggerInstrumenterDoWorkForWiki_do(ip,blockPtr,Tcl_GetString(objv[2]),
    progress,indentlevel_ini,indent_spaces,raiseerror);
  if(indent_spaces){
    Tcl_DecrRefCount(blockPtr);
  }
  return result;
}

static int give_line_chars(char* block,int ipos)
{
  int i;
  for(i=ipos-1;i>=0;i--){
    if(block[i]=='\n') break;
  }
  i++;
  return Tcl_NumUtfChars(&block[i],ipos-i);
}

static int is_backslashed(char *block,int i)
{
  int backslashes=0;
  for(int j=i-1;j>=0;j--){
    if(block[j]=='\\') backslashes++;
    else break;
  }
  if(backslashes%2==1) return 1;
  else return 0;
}

static int is_c_char(char *block,int i)
{
  if(i>0 && block[i-1]=='\'' && block[i+1]=='\'') return 1;
  return 0;
}

int RamDebuggerInstrumenterSearchBraces_do(Tcl_Interp *ip,Tcl_Obj* blockPtr,
  int& linenum,int& linecharpos)
{
  int linenumL,i_stack,delta_i,delta_iL;
  int i,j,i_start_line,length;
  
  const int stack_len=2048;
  const char* p;
  char *block,stack[stack_len],c_opposite;
  
  block=Tcl_GetString(blockPtr);
  length=(int)strlen(block);
  
  linenumL=1;
  if(linenum==1){
    i=0;
  } else {
    for(i=0;i<length;i++){
      if(block[i]=='\n'){
        linenumL++;
        if(linenumL==linenum){
          i++;
          break;
        }
      }
    }
    if(i==length){
      linenum=linenumL;
      linecharpos=0;
      return TCL_ERROR;
    }
  }
  for(i_start_line=i;i<length;i++){
    if(block[i]=='\n') break;
    if(Tcl_NumUtfChars(&block[i_start_line],(int)(i-i_start_line))==linecharpos) break;
  }
  if(i==length || block[i]=='\n'){
    linenum=linenumL;
    linecharpos=0;
    return TCL_ERROR;
  }
  
  const char *keys="{[()]}";
  
  i_stack=0;
  p=strchr(keys,block[i]);
  if(!p) return TCL_ERROR;
  if(p-keys<3) delta_i=1;
  else delta_i=-1;
  
  stack[i_stack++]=block[i];
  
  for(i+=delta_i;i>=0 && i<length;i+=delta_i){
    if(block[i]=='\n'){
      if(delta_i==1) linenum++;
      else linenum--;
    } else if((p=strchr(keys,block[i]))){
      if(is_backslashed(block,i) || is_c_char(block,i)) continue;

      if(p-keys<3) delta_iL=1;
      else delta_iL=-1;
      c_opposite=keys[5-(p-keys)];
      
      if(delta_iL==delta_i){
        if(i_stack==stack_len){
          linecharpos=give_line_chars(block,i);
          return TCL_ERROR;
        }
        stack[i_stack++]=block[i];
      } else {
        if(stack[i_stack-1]!=c_opposite){
          linecharpos=give_line_chars(block,i);
          return TCL_ERROR;
        }
        i_stack--;
        if(i_stack==0){
          linecharpos=give_line_chars(block,i);
          return TCL_OK;
        }
      }
    } else if(block[i]=='"'){
      // assuming "" blocks are contained in one line
      if(is_backslashed(block,i) || is_c_char(block,i)) continue;
      int is_start,num_to_start=0;
      for(j=i-1;j>=0;j--){
        if(block[j]=='"' && !is_backslashed(block,j) && !is_c_char(block,j)){
          num_to_start++;
        } else if(block[j]=='\n') break;
      }
      if(num_to_start%2==0) is_start=1;
      else is_start=0;
      if((is_start && delta_i>0) || (!is_start && delta_i<0)){
        for(i+=delta_i;i>=0 && i<length;i+=delta_i){
          if(block[i]=='"' && !is_backslashed(block,i) && !is_c_char(block,i)){
            break;
          } else if(block[i]=='\n'){
            if(delta_i==1) linenum++;
            else linenum--;
            break;
          }
        }
      }
    }
  }
  if(i<0) i=0;
  if(i>=length) i=length-1;
  
  linecharpos=give_line_chars(block,i);
  return TCL_ERROR;
}

int RamDebuggerInstrumenterSearchBraces(ClientData clientData, Tcl_Interp *ip, int objc,
  Tcl_Obj *CONST objv[])
{
  int result,linenum,linepos;
  Tcl_Obj* blockPtr;
  if (objc!=4) {
    Tcl_WrongNumArgs(ip, 1, objv,"block linenum linepos");
    return TCL_ERROR;
  }
  blockPtr=objv[1];

  result=Tcl_GetIntFromObj(ip,objv[2],&linenum);
  if(result) return TCL_ERROR;
  
  result=Tcl_GetIntFromObj(ip,objv[3],&linepos);
  if(result) return TCL_ERROR;

  result=RamDebuggerInstrumenterSearchBraces_do(ip,blockPtr,linenum,linepos);
  
  Tcl_Obj *listPtr=Tcl_NewListObj(0,NULL);
  Tcl_ListObjAppendElement(ip,listPtr,Tcl_NewIntObj(linenum));
  Tcl_ListObjAppendElement(ip,listPtr,Tcl_NewIntObj(linepos));
  Tcl_SetObjResult(ip,listPtr);
  return result;
}

#ifdef RAMDEBUGGER_MARKDOWN 
extern "C" DLLEXPORT int Markdown_Init(Tcl_Interp *interp);
#endif //RAMDEBUGGER_MARKDOWN

extern "C" DLLEXPORT int Ramdebuggerinstrumenter_Init(Tcl_Interp *interp)
{
#ifdef USE_TCL_STUBS
  Tcl_InitStubs(interp,"8.5",0);
  //Tk_InitStubs(interp,"8.5",0);
#endif

#ifdef RAMDEBUGGER_MARKDOWN 
  Markdown_Init(interp);
#endif //RAMDEBUGGER_MARKDOWN

  Tcl_CreateObjCommand( interp, "RamDebuggerInstrumenterDoWork",RamDebuggerInstrumenterDoWork,NULL,NULL);
  Tcl_CreateObjCommand( interp, "RamDebuggerInstrumenterDoWorkForCpp",RamDebuggerInstrumenterDoWorkForCpp,NULL,NULL);
  Tcl_CreateObjCommand( interp, "RamDebuggerInstrumenterDoWorkForXML",RamDebuggerInstrumenterDoWorkForXML,NULL,NULL);
  Tcl_CreateObjCommand( interp, "RamDebuggerInstrumenterDoWorkForLatex",RamDebuggerInstrumenterDoWorkForLatex,NULL,NULL);
  Tcl_CreateObjCommand( interp, "RamDebuggerInstrumenterDoWorkForWiki",RamDebuggerInstrumenterDoWorkForWiki,NULL,NULL);
  Tcl_CreateObjCommand( interp, "RamDebuggerInstrumenterSearchBraces",RamDebuggerInstrumenterSearchBraces,NULL,NULL);
  return TCL_OK;
}

extern "C" DLLEXPORT int Ramdebuggerinstrumenter_SafeInit(Tcl_Interp *interp)
{
  return Ramdebuggerinstrumenter_Init(interp);
}

extern "C" DLLEXPORT int Ramdebuggerinstrumenter_Unload(Tcl_Interp *interp,int flags)
{
  return TCL_ERROR;
}

extern "C" DLLEXPORT int Ramdebuggerinstrumenter_SafeUnload(Tcl_Interp *interp,int flags)
{
  return TCL_ERROR;
}






